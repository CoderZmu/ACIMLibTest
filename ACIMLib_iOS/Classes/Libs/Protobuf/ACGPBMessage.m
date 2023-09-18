// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// https://developers.google.com/protocol-buffers/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "ACGPBMessage_PackagePrivate.h"

#import <objc/runtime.h>
#import <objc/message.h>
#import <stdatomic.h>

#import "ACGPBArray_PackagePrivate.h"
#import "ACGPBCodedInputStream_PackagePrivate.h"
#import "ACGPBCodedOutputStream_PackagePrivate.h"
#import "ACGPBDescriptor_PackagePrivate.h"
#import "ACGPBDictionary_PackagePrivate.h"
#import "ACGPBExtensionInternals.h"
#import "ACGPBExtensionRegistry.h"
#import "ACGPBRootObject_PackagePrivate.h"
#import "ACGPBUnknownFieldSet_PackagePrivate.h"
#import "ACGPBUtilities_PackagePrivate.h"

// Direct access is use for speed, to avoid even internally declaring things
// read/write, etc. The warning is enabled in the project to ensure code calling
// protos can turn on -Wdirect-ivar-access without issues.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

NSString *const ACGPBMessageErrorDomain =
    ACGPBNSStringifySymbol(ACGPBMessageErrorDomain);

NSString *const ACGPBErrorReasonKey = @"Reason";

static NSString *const kACGPBDataCoderKey = @"ACGPBData";

//
// PLEASE REMEMBER:
//
// This is the base class for *all* messages generated, so any selector defined,
// *public* or *private* could end up colliding with a proto message field. So
// avoid using selectors that could match a property, use C functions to hide
// them, etc.
//

@interface ACGPBMessage () {
 @package
  ACGPBUnknownFieldSet *unknownFields_;
  NSMutableDictionary *extensionMap_;
  // Readonly access to autocreatedExtensionMap_ is protected via
  // readOnlySemaphore_.
  NSMutableDictionary *autocreatedExtensionMap_;

  // If the object was autocreated, we remember the creator so that if we get
  // mutated, we can inform the creator to make our field visible.
  ACGPBMessage *autocreator_;
  ACGPBFieldDescriptor *autocreatorField_;
  ACGPBExtensionDescriptor *autocreatorExtension_;

  // Message can only be mutated from one thread. But some *readonly* operations
  // modify internal state because they autocreate things. The
  // autocreatedExtensionMap_ is one such structure. Access during readonly
  // operations is protected via this semaphore.
  // NOTE: OSSpinLock may seem like a good fit here but Apple engineers have
  // pointed out that they are vulnerable to live locking on iOS in cases of
  // priority inversion:
  //   http://mjtsai.com/blog/2015/12/16/osspinlock-is-unsafe/
  //   https://lists.swift.org/pipermail/swift-dev/Week-of-Mon-20151214/000372.html
  // Use of readOnlySemaphore_ must be prefaced by a call to
  // ACGPBPrepareReadOnlySemaphore to ensure it has been created. This allows
  // readOnlySemaphore_ to be only created when actually needed.
  _Atomic(dispatch_semaphore_t) readOnlySemaphore_;
}
@end

static id CreateArrayForField(ACGPBFieldDescriptor *field,
                              ACGPBMessage *autocreator)
    __attribute__((ns_returns_retained));
static id GetOrCreateArrayIvarWithField(ACGPBMessage *self,
                                        ACGPBFieldDescriptor *field);
static id GetArrayIvarWithField(ACGPBMessage *self, ACGPBFieldDescriptor *field);
static id CreateMapForField(ACGPBFieldDescriptor *field,
                            ACGPBMessage *autocreator)
    __attribute__((ns_returns_retained));
static id GetOrCreateMapIvarWithField(ACGPBMessage *self,
                                      ACGPBFieldDescriptor *field);
static id GetMapIvarWithField(ACGPBMessage *self, ACGPBFieldDescriptor *field);
static NSMutableDictionary *CloneExtensionMap(NSDictionary *extensionMap,
                                              NSZone *zone)
    __attribute__((ns_returns_retained));

#ifdef DEBUG
static NSError *MessageError(NSInteger code, NSDictionary *userInfo) {
  return [NSError errorWithDomain:ACGPBMessageErrorDomain
                             code:code
                         userInfo:userInfo];
}
#endif

static NSError *ErrorFromException(NSException *exception) {
  NSError *error = nil;

  if ([exception.name isEqual:ACGPBCodedInputStreamException]) {
    NSDictionary *exceptionInfo = exception.userInfo;
    error = exceptionInfo[ACGPBCodedInputStreamUnderlyingErrorKey];
  }

  if (!error) {
    NSString *reason = exception.reason;
    NSDictionary *userInfo = nil;
    if ([reason length]) {
      userInfo = @{ ACGPBErrorReasonKey : reason };
    }

    error = [NSError errorWithDomain:ACGPBMessageErrorDomain
                                code:ACGPBMessageErrorCodeOther
                            userInfo:userInfo];
  }
  return error;
}

static void CheckExtension(ACGPBMessage *self,
                           ACGPBExtensionDescriptor *extension) {
  if (![self isKindOfClass:extension.containingMessageClass]) {
    [NSException
         raise:NSInvalidArgumentException
        format:@"Extension %@ used on wrong class (%@ instead of %@)",
               extension.singletonName,
               [self class], extension.containingMessageClass];
  }
}

static NSMutableDictionary *CloneExtensionMap(NSDictionary *extensionMap,
                                              NSZone *zone) {
  if (extensionMap.count == 0) {
    return nil;
  }
  NSMutableDictionary *result = [[NSMutableDictionary allocWithZone:zone]
      initWithCapacity:extensionMap.count];

  for (ACGPBExtensionDescriptor *extension in extensionMap) {
    id value = [extensionMap objectForKey:extension];
    BOOL isMessageExtension = ACGPBExtensionIsMessage(extension);

    if (extension.repeated) {
      if (isMessageExtension) {
        NSMutableArray *list =
            [[NSMutableArray alloc] initWithCapacity:[value count]];
        for (ACGPBMessage *listValue in value) {
          ACGPBMessage *copiedValue = [listValue copyWithZone:zone];
          [list addObject:copiedValue];
          [copiedValue release];
        }
        [result setObject:list forKey:extension];
        [list release];
      } else {
        NSMutableArray *copiedValue = [value mutableCopyWithZone:zone];
        [result setObject:copiedValue forKey:extension];
        [copiedValue release];
      }
    } else {
      if (isMessageExtension) {
        ACGPBMessage *copiedValue = [value copyWithZone:zone];
        [result setObject:copiedValue forKey:extension];
        [copiedValue release];
      } else {
        [result setObject:value forKey:extension];
      }
    }
  }

  return result;
}

static id CreateArrayForField(ACGPBFieldDescriptor *field,
                              ACGPBMessage *autocreator) {
  id result;
  ACGPBDataType fieldDataType = ACGPBGetFieldDataType(field);
  switch (fieldDataType) {
    case ACGPBDataTypeBool:
      result = [[ACGPBBoolArray alloc] init];
      break;
    case ACGPBDataTypeFixed32:
    case ACGPBDataTypeUInt32:
      result = [[ACGPBUInt32Array alloc] init];
      break;
    case ACGPBDataTypeInt32:
    case ACGPBDataTypeSFixed32:
    case ACGPBDataTypeSInt32:
      result = [[ACGPBInt32Array alloc] init];
      break;
    case ACGPBDataTypeFixed64:
    case ACGPBDataTypeUInt64:
      result = [[ACGPBUInt64Array alloc] init];
      break;
    case ACGPBDataTypeInt64:
    case ACGPBDataTypeSFixed64:
    case ACGPBDataTypeSInt64:
      result = [[ACGPBInt64Array alloc] init];
      break;
    case ACGPBDataTypeFloat:
      result = [[ACGPBFloatArray alloc] init];
      break;
    case ACGPBDataTypeDouble:
      result = [[ACGPBDoubleArray alloc] init];
      break;

    case ACGPBDataTypeEnum:
      result = [[ACGPBEnumArray alloc]
                  initWithValidationFunction:field.enumDescriptor.enumVerifier];
      break;

    case ACGPBDataTypeBytes:
    case ACGPBDataTypeGroup:
    case ACGPBDataTypeMessage:
    case ACGPBDataTypeString:
      if (autocreator) {
        result = [[ACGPBAutocreatedArray alloc] init];
      } else {
        result = [[NSMutableArray alloc] init];
      }
      break;
  }

  if (autocreator) {
    if (ACGPBDataTypeIsObject(fieldDataType)) {
      ACGPBAutocreatedArray *autoArray = result;
      autoArray->_autocreator =  autocreator;
    } else {
      ACGPBInt32Array *gpbArray = result;
      gpbArray->_autocreator = autocreator;
    }
  }

  return result;
}

static id CreateMapForField(ACGPBFieldDescriptor *field,
                            ACGPBMessage *autocreator) {
  id result;
  ACGPBDataType keyDataType = field.mapKeyDataType;
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  switch (keyDataType) {
    case ACGPBDataTypeBool:
      switch (valueDataType) {
        case ACGPBDataTypeBool:
          result = [[ACGPBBoolBoolDictionary alloc] init];
          break;
        case ACGPBDataTypeFixed32:
        case ACGPBDataTypeUInt32:
          result = [[ACGPBBoolUInt32Dictionary alloc] init];
          break;
        case ACGPBDataTypeInt32:
        case ACGPBDataTypeSFixed32:
        case ACGPBDataTypeSInt32:
          result = [[ACGPBBoolInt32Dictionary alloc] init];
          break;
        case ACGPBDataTypeFixed64:
        case ACGPBDataTypeUInt64:
          result = [[ACGPBBoolUInt64Dictionary alloc] init];
          break;
        case ACGPBDataTypeInt64:
        case ACGPBDataTypeSFixed64:
        case ACGPBDataTypeSInt64:
          result = [[ACGPBBoolInt64Dictionary alloc] init];
          break;
        case ACGPBDataTypeFloat:
          result = [[ACGPBBoolFloatDictionary alloc] init];
          break;
        case ACGPBDataTypeDouble:
          result = [[ACGPBBoolDoubleDictionary alloc] init];
          break;
        case ACGPBDataTypeEnum:
          result = [[ACGPBBoolEnumDictionary alloc]
              initWithValidationFunction:field.enumDescriptor.enumVerifier];
          break;
        case ACGPBDataTypeBytes:
        case ACGPBDataTypeMessage:
        case ACGPBDataTypeString:
          result = [[ACGPBBoolObjectDictionary alloc] init];
          break;
        case ACGPBDataTypeGroup:
          NSCAssert(NO, @"shouldn't happen");
          return nil;
      }
      break;
    case ACGPBDataTypeFixed32:
    case ACGPBDataTypeUInt32:
      switch (valueDataType) {
        case ACGPBDataTypeBool:
          result = [[ACGPBUInt32BoolDictionary alloc] init];
          break;
        case ACGPBDataTypeFixed32:
        case ACGPBDataTypeUInt32:
          result = [[ACGPBUInt32UInt32Dictionary alloc] init];
          break;
        case ACGPBDataTypeInt32:
        case ACGPBDataTypeSFixed32:
        case ACGPBDataTypeSInt32:
          result = [[ACGPBUInt32Int32Dictionary alloc] init];
          break;
        case ACGPBDataTypeFixed64:
        case ACGPBDataTypeUInt64:
          result = [[ACGPBUInt32UInt64Dictionary alloc] init];
          break;
        case ACGPBDataTypeInt64:
        case ACGPBDataTypeSFixed64:
        case ACGPBDataTypeSInt64:
          result = [[ACGPBUInt32Int64Dictionary alloc] init];
          break;
        case ACGPBDataTypeFloat:
          result = [[ACGPBUInt32FloatDictionary alloc] init];
          break;
        case ACGPBDataTypeDouble:
          result = [[ACGPBUInt32DoubleDictionary alloc] init];
          break;
        case ACGPBDataTypeEnum:
          result = [[ACGPBUInt32EnumDictionary alloc]
              initWithValidationFunction:field.enumDescriptor.enumVerifier];
          break;
        case ACGPBDataTypeBytes:
        case ACGPBDataTypeMessage:
        case ACGPBDataTypeString:
          result = [[ACGPBUInt32ObjectDictionary alloc] init];
          break;
        case ACGPBDataTypeGroup:
          NSCAssert(NO, @"shouldn't happen");
          return nil;
      }
      break;
    case ACGPBDataTypeInt32:
    case ACGPBDataTypeSFixed32:
    case ACGPBDataTypeSInt32:
      switch (valueDataType) {
        case ACGPBDataTypeBool:
          result = [[ACGPBInt32BoolDictionary alloc] init];
          break;
        case ACGPBDataTypeFixed32:
        case ACGPBDataTypeUInt32:
          result = [[ACGPBInt32UInt32Dictionary alloc] init];
          break;
        case ACGPBDataTypeInt32:
        case ACGPBDataTypeSFixed32:
        case ACGPBDataTypeSInt32:
          result = [[ACGPBInt32Int32Dictionary alloc] init];
          break;
        case ACGPBDataTypeFixed64:
        case ACGPBDataTypeUInt64:
          result = [[ACGPBInt32UInt64Dictionary alloc] init];
          break;
        case ACGPBDataTypeInt64:
        case ACGPBDataTypeSFixed64:
        case ACGPBDataTypeSInt64:
          result = [[ACGPBInt32Int64Dictionary alloc] init];
          break;
        case ACGPBDataTypeFloat:
          result = [[ACGPBInt32FloatDictionary alloc] init];
          break;
        case ACGPBDataTypeDouble:
          result = [[ACGPBInt32DoubleDictionary alloc] init];
          break;
        case ACGPBDataTypeEnum:
          result = [[ACGPBInt32EnumDictionary alloc]
              initWithValidationFunction:field.enumDescriptor.enumVerifier];
          break;
        case ACGPBDataTypeBytes:
        case ACGPBDataTypeMessage:
        case ACGPBDataTypeString:
          result = [[ACGPBInt32ObjectDictionary alloc] init];
          break;
        case ACGPBDataTypeGroup:
          NSCAssert(NO, @"shouldn't happen");
          return nil;
      }
      break;
    case ACGPBDataTypeFixed64:
    case ACGPBDataTypeUInt64:
      switch (valueDataType) {
        case ACGPBDataTypeBool:
          result = [[ACGPBUInt64BoolDictionary alloc] init];
          break;
        case ACGPBDataTypeFixed32:
        case ACGPBDataTypeUInt32:
          result = [[ACGPBUInt64UInt32Dictionary alloc] init];
          break;
        case ACGPBDataTypeInt32:
        case ACGPBDataTypeSFixed32:
        case ACGPBDataTypeSInt32:
          result = [[ACGPBUInt64Int32Dictionary alloc] init];
          break;
        case ACGPBDataTypeFixed64:
        case ACGPBDataTypeUInt64:
          result = [[ACGPBUInt64UInt64Dictionary alloc] init];
          break;
        case ACGPBDataTypeInt64:
        case ACGPBDataTypeSFixed64:
        case ACGPBDataTypeSInt64:
          result = [[ACGPBUInt64Int64Dictionary alloc] init];
          break;
        case ACGPBDataTypeFloat:
          result = [[ACGPBUInt64FloatDictionary alloc] init];
          break;
        case ACGPBDataTypeDouble:
          result = [[ACGPBUInt64DoubleDictionary alloc] init];
          break;
        case ACGPBDataTypeEnum:
          result = [[ACGPBUInt64EnumDictionary alloc]
              initWithValidationFunction:field.enumDescriptor.enumVerifier];
          break;
        case ACGPBDataTypeBytes:
        case ACGPBDataTypeMessage:
        case ACGPBDataTypeString:
          result = [[ACGPBUInt64ObjectDictionary alloc] init];
          break;
        case ACGPBDataTypeGroup:
          NSCAssert(NO, @"shouldn't happen");
          return nil;
      }
      break;
    case ACGPBDataTypeInt64:
    case ACGPBDataTypeSFixed64:
    case ACGPBDataTypeSInt64:
      switch (valueDataType) {
        case ACGPBDataTypeBool:
          result = [[ACGPBInt64BoolDictionary alloc] init];
          break;
        case ACGPBDataTypeFixed32:
        case ACGPBDataTypeUInt32:
          result = [[ACGPBInt64UInt32Dictionary alloc] init];
          break;
        case ACGPBDataTypeInt32:
        case ACGPBDataTypeSFixed32:
        case ACGPBDataTypeSInt32:
          result = [[ACGPBInt64Int32Dictionary alloc] init];
          break;
        case ACGPBDataTypeFixed64:
        case ACGPBDataTypeUInt64:
          result = [[ACGPBInt64UInt64Dictionary alloc] init];
          break;
        case ACGPBDataTypeInt64:
        case ACGPBDataTypeSFixed64:
        case ACGPBDataTypeSInt64:
          result = [[ACGPBInt64Int64Dictionary alloc] init];
          break;
        case ACGPBDataTypeFloat:
          result = [[ACGPBInt64FloatDictionary alloc] init];
          break;
        case ACGPBDataTypeDouble:
          result = [[ACGPBInt64DoubleDictionary alloc] init];
          break;
        case ACGPBDataTypeEnum:
          result = [[ACGPBInt64EnumDictionary alloc]
              initWithValidationFunction:field.enumDescriptor.enumVerifier];
          break;
        case ACGPBDataTypeBytes:
        case ACGPBDataTypeMessage:
        case ACGPBDataTypeString:
          result = [[ACGPBInt64ObjectDictionary alloc] init];
          break;
        case ACGPBDataTypeGroup:
          NSCAssert(NO, @"shouldn't happen");
          return nil;
      }
      break;
    case ACGPBDataTypeString:
      switch (valueDataType) {
        case ACGPBDataTypeBool:
          result = [[ACGPBStringBoolDictionary alloc] init];
          break;
        case ACGPBDataTypeFixed32:
        case ACGPBDataTypeUInt32:
          result = [[ACGPBStringUInt32Dictionary alloc] init];
          break;
        case ACGPBDataTypeInt32:
        case ACGPBDataTypeSFixed32:
        case ACGPBDataTypeSInt32:
          result = [[ACGPBStringInt32Dictionary alloc] init];
          break;
        case ACGPBDataTypeFixed64:
        case ACGPBDataTypeUInt64:
          result = [[ACGPBStringUInt64Dictionary alloc] init];
          break;
        case ACGPBDataTypeInt64:
        case ACGPBDataTypeSFixed64:
        case ACGPBDataTypeSInt64:
          result = [[ACGPBStringInt64Dictionary alloc] init];
          break;
        case ACGPBDataTypeFloat:
          result = [[ACGPBStringFloatDictionary alloc] init];
          break;
        case ACGPBDataTypeDouble:
          result = [[ACGPBStringDoubleDictionary alloc] init];
          break;
        case ACGPBDataTypeEnum:
          result = [[ACGPBStringEnumDictionary alloc]
              initWithValidationFunction:field.enumDescriptor.enumVerifier];
          break;
        case ACGPBDataTypeBytes:
        case ACGPBDataTypeMessage:
        case ACGPBDataTypeString:
          if (autocreator) {
            result = [[ACGPBAutocreatedDictionary alloc] init];
          } else {
            result = [[NSMutableDictionary alloc] init];
          }
          break;
        case ACGPBDataTypeGroup:
          NSCAssert(NO, @"shouldn't happen");
          return nil;
      }
      break;

    case ACGPBDataTypeFloat:
    case ACGPBDataTypeDouble:
    case ACGPBDataTypeEnum:
    case ACGPBDataTypeBytes:
    case ACGPBDataTypeGroup:
    case ACGPBDataTypeMessage:
      NSCAssert(NO, @"shouldn't happen");
      return nil;
  }

  if (autocreator) {
    if ((keyDataType == ACGPBDataTypeString) &&
        ACGPBDataTypeIsObject(valueDataType)) {
      ACGPBAutocreatedDictionary *autoDict = result;
      autoDict->_autocreator =  autocreator;
    } else {
      ACGPBInt32Int32Dictionary *gpbDict = result;
      gpbDict->_autocreator = autocreator;
    }
  }

  return result;
}

#if !defined(__clang_analyzer__)
// These functions are blocked from the analyzer because the analyzer sees the
// ACGPBSetRetainedObjectIvarWithFieldPrivate() call as consuming the array/map,
// so use of the array/map after the call returns is flagged as a use after
// free.
// But ACGPBSetRetainedObjectIvarWithFieldPrivate() is "consuming" the retain
// count be holding onto the object (it is transferring it), the object is
// still valid after returning from the call.  The other way to avoid this
// would be to add a -retain/-autorelease, but that would force every
// repeated/map field parsed into the autorelease pool which is both a memory
// and performance hit.

static id GetOrCreateArrayIvarWithField(ACGPBMessage *self,
                                        ACGPBFieldDescriptor *field) {
  id array = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
  if (!array) {
    // No lock needed, this is called from places expecting to mutate
    // so no threading protection is needed.
    array = CreateArrayForField(field, nil);
    ACGPBSetRetainedObjectIvarWithFieldPrivate(self, field, array);
  }
  return array;
}

// This is like ACGPBGetObjectIvarWithField(), but for arrays, it should
// only be used to wire the method into the class.
static id GetArrayIvarWithField(ACGPBMessage *self, ACGPBFieldDescriptor *field) {
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  _Atomic(id) *typePtr = (_Atomic(id) *)&storage[field->description_->offset];
  id array = atomic_load(typePtr);
  if (array) {
    return array;
  }

  id expected = nil;
  id autocreated = CreateArrayForField(field, self);
  if (atomic_compare_exchange_strong(typePtr, &expected, autocreated)) {
    // Value was set, return it.
    return autocreated;
  }

  // Some other thread set it, release the one created and return what got set.
  if (ACGPBFieldDataTypeIsObject(field)) {
    ACGPBAutocreatedArray *autoArray = autocreated;
    autoArray->_autocreator = nil;
  } else {
    ACGPBInt32Array *gpbArray = autocreated;
    gpbArray->_autocreator = nil;
  }
  [autocreated release];
  return expected;
}

static id GetOrCreateMapIvarWithField(ACGPBMessage *self,
                                      ACGPBFieldDescriptor *field) {
  id dict = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
  if (!dict) {
    // No lock needed, this is called from places expecting to mutate
    // so no threading protection is needed.
    dict = CreateMapForField(field, nil);
    ACGPBSetRetainedObjectIvarWithFieldPrivate(self, field, dict);
  }
  return dict;
}

// This is like ACGPBGetObjectIvarWithField(), but for maps, it should
// only be used to wire the method into the class.
static id GetMapIvarWithField(ACGPBMessage *self, ACGPBFieldDescriptor *field) {
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  _Atomic(id) *typePtr = (_Atomic(id) *)&storage[field->description_->offset];
  id dict = atomic_load(typePtr);
  if (dict) {
    return dict;
  }

  id expected = nil;
  id autocreated = CreateMapForField(field, self);
  if (atomic_compare_exchange_strong(typePtr, &expected, autocreated)) {
    // Value was set, return it.
    return autocreated;
  }

  // Some other thread set it, release the one created and return what got set.
  if ((field.mapKeyDataType == ACGPBDataTypeString) &&
      ACGPBFieldDataTypeIsObject(field)) {
    ACGPBAutocreatedDictionary *autoDict = autocreated;
    autoDict->_autocreator = nil;
  } else {
    ACGPBInt32Int32Dictionary *gpbDict = autocreated;
    gpbDict->_autocreator = nil;
  }
  [autocreated release];
  return expected;
}

#endif  // !defined(__clang_analyzer__)

ACGPBMessage *ACGPBCreateMessageWithAutocreator(Class msgClass,
                                            ACGPBMessage *autocreator,
                                            ACGPBFieldDescriptor *field) {
  ACGPBMessage *message = [[msgClass alloc] init];
  message->autocreator_ = autocreator;
  message->autocreatorField_ = [field retain];
  return message;
}

static ACGPBMessage *CreateMessageWithAutocreatorForExtension(
    Class msgClass, ACGPBMessage *autocreator, ACGPBExtensionDescriptor *extension)
    __attribute__((ns_returns_retained));

static ACGPBMessage *CreateMessageWithAutocreatorForExtension(
    Class msgClass, ACGPBMessage *autocreator,
    ACGPBExtensionDescriptor *extension) {
  ACGPBMessage *message = [[msgClass alloc] init];
  message->autocreator_ = autocreator;
  message->autocreatorExtension_ = [extension retain];
  return message;
}

BOOL ACGPBWasMessageAutocreatedBy(ACGPBMessage *message, ACGPBMessage *parent) {
  return (message->autocreator_ == parent);
}

void ACGPBBecomeVisibleToAutocreator(ACGPBMessage *self) {
  // Message objects that are implicitly created by accessing a message field
  // are initially not visible via the hasX selector. This method makes them
  // visible.
  if (self->autocreator_) {
    // This will recursively make all parent messages visible until it reaches a
    // super-creator that's visible.
    if (self->autocreatorField_) {
      ACGPBSetObjectIvarWithFieldPrivate(self->autocreator_,
                                        self->autocreatorField_, self);
    } else {
      [self->autocreator_ setExtension:self->autocreatorExtension_ value:self];
    }
  }
}

void ACGPBAutocreatedArrayModified(ACGPBMessage *self, id array) {
  // When one of our autocreated arrays adds elements, make it visible.
  ACGPBDescriptor *descriptor = [[self class] descriptor];
  for (ACGPBFieldDescriptor *field in descriptor->fields_) {
    if (field.fieldType == ACGPBFieldTypeRepeated) {
      id curArray = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      if (curArray == array) {
        if (ACGPBFieldDataTypeIsObject(field)) {
          ACGPBAutocreatedArray *autoArray = array;
          autoArray->_autocreator = nil;
        } else {
          ACGPBInt32Array *gpbArray = array;
          gpbArray->_autocreator = nil;
        }
        ACGPBBecomeVisibleToAutocreator(self);
        return;
      }
    }
  }
  NSCAssert(NO, @"Unknown autocreated %@ for %@.", [array class], self);
}

void ACGPBAutocreatedDictionaryModified(ACGPBMessage *self, id dictionary) {
  // When one of our autocreated dicts adds elements, make it visible.
  ACGPBDescriptor *descriptor = [[self class] descriptor];
  for (ACGPBFieldDescriptor *field in descriptor->fields_) {
    if (field.fieldType == ACGPBFieldTypeMap) {
      id curDict = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      if (curDict == dictionary) {
        if ((field.mapKeyDataType == ACGPBDataTypeString) &&
            ACGPBFieldDataTypeIsObject(field)) {
          ACGPBAutocreatedDictionary *autoDict = dictionary;
          autoDict->_autocreator = nil;
        } else {
          ACGPBInt32Int32Dictionary *gpbDict = dictionary;
          gpbDict->_autocreator = nil;
        }
        ACGPBBecomeVisibleToAutocreator(self);
        return;
      }
    }
  }
  NSCAssert(NO, @"Unknown autocreated %@ for %@.", [dictionary class], self);
}

void ACGPBClearMessageAutocreator(ACGPBMessage *self) {
  if ((self == nil) || !self->autocreator_) {
    return;
  }

#if defined(DEBUG) && DEBUG && !defined(NS_BLOCK_ASSERTIONS)
  // Either the autocreator must have its "has" flag set to YES, or it must be
  // NO and not equal to ourselves.
  BOOL autocreatorHas =
      (self->autocreatorField_
           ? ACGPBGetHasIvarField(self->autocreator_, self->autocreatorField_)
           : [self->autocreator_ hasExtension:self->autocreatorExtension_]);
  ACGPBMessage *autocreatorFieldValue =
      (self->autocreatorField_
           ? ACGPBGetObjectIvarWithFieldNoAutocreate(self->autocreator_,
                                                   self->autocreatorField_)
           : [self->autocreator_->autocreatedExtensionMap_
                 objectForKey:self->autocreatorExtension_]);
  NSCAssert(autocreatorHas || autocreatorFieldValue != self,
            @"Cannot clear autocreator because it still refers to self, self: %@.",
            self);

#endif  // DEBUG && !defined(NS_BLOCK_ASSERTIONS)

  self->autocreator_ = nil;
  [self->autocreatorField_ release];
  self->autocreatorField_ = nil;
  [self->autocreatorExtension_ release];
  self->autocreatorExtension_ = nil;
}

// Call this before using the readOnlySemaphore_. This ensures it is created only once.
void ACGPBPrepareReadOnlySemaphore(ACGPBMessage *self) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

  // Create the semaphore on demand (rather than init) as developers might not cause them
  // to be needed, and the heap usage can add up.  The atomic swap is used to avoid needing
  // another lock around creating it.
  if (self->readOnlySemaphore_ == nil) {
    dispatch_semaphore_t worker = dispatch_semaphore_create(1);
    dispatch_semaphore_t expected = nil;
    if (!atomic_compare_exchange_strong(&self->readOnlySemaphore_, &expected, worker)) {
      dispatch_release(worker);
    }
#if defined(__clang_analyzer__)
    // The Xcode 9.2 (and 9.3 beta) static analyzer thinks worker is leaked
    // (doesn't seem to know about atomic_compare_exchange_strong); so just
    // for the analyzer, let it think worker is also released in this case.
    else { dispatch_release(worker); }
#endif
  }

#pragma clang diagnostic pop
}

static ACGPBUnknownFieldSet *GetOrMakeUnknownFields(ACGPBMessage *self) {
  if (!self->unknownFields_) {
    self->unknownFields_ = [[ACGPBUnknownFieldSet alloc] init];
    ACGPBBecomeVisibleToAutocreator(self);
  }
  return self->unknownFields_;
}

@implementation ACGPBMessage

+ (void)initialize {
  Class pbMessageClass = [ACGPBMessage class];
  if ([self class] == pbMessageClass) {
    // This is here to start up the "base" class descriptor.
    [self descriptor];
    // Message shares extension method resolving with ACGPBRootObject so insure
    // it is started up at the same time.
    (void)[ACGPBRootObject class];
  } else if ([self superclass] == pbMessageClass) {
    // This is here to start up all the "message" subclasses. Just needs to be
    // done for the messages, not any of the subclasses.
    // This must be done in initialize to enforce thread safety of start up of
    // the protocol buffer library.
    // Note: The generated code for -descriptor calls
    // +[ACGPBDescriptor allocDescriptorForClass:...], passing the ACGPBRootObject
    // subclass for the file.  That call chain is what ensures that *Root class
    // is started up to support extension resolution off the message class
    // (+resolveClassMethod: below) in a thread safe manner.
    [self descriptor];
  }
}

+ (instancetype)allocWithZone:(NSZone *)zone {
  // Override alloc to allocate our classes with the additional storage
  // required for the instance variables.
  ACGPBDescriptor *descriptor = [self descriptor];
  return NSAllocateObject(self, descriptor->storageSize_, zone);
}

+ (instancetype)alloc {
  return [self allocWithZone:nil];
}

+ (ACGPBDescriptor *)descriptor {
  // This is thread safe because it is called from +initialize.
  static ACGPBDescriptor *descriptor = NULL;
  static ACGPBFileDescriptor *fileDescriptor = NULL;
  if (!descriptor) {
    // Use a dummy file that marks it as proto2 syntax so when used generically
    // it supports unknowns/etc.
    fileDescriptor =
        [[ACGPBFileDescriptor alloc] initWithPackage:@"internal"
                                            syntax:ACGPBFileSyntaxProto2];

    descriptor = [ACGPBDescriptor allocDescriptorForClass:[ACGPBMessage class]
                                              rootClass:Nil
                                                   file:fileDescriptor
                                                 fields:NULL
                                             fieldCount:0
                                            storageSize:0
                                                  flags:0];
  }
  return descriptor;
}

+ (instancetype)message {
  return [[[self alloc] init] autorelease];
}

- (instancetype)init {
  if ((self = [super init])) {
    messageStorage_ = (ACGPBMessage_StoragePtr)(
        ((uint8_t *)self) + class_getInstanceSize([self class]));
  }

  return self;
}

- (instancetype)initWithData:(NSData *)data error:(NSError **)errorPtr {
  return [self initWithData:data extensionRegistry:nil error:errorPtr];
}

- (instancetype)initWithData:(NSData *)data
           extensionRegistry:(ACGPBExtensionRegistry *)extensionRegistry
                       error:(NSError **)errorPtr {
  if ((self = [self init])) {
    @try {
      [self mergeFromData:data extensionRegistry:extensionRegistry];
      if (errorPtr) {
        *errorPtr = nil;
      }
    }
    @catch (NSException *exception) {
      [self release];
      self = nil;
      if (errorPtr) {
        *errorPtr = ErrorFromException(exception);
      }
    }
#ifdef DEBUG
    if (self && !self.initialized) {
      [self release];
      self = nil;
      if (errorPtr) {
        *errorPtr = MessageError(ACGPBMessageErrorCodeMissingRequiredField, nil);
      }
    }
#endif
  }
  return self;
}

- (instancetype)initWithCodedInputStream:(ACGPBCodedInputStream *)input
                       extensionRegistry:
                           (ACGPBExtensionRegistry *)extensionRegistry
                                   error:(NSError **)errorPtr {
  if ((self = [self init])) {
    @try {
      [self mergeFromCodedInputStream:input extensionRegistry:extensionRegistry];
      if (errorPtr) {
        *errorPtr = nil;
      }
    }
    @catch (NSException *exception) {
      [self release];
      self = nil;
      if (errorPtr) {
        *errorPtr = ErrorFromException(exception);
      }
    }
#ifdef DEBUG
    if (self && !self.initialized) {
      [self release];
      self = nil;
      if (errorPtr) {
        *errorPtr = MessageError(ACGPBMessageErrorCodeMissingRequiredField, nil);
      }
    }
#endif
  }
  return self;
}

- (void)dealloc {
  [self internalClear:NO];
  NSCAssert(!autocreator_, @"Autocreator was not cleared before dealloc.");
  if (readOnlySemaphore_) {
    dispatch_release(readOnlySemaphore_);
  }
  [super dealloc];
}

- (void)copyFieldsInto:(ACGPBMessage *)message
                  zone:(NSZone *)zone
            descriptor:(ACGPBDescriptor *)descriptor {
  // Copy all the storage...
  memcpy(message->messageStorage_, messageStorage_, descriptor->storageSize_);

  // Loop over the fields doing fixup...
  for (ACGPBFieldDescriptor *field in descriptor->fields_) {
    if (ACGPBFieldIsMapOrArray(field)) {
      id value = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      if (value) {
        // We need to copy the array/map, but the catch is for message fields,
        // we also need to ensure all the messages as those need copying also.
        id newValue;
        if (ACGPBFieldDataTypeIsMessage(field)) {
          if (field.fieldType == ACGPBFieldTypeRepeated) {
            NSArray *existingArray = (NSArray *)value;
            NSMutableArray *newArray =
                [[NSMutableArray alloc] initWithCapacity:existingArray.count];
            newValue = newArray;
            for (ACGPBMessage *msg in existingArray) {
              ACGPBMessage *copiedMsg = [msg copyWithZone:zone];
              [newArray addObject:copiedMsg];
              [copiedMsg release];
            }
          } else {
            if (field.mapKeyDataType == ACGPBDataTypeString) {
              // Map is an NSDictionary.
              NSDictionary *existingDict = value;
              NSMutableDictionary *newDict = [[NSMutableDictionary alloc]
                  initWithCapacity:existingDict.count];
              newValue = newDict;
              [existingDict enumerateKeysAndObjectsUsingBlock:^(NSString *key,
                                                                ACGPBMessage *msg,
                                                                BOOL *stop) {
#pragma unused(stop)
                ACGPBMessage *copiedMsg = [msg copyWithZone:zone];
                [newDict setObject:copiedMsg forKey:key];
                [copiedMsg release];
              }];
            } else {
              // Is one of the ACGPB*ObjectDictionary classes.  Type doesn't
              // matter, just need one to invoke the selector.
              ACGPBInt32ObjectDictionary *existingDict = value;
              newValue = [existingDict deepCopyWithZone:zone];
            }
          }
        } else {
          // Not messages (but is a map/array)...
          if (field.fieldType == ACGPBFieldTypeRepeated) {
            if (ACGPBFieldDataTypeIsObject(field)) {
              // NSArray
              newValue = [value mutableCopyWithZone:zone];
            } else {
              // ACGPB*Array
              newValue = [value copyWithZone:zone];
            }
          } else {
            if ((field.mapKeyDataType == ACGPBDataTypeString) &&
                ACGPBFieldDataTypeIsObject(field)) {
              // NSDictionary
              newValue = [value mutableCopyWithZone:zone];
            } else {
              // Is one of the ACGPB*Dictionary classes.  Type doesn't matter,
              // just need one to invoke the selector.
              ACGPBInt32Int32Dictionary *existingDict = value;
              newValue = [existingDict copyWithZone:zone];
            }
          }
        }
        // We retain here because the memcpy picked up the pointer value and
        // the next call to SetRetainedObject... will release the current value.
        [value retain];
        ACGPBSetRetainedObjectIvarWithFieldPrivate(message, field, newValue);
      }
    } else if (ACGPBFieldDataTypeIsMessage(field)) {
      // For object types, if we have a value, copy it.  If we don't,
      // zero it to remove the pointer to something that was autocreated
      // (and the ptr just got memcpyed).
      if (ACGPBGetHasIvarField(self, field)) {
        ACGPBMessage *value = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        ACGPBMessage *newValue = [value copyWithZone:zone];
        // We retain here because the memcpy picked up the pointer value and
        // the next call to SetRetainedObject... will release the current value.
        [value retain];
        ACGPBSetRetainedObjectIvarWithFieldPrivate(message, field, newValue);
      } else {
        uint8_t *storage = (uint8_t *)message->messageStorage_;
        id *typePtr = (id *)&storage[field->description_->offset];
        *typePtr = NULL;
      }
    } else if (ACGPBFieldDataTypeIsObject(field) &&
               ACGPBGetHasIvarField(self, field)) {
      // A set string/data value (message picked off above), copy it.
      id value = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      id newValue = [value copyWithZone:zone];
      // We retain here because the memcpy picked up the pointer value and
      // the next call to SetRetainedObject... will release the current value.
      [value retain];
      ACGPBSetRetainedObjectIvarWithFieldPrivate(message, field, newValue);
    } else {
      // memcpy took care of the rest of the primitive fields if they were set.
    }
  }  // for (field in descriptor->fields_)
}

- (id)copyWithZone:(NSZone *)zone {
  ACGPBDescriptor *descriptor = [self descriptor];
  ACGPBMessage *result = [[descriptor.messageClass allocWithZone:zone] init];

  [self copyFieldsInto:result zone:zone descriptor:descriptor];
  // Make immutable copies of the extra bits.
  result->unknownFields_ = [unknownFields_ copyWithZone:zone];
  result->extensionMap_ = CloneExtensionMap(extensionMap_, zone);
  return result;
}

- (void)clear {
  [self internalClear:YES];
}

- (void)internalClear:(BOOL)zeroStorage {
  ACGPBDescriptor *descriptor = [self descriptor];
  for (ACGPBFieldDescriptor *field in descriptor->fields_) {
    if (ACGPBFieldIsMapOrArray(field)) {
      id arrayOrMap = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      if (arrayOrMap) {
        if (field.fieldType == ACGPBFieldTypeRepeated) {
          if (ACGPBFieldDataTypeIsObject(field)) {
            if ([arrayOrMap isKindOfClass:[ACGPBAutocreatedArray class]]) {
              ACGPBAutocreatedArray *autoArray = arrayOrMap;
              if (autoArray->_autocreator == self) {
                autoArray->_autocreator = nil;
              }
            }
          } else {
            // Type doesn't matter, it is a ACGPB*Array.
            ACGPBInt32Array *gpbArray = arrayOrMap;
            if (gpbArray->_autocreator == self) {
              gpbArray->_autocreator = nil;
            }
          }
        } else {
          if ((field.mapKeyDataType == ACGPBDataTypeString) &&
              ACGPBFieldDataTypeIsObject(field)) {
            if ([arrayOrMap isKindOfClass:[ACGPBAutocreatedDictionary class]]) {
              ACGPBAutocreatedDictionary *autoDict = arrayOrMap;
              if (autoDict->_autocreator == self) {
                autoDict->_autocreator = nil;
              }
            }
          } else {
            // Type doesn't matter, it is a ACGPB*Dictionary.
            ACGPBInt32Int32Dictionary *gpbDict = arrayOrMap;
            if (gpbDict->_autocreator == self) {
              gpbDict->_autocreator = nil;
            }
          }
        }
        [arrayOrMap release];
      }
    } else if (ACGPBFieldDataTypeIsMessage(field)) {
      ACGPBClearAutocreatedMessageIvarWithField(self, field);
      ACGPBMessage *value = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      [value release];
    } else if (ACGPBFieldDataTypeIsObject(field) &&
               ACGPBGetHasIvarField(self, field)) {
      id value = ACGPBGetObjectIvarWithField(self, field);
      [value release];
    }
  }

  // ACGPBClearMessageAutocreator() expects that its caller has already been
  // removed from autocreatedExtensionMap_ so we set to nil first.
  NSArray *autocreatedValues = [autocreatedExtensionMap_ allValues];
  [autocreatedExtensionMap_ release];
  autocreatedExtensionMap_ = nil;

  // Since we're clearing all of our extensions, make sure that we clear the
  // autocreator on any that we've created so they no longer refer to us.
  for (ACGPBMessage *value in autocreatedValues) {
    NSCAssert(ACGPBWasMessageAutocreatedBy(value, self),
              @"Autocreated extension does not refer back to self.");
    ACGPBClearMessageAutocreator(value);
  }

  [extensionMap_ release];
  extensionMap_ = nil;
  [unknownFields_ release];
  unknownFields_ = nil;

  // Note that clearing does not affect autocreator_. If we are being cleared
  // because of a dealloc, then autocreator_ should be nil anyway. If we are
  // being cleared because someone explicitly clears us, we don't want to
  // sever our relationship with our autocreator.

  if (zeroStorage) {
    memset(messageStorage_, 0, descriptor->storageSize_);
  }
}

- (BOOL)isInitialized {
  ACGPBDescriptor *descriptor = [self descriptor];
  for (ACGPBFieldDescriptor *field in descriptor->fields_) {
    if (field.isRequired) {
      if (!ACGPBGetHasIvarField(self, field)) {
        return NO;
      }
    }
    if (ACGPBFieldDataTypeIsMessage(field)) {
      ACGPBFieldType fieldType = field.fieldType;
      if (fieldType == ACGPBFieldTypeSingle) {
        if (field.isRequired) {
          ACGPBMessage *message = ACGPBGetMessageMessageField(self, field);
          if (!message.initialized) {
            return NO;
          }
        } else {
          NSAssert(field.isOptional,
                   @"%@: Single message field %@ not required or optional?",
                   [self class], field.name);
          if (ACGPBGetHasIvarField(self, field)) {
            ACGPBMessage *message = ACGPBGetMessageMessageField(self, field);
            if (!message.initialized) {
              return NO;
            }
          }
        }
      } else if (fieldType == ACGPBFieldTypeRepeated) {
        NSArray *array = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        for (ACGPBMessage *message in array) {
          if (!message.initialized) {
            return NO;
          }
        }
      } else {  // fieldType == ACGPBFieldTypeMap
        if (field.mapKeyDataType == ACGPBDataTypeString) {
          NSDictionary *map =
              ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
          if (map && !ACGPBDictionaryIsInitializedInternalHelper(map, field)) {
            return NO;
          }
        } else {
          // Real type is ACGPB*ObjectDictionary, exact type doesn't matter.
          ACGPBInt32ObjectDictionary *map =
              ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
          if (map && ![map isInitialized]) {
            return NO;
          }
        }
      }
    }
  }

  __block BOOL result = YES;
  [extensionMap_
      enumerateKeysAndObjectsUsingBlock:^(ACGPBExtensionDescriptor *extension,
                                          id obj,
                                          BOOL *stop) {
        if (ACGPBExtensionIsMessage(extension)) {
          if (extension.isRepeated) {
            for (ACGPBMessage *msg in obj) {
              if (!msg.initialized) {
                result = NO;
                *stop = YES;
                break;
              }
            }
          } else {
            ACGPBMessage *asMsg = obj;
            if (!asMsg.initialized) {
              result = NO;
              *stop = YES;
            }
          }
        }
      }];
  return result;
}

- (ACGPBDescriptor *)descriptor {
  return [[self class] descriptor];
}

- (NSData *)data {
#ifdef DEBUG
  if (!self.initialized) {
    return nil;
  }
#endif
  NSMutableData *data = [NSMutableData dataWithLength:[self serializedSize]];
  ACGPBCodedOutputStream *stream =
      [[ACGPBCodedOutputStream alloc] initWithData:data];
  @try {
    [self writeToCodedOutputStream:stream];
  }
  @catch (NSException *exception) {
    // This really shouldn't happen. The only way writeToCodedOutputStream:
    // could throw is if something in the library has a bug and the
    // serializedSize was wrong.
#ifdef DEBUG
    NSLog(@"%@: Internal exception while building message data: %@",
          [self class], exception);
#endif
    data = nil;
  }
  [stream release];
  return data;
}

- (NSData *)delimitedData {
  size_t serializedSize = [self serializedSize];
  size_t varintSize = ACGPBComputeRawVarint32SizeForInteger(serializedSize);
  NSMutableData *data =
      [NSMutableData dataWithLength:(serializedSize + varintSize)];
  ACGPBCodedOutputStream *stream =
      [[ACGPBCodedOutputStream alloc] initWithData:data];
  @try {
    [self writeDelimitedToCodedOutputStream:stream];
  }
  @catch (NSException *exception) {
    // This really shouldn't happen.  The only way writeToCodedOutputStream:
    // could throw is if something in the library has a bug and the
    // serializedSize was wrong.
#ifdef DEBUG
    NSLog(@"%@: Internal exception while building message delimitedData: %@",
          [self class], exception);
#endif
    // If it happens, truncate.
    data.length = 0;
  }
  [stream release];
  return data;
}

- (void)writeToOutputStream:(NSOutputStream *)output {
  ACGPBCodedOutputStream *stream =
      [[ACGPBCodedOutputStream alloc] initWithOutputStream:output];
  [self writeToCodedOutputStream:stream];
  [stream release];
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)output {
  ACGPBDescriptor *descriptor = [self descriptor];
  NSArray *fieldsArray = descriptor->fields_;
  NSUInteger fieldCount = fieldsArray.count;
  const ACGPBExtensionRange *extensionRanges = descriptor.extensionRanges;
  NSUInteger extensionRangesCount = descriptor.extensionRangesCount;
  NSArray *sortedExtensions =
      [[extensionMap_ allKeys] sortedArrayUsingSelector:@selector(compareByFieldNumber:)];
  for (NSUInteger i = 0, j = 0; i < fieldCount || j < extensionRangesCount;) {
    if (i == fieldCount) {
      [self writeExtensionsToCodedOutputStream:output
                                         range:extensionRanges[j++]
                              sortedExtensions:sortedExtensions];
    } else if (j == extensionRangesCount ||
               ACGPBFieldNumber(fieldsArray[i]) < extensionRanges[j].start) {
      [self writeField:fieldsArray[i++] toCodedOutputStream:output];
    } else {
      [self writeExtensionsToCodedOutputStream:output
                                         range:extensionRanges[j++]
                              sortedExtensions:sortedExtensions];
    }
  }
  if (descriptor.isWireFormat) {
    [unknownFields_ writeAsMessageSetTo:output];
  } else {
    [unknownFields_ writeToCodedOutputStream:output];
  }
}

- (void)writeDelimitedToOutputStream:(NSOutputStream *)output {
  ACGPBCodedOutputStream *codedOutput =
      [[ACGPBCodedOutputStream alloc] initWithOutputStream:output];
  [self writeDelimitedToCodedOutputStream:codedOutput];
  [codedOutput release];
}

- (void)writeDelimitedToCodedOutputStream:(ACGPBCodedOutputStream *)output {
  [output writeRawVarintSizeTAs32:[self serializedSize]];
  [self writeToCodedOutputStream:output];
}

- (void)writeField:(ACGPBFieldDescriptor *)field
    toCodedOutputStream:(ACGPBCodedOutputStream *)output {
  ACGPBFieldType fieldType = field.fieldType;
  if (fieldType == ACGPBFieldTypeSingle) {
    BOOL has = ACGPBGetHasIvarField(self, field);
    if (!has) {
      return;
    }
  }
  uint32_t fieldNumber = ACGPBFieldNumber(field);

//%PDDM-DEFINE FIELD_CASE(TYPE, REAL_TYPE)
//%FIELD_CASE_FULL(TYPE, REAL_TYPE, REAL_TYPE)
//%PDDM-DEFINE FIELD_CASE_FULL(TYPE, REAL_TYPE, ARRAY_TYPE)
//%    case ACGPBDataType##TYPE:
//%      if (fieldType == ACGPBFieldTypeRepeated) {
//%        uint32_t tag = field.isPackable ? ACGPBFieldTag(field) : 0;
//%        ACGPB##ARRAY_TYPE##Array *array =
//%            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
//%        [output write##TYPE##Array:fieldNumber values:array tag:tag];
//%      } else if (fieldType == ACGPBFieldTypeSingle) {
//%        [output write##TYPE:fieldNumber
//%              TYPE$S  value:ACGPBGetMessage##REAL_TYPE##Field(self, field)];
//%      } else {  // fieldType == ACGPBFieldTypeMap
//%        // Exact type here doesn't matter.
//%        ACGPBInt32##ARRAY_TYPE##Dictionary *dict =
//%            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
//%        [dict writeToCodedOutputStream:output asField:field];
//%      }
//%      break;
//%
//%PDDM-DEFINE FIELD_CASE2(TYPE)
//%    case ACGPBDataType##TYPE:
//%      if (fieldType == ACGPBFieldTypeRepeated) {
//%        NSArray *array = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
//%        [output write##TYPE##Array:fieldNumber values:array];
//%      } else if (fieldType == ACGPBFieldTypeSingle) {
//%        // ACGPBGetObjectIvarWithFieldNoAutocreate() avoids doing the has check
//%        // again.
//%        [output write##TYPE:fieldNumber
//%              TYPE$S  value:ACGPBGetObjectIvarWithFieldNoAutocreate(self, field)];
//%      } else {  // fieldType == ACGPBFieldTypeMap
//%        // Exact type here doesn't matter.
//%        id dict = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
//%        ACGPBDataType mapKeyDataType = field.mapKeyDataType;
//%        if (mapKeyDataType == ACGPBDataTypeString) {
//%          ACGPBDictionaryWriteToStreamInternalHelper(output, dict, field);
//%        } else {
//%          [dict writeToCodedOutputStream:output asField:field];
//%        }
//%      }
//%      break;
//%

  switch (ACGPBGetFieldDataType(field)) {

//%PDDM-EXPAND FIELD_CASE(Bool, Bool)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeBool:
      if (fieldType == ACGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? ACGPBFieldTag(field) : 0;
        ACGPBBoolArray *array =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeBoolArray:fieldNumber values:array tag:tag];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        [output writeBool:fieldNumber
                    value:ACGPBGetMessageBoolField(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        ACGPBInt32BoolDictionary *dict =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE(Fixed32, UInt32)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeFixed32:
      if (fieldType == ACGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? ACGPBFieldTag(field) : 0;
        ACGPBUInt32Array *array =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeFixed32Array:fieldNumber values:array tag:tag];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        [output writeFixed32:fieldNumber
                       value:ACGPBGetMessageUInt32Field(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        ACGPBInt32UInt32Dictionary *dict =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE(SFixed32, Int32)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeSFixed32:
      if (fieldType == ACGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? ACGPBFieldTag(field) : 0;
        ACGPBInt32Array *array =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeSFixed32Array:fieldNumber values:array tag:tag];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        [output writeSFixed32:fieldNumber
                        value:ACGPBGetMessageInt32Field(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        ACGPBInt32Int32Dictionary *dict =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE(Float, Float)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeFloat:
      if (fieldType == ACGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? ACGPBFieldTag(field) : 0;
        ACGPBFloatArray *array =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeFloatArray:fieldNumber values:array tag:tag];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        [output writeFloat:fieldNumber
                     value:ACGPBGetMessageFloatField(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        ACGPBInt32FloatDictionary *dict =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE(Fixed64, UInt64)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeFixed64:
      if (fieldType == ACGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? ACGPBFieldTag(field) : 0;
        ACGPBUInt64Array *array =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeFixed64Array:fieldNumber values:array tag:tag];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        [output writeFixed64:fieldNumber
                       value:ACGPBGetMessageUInt64Field(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        ACGPBInt32UInt64Dictionary *dict =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE(SFixed64, Int64)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeSFixed64:
      if (fieldType == ACGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? ACGPBFieldTag(field) : 0;
        ACGPBInt64Array *array =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeSFixed64Array:fieldNumber values:array tag:tag];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        [output writeSFixed64:fieldNumber
                        value:ACGPBGetMessageInt64Field(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        ACGPBInt32Int64Dictionary *dict =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE(Double, Double)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeDouble:
      if (fieldType == ACGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? ACGPBFieldTag(field) : 0;
        ACGPBDoubleArray *array =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeDoubleArray:fieldNumber values:array tag:tag];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        [output writeDouble:fieldNumber
                      value:ACGPBGetMessageDoubleField(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        ACGPBInt32DoubleDictionary *dict =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE(Int32, Int32)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeInt32:
      if (fieldType == ACGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? ACGPBFieldTag(field) : 0;
        ACGPBInt32Array *array =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeInt32Array:fieldNumber values:array tag:tag];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        [output writeInt32:fieldNumber
                     value:ACGPBGetMessageInt32Field(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        ACGPBInt32Int32Dictionary *dict =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE(Int64, Int64)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeInt64:
      if (fieldType == ACGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? ACGPBFieldTag(field) : 0;
        ACGPBInt64Array *array =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeInt64Array:fieldNumber values:array tag:tag];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        [output writeInt64:fieldNumber
                     value:ACGPBGetMessageInt64Field(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        ACGPBInt32Int64Dictionary *dict =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE(SInt32, Int32)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeSInt32:
      if (fieldType == ACGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? ACGPBFieldTag(field) : 0;
        ACGPBInt32Array *array =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeSInt32Array:fieldNumber values:array tag:tag];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        [output writeSInt32:fieldNumber
                      value:ACGPBGetMessageInt32Field(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        ACGPBInt32Int32Dictionary *dict =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE(SInt64, Int64)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeSInt64:
      if (fieldType == ACGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? ACGPBFieldTag(field) : 0;
        ACGPBInt64Array *array =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeSInt64Array:fieldNumber values:array tag:tag];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        [output writeSInt64:fieldNumber
                      value:ACGPBGetMessageInt64Field(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        ACGPBInt32Int64Dictionary *dict =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE(UInt32, UInt32)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeUInt32:
      if (fieldType == ACGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? ACGPBFieldTag(field) : 0;
        ACGPBUInt32Array *array =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeUInt32Array:fieldNumber values:array tag:tag];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        [output writeUInt32:fieldNumber
                      value:ACGPBGetMessageUInt32Field(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        ACGPBInt32UInt32Dictionary *dict =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE(UInt64, UInt64)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeUInt64:
      if (fieldType == ACGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? ACGPBFieldTag(field) : 0;
        ACGPBUInt64Array *array =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeUInt64Array:fieldNumber values:array tag:tag];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        [output writeUInt64:fieldNumber
                      value:ACGPBGetMessageUInt64Field(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        ACGPBInt32UInt64Dictionary *dict =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE_FULL(Enum, Int32, Enum)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeEnum:
      if (fieldType == ACGPBFieldTypeRepeated) {
        uint32_t tag = field.isPackable ? ACGPBFieldTag(field) : 0;
        ACGPBEnumArray *array =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeEnumArray:fieldNumber values:array tag:tag];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        [output writeEnum:fieldNumber
                    value:ACGPBGetMessageInt32Field(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        ACGPBInt32EnumDictionary *dict =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [dict writeToCodedOutputStream:output asField:field];
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE2(Bytes)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeBytes:
      if (fieldType == ACGPBFieldTypeRepeated) {
        NSArray *array = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeBytesArray:fieldNumber values:array];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        // ACGPBGetObjectIvarWithFieldNoAutocreate() avoids doing the has check
        // again.
        [output writeBytes:fieldNumber
                     value:ACGPBGetObjectIvarWithFieldNoAutocreate(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        id dict = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        ACGPBDataType mapKeyDataType = field.mapKeyDataType;
        if (mapKeyDataType == ACGPBDataTypeString) {
          ACGPBDictionaryWriteToStreamInternalHelper(output, dict, field);
        } else {
          [dict writeToCodedOutputStream:output asField:field];
        }
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE2(String)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeString:
      if (fieldType == ACGPBFieldTypeRepeated) {
        NSArray *array = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeStringArray:fieldNumber values:array];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        // ACGPBGetObjectIvarWithFieldNoAutocreate() avoids doing the has check
        // again.
        [output writeString:fieldNumber
                      value:ACGPBGetObjectIvarWithFieldNoAutocreate(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        id dict = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        ACGPBDataType mapKeyDataType = field.mapKeyDataType;
        if (mapKeyDataType == ACGPBDataTypeString) {
          ACGPBDictionaryWriteToStreamInternalHelper(output, dict, field);
        } else {
          [dict writeToCodedOutputStream:output asField:field];
        }
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE2(Message)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeMessage:
      if (fieldType == ACGPBFieldTypeRepeated) {
        NSArray *array = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeMessageArray:fieldNumber values:array];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        // ACGPBGetObjectIvarWithFieldNoAutocreate() avoids doing the has check
        // again.
        [output writeMessage:fieldNumber
                       value:ACGPBGetObjectIvarWithFieldNoAutocreate(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        id dict = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        ACGPBDataType mapKeyDataType = field.mapKeyDataType;
        if (mapKeyDataType == ACGPBDataTypeString) {
          ACGPBDictionaryWriteToStreamInternalHelper(output, dict, field);
        } else {
          [dict writeToCodedOutputStream:output asField:field];
        }
      }
      break;

// clang-format on
//%PDDM-EXPAND FIELD_CASE2(Group)
// This block of code is generated, do not edit it directly.
// clang-format off

    case ACGPBDataTypeGroup:
      if (fieldType == ACGPBFieldTypeRepeated) {
        NSArray *array = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [output writeGroupArray:fieldNumber values:array];
      } else if (fieldType == ACGPBFieldTypeSingle) {
        // ACGPBGetObjectIvarWithFieldNoAutocreate() avoids doing the has check
        // again.
        [output writeGroup:fieldNumber
                     value:ACGPBGetObjectIvarWithFieldNoAutocreate(self, field)];
      } else {  // fieldType == ACGPBFieldTypeMap
        // Exact type here doesn't matter.
        id dict = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        ACGPBDataType mapKeyDataType = field.mapKeyDataType;
        if (mapKeyDataType == ACGPBDataTypeString) {
          ACGPBDictionaryWriteToStreamInternalHelper(output, dict, field);
        } else {
          [dict writeToCodedOutputStream:output asField:field];
        }
      }
      break;

// clang-format on
//%PDDM-EXPAND-END (18 expansions)
  }
}

#pragma mark - Extensions

- (id)getExtension:(ACGPBExtensionDescriptor *)extension {
  CheckExtension(self, extension);
  id value = [extensionMap_ objectForKey:extension];
  if (value != nil) {
    return value;
  }

  // No default for repeated.
  if (extension.isRepeated) {
    return nil;
  }
  // Non messages get their default.
  if (!ACGPBExtensionIsMessage(extension)) {
    return extension.defaultValue;
  }

  // Check for an autocreated value.
  ACGPBPrepareReadOnlySemaphore(self);
  dispatch_semaphore_wait(readOnlySemaphore_, DISPATCH_TIME_FOREVER);
  value = [autocreatedExtensionMap_ objectForKey:extension];
  if (!value) {
    // Auto create the message extensions to match normal fields.
    value = CreateMessageWithAutocreatorForExtension(extension.msgClass, self,
                                                     extension);

    if (autocreatedExtensionMap_ == nil) {
      autocreatedExtensionMap_ = [[NSMutableDictionary alloc] init];
    }

    // We can't simply call setExtension here because that would clear the new
    // value's autocreator.
    [autocreatedExtensionMap_ setObject:value forKey:extension];
    [value release];
  }

  dispatch_semaphore_signal(readOnlySemaphore_);
  return value;
}

- (id)getExistingExtension:(ACGPBExtensionDescriptor *)extension {
  // This is an internal method so we don't need to call CheckExtension().
  return [extensionMap_ objectForKey:extension];
}

- (BOOL)hasExtension:(ACGPBExtensionDescriptor *)extension {
#if defined(DEBUG) && DEBUG
  CheckExtension(self, extension);
#endif  // DEBUG
  return nil != [extensionMap_ objectForKey:extension];
}

- (NSArray *)extensionsCurrentlySet {
  return [extensionMap_ allKeys];
}

- (void)writeExtensionsToCodedOutputStream:(ACGPBCodedOutputStream *)output
                                     range:(ACGPBExtensionRange)range
                          sortedExtensions:(NSArray *)sortedExtensions {
  uint32_t start = range.start;
  uint32_t end = range.end;
  for (ACGPBExtensionDescriptor *extension in sortedExtensions) {
    uint32_t fieldNumber = extension.fieldNumber;
    if (fieldNumber < start) {
      continue;
    }
    if (fieldNumber >= end) {
      break;
    }
    id value = [extensionMap_ objectForKey:extension];
    ACGPBWriteExtensionValueToOutputStream(extension, value, output);
  }
}

- (void)setExtension:(ACGPBExtensionDescriptor *)extension value:(id)value {
  if (!value) {
    [self clearExtension:extension];
    return;
  }

  CheckExtension(self, extension);

  if (extension.repeated) {
    [NSException raise:NSInvalidArgumentException
                format:@"Must call addExtension() for repeated types."];
  }

  if (extensionMap_ == nil) {
    extensionMap_ = [[NSMutableDictionary alloc] init];
  }

  // This pointless cast is for CLANG_WARN_NULLABLE_TO_NONNULL_CONVERSION.
  // Without it, the compiler complains we're passing an id nullable when
  // setObject:forKey: requires a id nonnull for the value. The check for
  // !value at the start of the method ensures it isn't nil, but the check
  // isn't smart enough to realize that.
  [extensionMap_ setObject:(id)value forKey:extension];

  ACGPBExtensionDescriptor *descriptor = extension;

  if (ACGPBExtensionIsMessage(descriptor) && !descriptor.isRepeated) {
    ACGPBMessage *autocreatedValue =
        [[autocreatedExtensionMap_ objectForKey:extension] retain];
    // Must remove from the map before calling ACGPBClearMessageAutocreator() so
    // that ACGPBClearMessageAutocreator() knows its safe to clear.
    [autocreatedExtensionMap_ removeObjectForKey:extension];
    ACGPBClearMessageAutocreator(autocreatedValue);
    [autocreatedValue release];
  }

  ACGPBBecomeVisibleToAutocreator(self);
}

- (void)addExtension:(ACGPBExtensionDescriptor *)extension value:(id)value {
  CheckExtension(self, extension);

  if (!extension.repeated) {
    [NSException raise:NSInvalidArgumentException
                format:@"Must call setExtension() for singular types."];
  }

  if (extensionMap_ == nil) {
    extensionMap_ = [[NSMutableDictionary alloc] init];
  }
  NSMutableArray *list = [extensionMap_ objectForKey:extension];
  if (list == nil) {
    list = [NSMutableArray array];
    [extensionMap_ setObject:list forKey:extension];
  }

  [list addObject:value];
  ACGPBBecomeVisibleToAutocreator(self);
}

- (void)setExtension:(ACGPBExtensionDescriptor *)extension
               index:(NSUInteger)idx
               value:(id)value {
  CheckExtension(self, extension);

  if (!extension.repeated) {
    [NSException raise:NSInvalidArgumentException
                format:@"Must call setExtension() for singular types."];
  }

  if (extensionMap_ == nil) {
    extensionMap_ = [[NSMutableDictionary alloc] init];
  }

  NSMutableArray *list = [extensionMap_ objectForKey:extension];

  [list replaceObjectAtIndex:idx withObject:value];
  ACGPBBecomeVisibleToAutocreator(self);
}

- (void)clearExtension:(ACGPBExtensionDescriptor *)extension {
  CheckExtension(self, extension);

  // Only become visible if there was actually a value to clear.
  if ([extensionMap_ objectForKey:extension]) {
    [extensionMap_ removeObjectForKey:extension];
    ACGPBBecomeVisibleToAutocreator(self);
  }
}

#pragma mark - mergeFrom

- (void)mergeFromData:(NSData *)data
    extensionRegistry:(ACGPBExtensionRegistry *)extensionRegistry {
  ACGPBCodedInputStream *input = [[ACGPBCodedInputStream alloc] initWithData:data];
  [self mergeFromCodedInputStream:input extensionRegistry:extensionRegistry];
  [input checkLastTagWas:0];
  [input release];
}

#pragma mark - mergeDelimitedFrom

- (void)mergeDelimitedFromCodedInputStream:(ACGPBCodedInputStream *)input
                         extensionRegistry:(ACGPBExtensionRegistry *)extensionRegistry {
  ACGPBCodedInputStreamState *state = &input->state_;
  if (ACGPBCodedInputStreamIsAtEnd(state)) {
    return;
  }
  NSData *data = ACGPBCodedInputStreamReadRetainedBytesNoCopy(state);
  if (data == nil) {
    return;
  }
  [self mergeFromData:data extensionRegistry:extensionRegistry];
  [data release];
}

#pragma mark - Parse From Data Support

+ (instancetype)parseFromData:(NSData *)data error:(NSError **)errorPtr {
  return [self parseFromData:data extensionRegistry:nil error:errorPtr];
}

+ (instancetype)parseFromData:(NSData *)data
            extensionRegistry:(ACGPBExtensionRegistry *)extensionRegistry
                        error:(NSError **)errorPtr {
  return [[[self alloc] initWithData:data
                   extensionRegistry:extensionRegistry
                               error:errorPtr] autorelease];
}

+ (instancetype)parseFromCodedInputStream:(ACGPBCodedInputStream *)input
                        extensionRegistry:(ACGPBExtensionRegistry *)extensionRegistry
                                    error:(NSError **)errorPtr {
  return
      [[[self alloc] initWithCodedInputStream:input
                            extensionRegistry:extensionRegistry
                                        error:errorPtr] autorelease];
}

#pragma mark - Parse Delimited From Data Support

+ (instancetype)parseDelimitedFromCodedInputStream:(ACGPBCodedInputStream *)input
                                 extensionRegistry:
                                     (ACGPBExtensionRegistry *)extensionRegistry
                                             error:(NSError **)errorPtr {
  ACGPBMessage *message = [[[self alloc] init] autorelease];
  @try {
    [message mergeDelimitedFromCodedInputStream:input
                              extensionRegistry:extensionRegistry];
    if (errorPtr) {
      *errorPtr = nil;
    }
  }
  @catch (NSException *exception) {
    message = nil;
    if (errorPtr) {
      *errorPtr = ErrorFromException(exception);
    }
  }
#ifdef DEBUG
  if (message && !message.initialized) {
    message = nil;
    if (errorPtr) {
      *errorPtr = MessageError(ACGPBMessageErrorCodeMissingRequiredField, nil);
    }
  }
#endif
  return message;
}

#pragma mark - Unknown Field Support

- (ACGPBUnknownFieldSet *)unknownFields {
  return unknownFields_;
}

- (void)setUnknownFields:(ACGPBUnknownFieldSet *)unknownFields {
  if (unknownFields != unknownFields_) {
    [unknownFields_ release];
    unknownFields_ = [unknownFields copy];
    ACGPBBecomeVisibleToAutocreator(self);
  }
}

- (void)parseMessageSet:(ACGPBCodedInputStream *)input
      extensionRegistry:(ACGPBExtensionRegistry *)extensionRegistry {
  uint32_t typeId = 0;
  NSData *rawBytes = nil;
  ACGPBExtensionDescriptor *extension = nil;
  ACGPBCodedInputStreamState *state = &input->state_;
  while (true) {
    uint32_t tag = ACGPBCodedInputStreamReadTag(state);
    if (tag == 0) {
      break;
    }

    if (tag == ACGPBWireFormatMessageSetTypeIdTag) {
      typeId = ACGPBCodedInputStreamReadUInt32(state);
      if (typeId != 0) {
        extension = [extensionRegistry extensionForDescriptor:[self descriptor]
                                                  fieldNumber:typeId];
      }
    } else if (tag == ACGPBWireFormatMessageSetMessageTag) {
      rawBytes =
          [ACGPBCodedInputStreamReadRetainedBytesNoCopy(state) autorelease];
    } else {
      if (![input skipField:tag]) {
        break;
      }
    }
  }

  [input checkLastTagWas:ACGPBWireFormatMessageSetItemEndTag];

  if (rawBytes != nil && typeId != 0) {
    if (extension != nil) {
      ACGPBCodedInputStream *newInput =
          [[ACGPBCodedInputStream alloc] initWithData:rawBytes];
      ACGPBExtensionMergeFromInputStream(extension,
                                       extension.packable,
                                       newInput,
                                       extensionRegistry,
                                       self);
      [newInput release];
    } else {
      ACGPBUnknownFieldSet *unknownFields = GetOrMakeUnknownFields(self);
      // rawBytes was created via a NoCopy, so it can be reusing a
      // subrange of another NSData that might go out of scope as things
      // unwind, so a copy is needed to ensure what is saved in the
      // unknown fields stays valid.
      NSData *cloned = [NSData dataWithData:rawBytes];
      [unknownFields mergeMessageSetMessage:typeId data:cloned];
    }
  }
}

- (BOOL)parseUnknownField:(ACGPBCodedInputStream *)input
        extensionRegistry:(ACGPBExtensionRegistry *)extensionRegistry
                      tag:(uint32_t)tag {
  ACGPBWireFormat wireType = ACGPBWireFormatGetTagWireType(tag);
  int32_t fieldNumber = ACGPBWireFormatGetTagFieldNumber(tag);

  ACGPBDescriptor *descriptor = [self descriptor];
  ACGPBExtensionDescriptor *extension =
      [extensionRegistry extensionForDescriptor:descriptor
                                    fieldNumber:fieldNumber];
  if (extension == nil) {
    if (descriptor.wireFormat && ACGPBWireFormatMessageSetItemTag == tag) {
      [self parseMessageSet:input extensionRegistry:extensionRegistry];
      return YES;
    }
  } else {
    if (extension.wireType == wireType) {
      ACGPBExtensionMergeFromInputStream(extension,
                                       extension.packable,
                                       input,
                                       extensionRegistry,
                                       self);
      return YES;
    }
    // Primitive, repeated types can be packed on unpacked on the wire, and are
    // parsed either way.
    if ([extension isRepeated] &&
        !ACGPBDataTypeIsObject(extension->description_->dataType) &&
        (extension.alternateWireType == wireType)) {
      ACGPBExtensionMergeFromInputStream(extension,
                                       !extension.packable,
                                       input,
                                       extensionRegistry,
                                       self);
      return YES;
    }
  }
  if ([ACGPBUnknownFieldSet isFieldTag:tag]) {
    ACGPBUnknownFieldSet *unknownFields = GetOrMakeUnknownFields(self);
    return [unknownFields mergeFieldFrom:tag input:input];
  } else {
    return NO;
  }
}

- (void)addUnknownMapEntry:(int32_t)fieldNum value:(NSData *)data {
  ACGPBUnknownFieldSet *unknownFields = GetOrMakeUnknownFields(self);
  [unknownFields addUnknownMapEntry:fieldNum value:data];
}

#pragma mark - MergeFromCodedInputStream Support

static void MergeSingleFieldFromCodedInputStream(
    ACGPBMessage *self, ACGPBFieldDescriptor *field, ACGPBFileSyntax syntax,
    ACGPBCodedInputStream *input, ACGPBExtensionRegistry *extensionRegistry) {
  ACGPBDataType fieldDataType = ACGPBGetFieldDataType(field);
  switch (fieldDataType) {
#define CASE_SINGLE_POD(NAME, TYPE, FUNC_TYPE)                             \
    case ACGPBDataType##NAME: {                                              \
      TYPE val = ACGPBCodedInputStreamRead##NAME(&input->state_);            \
      ACGPBSet##FUNC_TYPE##IvarWithFieldPrivate(self, field, val);           \
      break;                                                               \
            }
#define CASE_SINGLE_OBJECT(NAME)                                           \
    case ACGPBDataType##NAME: {                                              \
      id val = ACGPBCodedInputStreamReadRetained##NAME(&input->state_);      \
      ACGPBSetRetainedObjectIvarWithFieldPrivate(self, field, val);          \
      break;                                                               \
    }
      CASE_SINGLE_POD(Bool, BOOL, Bool)
      CASE_SINGLE_POD(Fixed32, uint32_t, UInt32)
      CASE_SINGLE_POD(SFixed32, int32_t, Int32)
      CASE_SINGLE_POD(Float, float, Float)
      CASE_SINGLE_POD(Fixed64, uint64_t, UInt64)
      CASE_SINGLE_POD(SFixed64, int64_t, Int64)
      CASE_SINGLE_POD(Double, double, Double)
      CASE_SINGLE_POD(Int32, int32_t, Int32)
      CASE_SINGLE_POD(Int64, int64_t, Int64)
      CASE_SINGLE_POD(SInt32, int32_t, Int32)
      CASE_SINGLE_POD(SInt64, int64_t, Int64)
      CASE_SINGLE_POD(UInt32, uint32_t, UInt32)
      CASE_SINGLE_POD(UInt64, uint64_t, UInt64)
      CASE_SINGLE_OBJECT(Bytes)
      CASE_SINGLE_OBJECT(String)
#undef CASE_SINGLE_POD
#undef CASE_SINGLE_OBJECT

    case ACGPBDataTypeMessage: {
      if (ACGPBGetHasIvarField(self, field)) {
        // ACGPBGetObjectIvarWithFieldNoAutocreate() avoids doing the has
        // check again.
        ACGPBMessage *message =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [input readMessage:message extensionRegistry:extensionRegistry];
      } else {
        ACGPBMessage *message = [[field.msgClass alloc] init];
        [input readMessage:message extensionRegistry:extensionRegistry];
        ACGPBSetRetainedObjectIvarWithFieldPrivate(self, field, message);
      }
      break;
    }

    case ACGPBDataTypeGroup: {
      if (ACGPBGetHasIvarField(self, field)) {
        // ACGPBGetObjectIvarWithFieldNoAutocreate() avoids doing the has
        // check again.
        ACGPBMessage *message =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
        [input readGroup:ACGPBFieldNumber(field)
                      message:message
            extensionRegistry:extensionRegistry];
      } else {
        ACGPBMessage *message = [[field.msgClass alloc] init];
        [input readGroup:ACGPBFieldNumber(field)
                      message:message
            extensionRegistry:extensionRegistry];
        ACGPBSetRetainedObjectIvarWithFieldPrivate(self, field, message);
      }
      break;
    }

    case ACGPBDataTypeEnum: {
      int32_t val = ACGPBCodedInputStreamReadEnum(&input->state_);
      if (ACGPBHasPreservingUnknownEnumSemantics(syntax) ||
          [field isValidEnumValue:val]) {
        ACGPBSetInt32IvarWithFieldPrivate(self, field, val);
      } else {
        ACGPBUnknownFieldSet *unknownFields = GetOrMakeUnknownFields(self);
        [unknownFields mergeVarintField:ACGPBFieldNumber(field) value:val];
      }
    }
  }  // switch
}

static void MergeRepeatedPackedFieldFromCodedInputStream(
    ACGPBMessage *self, ACGPBFieldDescriptor *field, ACGPBFileSyntax syntax,
    ACGPBCodedInputStream *input) {
  ACGPBDataType fieldDataType = ACGPBGetFieldDataType(field);
  ACGPBCodedInputStreamState *state = &input->state_;
  id genericArray = GetOrCreateArrayIvarWithField(self, field);
  int32_t length = ACGPBCodedInputStreamReadInt32(state);
  size_t limit = ACGPBCodedInputStreamPushLimit(state, length);

  while (ACGPBCodedInputStreamBytesUntilLimit(state) > 0) {
    switch (fieldDataType) {
#define CASE_REPEATED_PACKED_POD(NAME, TYPE, ARRAY_TYPE)      \
     case ACGPBDataType##NAME: {                                \
       TYPE val = ACGPBCodedInputStreamRead##NAME(state);       \
       [(ACGPB##ARRAY_TYPE##Array *)genericArray addValue:val]; \
       break;                                                 \
     }
        CASE_REPEATED_PACKED_POD(Bool, BOOL, Bool)
        CASE_REPEATED_PACKED_POD(Fixed32, uint32_t, UInt32)
        CASE_REPEATED_PACKED_POD(SFixed32, int32_t, Int32)
        CASE_REPEATED_PACKED_POD(Float, float, Float)
        CASE_REPEATED_PACKED_POD(Fixed64, uint64_t, UInt64)
        CASE_REPEATED_PACKED_POD(SFixed64, int64_t, Int64)
        CASE_REPEATED_PACKED_POD(Double, double, Double)
        CASE_REPEATED_PACKED_POD(Int32, int32_t, Int32)
        CASE_REPEATED_PACKED_POD(Int64, int64_t, Int64)
        CASE_REPEATED_PACKED_POD(SInt32, int32_t, Int32)
        CASE_REPEATED_PACKED_POD(SInt64, int64_t, Int64)
        CASE_REPEATED_PACKED_POD(UInt32, uint32_t, UInt32)
        CASE_REPEATED_PACKED_POD(UInt64, uint64_t, UInt64)
#undef CASE_REPEATED_PACKED_POD

      case ACGPBDataTypeBytes:
      case ACGPBDataTypeString:
      case ACGPBDataTypeMessage:
      case ACGPBDataTypeGroup:
        NSCAssert(NO, @"Non primitive types can't be packed");
        break;

      case ACGPBDataTypeEnum: {
        int32_t val = ACGPBCodedInputStreamReadEnum(state);
        if (ACGPBHasPreservingUnknownEnumSemantics(syntax) ||
            [field isValidEnumValue:val]) {
          [(ACGPBEnumArray*)genericArray addRawValue:val];
        } else {
          ACGPBUnknownFieldSet *unknownFields = GetOrMakeUnknownFields(self);
          [unknownFields mergeVarintField:ACGPBFieldNumber(field) value:val];
        }
        break;
      }
    }  // switch
  }  // while(BytesUntilLimit() > 0)
  ACGPBCodedInputStreamPopLimit(state, limit);
}

static void MergeRepeatedNotPackedFieldFromCodedInputStream(
    ACGPBMessage *self, ACGPBFieldDescriptor *field, ACGPBFileSyntax syntax,
    ACGPBCodedInputStream *input, ACGPBExtensionRegistry *extensionRegistry) {
  ACGPBCodedInputStreamState *state = &input->state_;
  id genericArray = GetOrCreateArrayIvarWithField(self, field);

  switch (ACGPBGetFieldDataType(field)) {
#define CASE_REPEATED_NOT_PACKED_POD(NAME, TYPE, ARRAY_TYPE) \
   case ACGPBDataType##NAME: {                                 \
     TYPE val = ACGPBCodedInputStreamRead##NAME(state);        \
     [(ACGPB##ARRAY_TYPE##Array *)genericArray addValue:val];  \
     break;                                                  \
   }
#define CASE_REPEATED_NOT_PACKED_OBJECT(NAME)                \
   case ACGPBDataType##NAME: {                                 \
     id val = ACGPBCodedInputStreamReadRetained##NAME(state);  \
     [(NSMutableArray*)genericArray addObject:val];          \
     [val release];                                          \
     break;                                                  \
   }
      CASE_REPEATED_NOT_PACKED_POD(Bool, BOOL, Bool)
      CASE_REPEATED_NOT_PACKED_POD(Fixed32, uint32_t, UInt32)
      CASE_REPEATED_NOT_PACKED_POD(SFixed32, int32_t, Int32)
      CASE_REPEATED_NOT_PACKED_POD(Float, float, Float)
      CASE_REPEATED_NOT_PACKED_POD(Fixed64, uint64_t, UInt64)
      CASE_REPEATED_NOT_PACKED_POD(SFixed64, int64_t, Int64)
      CASE_REPEATED_NOT_PACKED_POD(Double, double, Double)
      CASE_REPEATED_NOT_PACKED_POD(Int32, int32_t, Int32)
      CASE_REPEATED_NOT_PACKED_POD(Int64, int64_t, Int64)
      CASE_REPEATED_NOT_PACKED_POD(SInt32, int32_t, Int32)
      CASE_REPEATED_NOT_PACKED_POD(SInt64, int64_t, Int64)
      CASE_REPEATED_NOT_PACKED_POD(UInt32, uint32_t, UInt32)
      CASE_REPEATED_NOT_PACKED_POD(UInt64, uint64_t, UInt64)
      CASE_REPEATED_NOT_PACKED_OBJECT(Bytes)
      CASE_REPEATED_NOT_PACKED_OBJECT(String)
#undef CASE_REPEATED_NOT_PACKED_POD
#undef CASE_NOT_PACKED_OBJECT
    case ACGPBDataTypeMessage: {
      ACGPBMessage *message = [[field.msgClass alloc] init];
      [input readMessage:message extensionRegistry:extensionRegistry];
      [(NSMutableArray*)genericArray addObject:message];
      [message release];
      break;
    }
    case ACGPBDataTypeGroup: {
      ACGPBMessage *message = [[field.msgClass alloc] init];
      [input readGroup:ACGPBFieldNumber(field)
                    message:message
          extensionRegistry:extensionRegistry];
      [(NSMutableArray*)genericArray addObject:message];
      [message release];
      break;
    }
    case ACGPBDataTypeEnum: {
      int32_t val = ACGPBCodedInputStreamReadEnum(state);
      if (ACGPBHasPreservingUnknownEnumSemantics(syntax) ||
          [field isValidEnumValue:val]) {
        [(ACGPBEnumArray*)genericArray addRawValue:val];
      } else {
        ACGPBUnknownFieldSet *unknownFields = GetOrMakeUnknownFields(self);
        [unknownFields mergeVarintField:ACGPBFieldNumber(field) value:val];
      }
      break;
    }
  }  // switch
}

- (void)mergeFromCodedInputStream:(ACGPBCodedInputStream *)input
                extensionRegistry:(ACGPBExtensionRegistry *)extensionRegistry {
  ACGPBDescriptor *descriptor = [self descriptor];
  ACGPBFileSyntax syntax = descriptor.file.syntax;
  ACGPBCodedInputStreamState *state = &input->state_;
  uint32_t tag = 0;
  NSUInteger startingIndex = 0;
  NSArray *fields = descriptor->fields_;
  NSUInteger numFields = fields.count;
  while (YES) {
    BOOL merged = NO;
    tag = ACGPBCodedInputStreamReadTag(state);
    if (tag == 0) {
      break;  // Reached end.
    }
    for (NSUInteger i = 0; i < numFields; ++i) {
      if (startingIndex >= numFields) startingIndex = 0;
      ACGPBFieldDescriptor *fieldDescriptor = fields[startingIndex];
      if (ACGPBFieldTag(fieldDescriptor) == tag) {
        ACGPBFieldType fieldType = fieldDescriptor.fieldType;
        if (fieldType == ACGPBFieldTypeSingle) {
          MergeSingleFieldFromCodedInputStream(self, fieldDescriptor, syntax,
                                               input, extensionRegistry);
          // Well formed protos will only have a single field once, advance
          // the starting index to the next field.
          startingIndex += 1;
        } else if (fieldType == ACGPBFieldTypeRepeated) {
          if (fieldDescriptor.isPackable) {
            MergeRepeatedPackedFieldFromCodedInputStream(
                self, fieldDescriptor, syntax, input);
            // Well formed protos will only have a repeated field that is
            // packed once, advance the starting index to the next field.
            startingIndex += 1;
          } else {
            MergeRepeatedNotPackedFieldFromCodedInputStream(
                self, fieldDescriptor, syntax, input, extensionRegistry);
          }
        } else {  // fieldType == ACGPBFieldTypeMap
          // ACGPB*Dictionary or NSDictionary, exact type doesn't matter at this
          // point.
          id map = GetOrCreateMapIvarWithField(self, fieldDescriptor);
          [input readMapEntry:map
            extensionRegistry:extensionRegistry
                        field:fieldDescriptor
                parentMessage:self];
        }
        merged = YES;
        break;
      } else {
        startingIndex += 1;
      }
    }  // for(i < numFields)

    if (!merged && (tag != 0)) {
      // Primitive, repeated types can be packed on unpacked on the wire, and
      // are parsed either way.  The above loop covered tag in the preferred
      // for, so this need to check the alternate form.
      for (NSUInteger i = 0; i < numFields; ++i) {
        if (startingIndex >= numFields) startingIndex = 0;
        ACGPBFieldDescriptor *fieldDescriptor = fields[startingIndex];
        if ((fieldDescriptor.fieldType == ACGPBFieldTypeRepeated) &&
            !ACGPBFieldDataTypeIsObject(fieldDescriptor) &&
            (ACGPBFieldAlternateTag(fieldDescriptor) == tag)) {
          BOOL alternateIsPacked = !fieldDescriptor.isPackable;
          if (alternateIsPacked) {
            MergeRepeatedPackedFieldFromCodedInputStream(
                self, fieldDescriptor, syntax, input);
            // Well formed protos will only have a repeated field that is
            // packed once, advance the starting index to the next field.
            startingIndex += 1;
          } else {
            MergeRepeatedNotPackedFieldFromCodedInputStream(
                self, fieldDescriptor, syntax, input, extensionRegistry);
          }
          merged = YES;
          break;
        } else {
          startingIndex += 1;
        }
      }
    }

    if (!merged) {
      if (tag == 0) {
        // zero signals EOF / limit reached
        return;
      } else {
        if (![self parseUnknownField:input
                   extensionRegistry:extensionRegistry
                                 tag:tag]) {
          // it's an endgroup tag
          return;
        }
      }
    }  // if(!merged)

  }  // while(YES)
}

#pragma mark - MergeFrom Support

- (void)mergeFrom:(ACGPBMessage *)other {
  Class selfClass = [self class];
  Class otherClass = [other class];
  if (!([selfClass isSubclassOfClass:otherClass] ||
        [otherClass isSubclassOfClass:selfClass])) {
    [NSException raise:NSInvalidArgumentException
                format:@"Classes must match %@ != %@", selfClass, otherClass];
  }

  // We assume something will be done and become visible.
  ACGPBBecomeVisibleToAutocreator(self);

  ACGPBDescriptor *descriptor = [[self class] descriptor];

  for (ACGPBFieldDescriptor *field in descriptor->fields_) {
    ACGPBFieldType fieldType = field.fieldType;
    if (fieldType == ACGPBFieldTypeSingle) {
      int32_t hasIndex = ACGPBFieldHasIndex(field);
      uint32_t fieldNumber = ACGPBFieldNumber(field);
      if (!ACGPBGetHasIvar(other, hasIndex, fieldNumber)) {
        // Other doesn't have the field set, on to the next.
        continue;
      }
      ACGPBDataType fieldDataType = ACGPBGetFieldDataType(field);
      switch (fieldDataType) {
        case ACGPBDataTypeBool:
          ACGPBSetBoolIvarWithFieldPrivate(
              self, field, ACGPBGetMessageBoolField(other, field));
          break;
        case ACGPBDataTypeSFixed32:
        case ACGPBDataTypeEnum:
        case ACGPBDataTypeInt32:
        case ACGPBDataTypeSInt32:
          ACGPBSetInt32IvarWithFieldPrivate(
              self, field, ACGPBGetMessageInt32Field(other, field));
          break;
        case ACGPBDataTypeFixed32:
        case ACGPBDataTypeUInt32:
          ACGPBSetUInt32IvarWithFieldPrivate(
              self, field, ACGPBGetMessageUInt32Field(other, field));
          break;
        case ACGPBDataTypeSFixed64:
        case ACGPBDataTypeInt64:
        case ACGPBDataTypeSInt64:
          ACGPBSetInt64IvarWithFieldPrivate(
              self, field, ACGPBGetMessageInt64Field(other, field));
          break;
        case ACGPBDataTypeFixed64:
        case ACGPBDataTypeUInt64:
          ACGPBSetUInt64IvarWithFieldPrivate(
              self, field, ACGPBGetMessageUInt64Field(other, field));
          break;
        case ACGPBDataTypeFloat:
          ACGPBSetFloatIvarWithFieldPrivate(
              self, field, ACGPBGetMessageFloatField(other, field));
          break;
        case ACGPBDataTypeDouble:
          ACGPBSetDoubleIvarWithFieldPrivate(
              self, field, ACGPBGetMessageDoubleField(other, field));
          break;
        case ACGPBDataTypeBytes:
        case ACGPBDataTypeString: {
          id otherVal = ACGPBGetObjectIvarWithFieldNoAutocreate(other, field);
          ACGPBSetObjectIvarWithFieldPrivate(self, field, otherVal);
          break;
        }
        case ACGPBDataTypeMessage:
        case ACGPBDataTypeGroup: {
          id otherVal = ACGPBGetObjectIvarWithFieldNoAutocreate(other, field);
          if (ACGPBGetHasIvar(self, hasIndex, fieldNumber)) {
            ACGPBMessage *message =
                ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
            [message mergeFrom:otherVal];
          } else {
            ACGPBMessage *message = [otherVal copy];
            ACGPBSetRetainedObjectIvarWithFieldPrivate(self, field, message);
          }
          break;
        }
      } // switch()
    } else if (fieldType == ACGPBFieldTypeRepeated) {
      // In the case of a list, they need to be appended, and there is no
      // _hasIvar to worry about setting.
      id otherArray =
          ACGPBGetObjectIvarWithFieldNoAutocreate(other, field);
      if (otherArray) {
        ACGPBDataType fieldDataType = field->description_->dataType;
        if (ACGPBDataTypeIsObject(fieldDataType)) {
          NSMutableArray *resultArray =
              GetOrCreateArrayIvarWithField(self, field);
          [resultArray addObjectsFromArray:otherArray];
        } else if (fieldDataType == ACGPBDataTypeEnum) {
          ACGPBEnumArray *resultArray =
              GetOrCreateArrayIvarWithField(self, field);
          [resultArray addRawValuesFromArray:otherArray];
        } else {
          // The array type doesn't matter, that all implement
          // -addValuesFromArray:.
          ACGPBInt32Array *resultArray =
              GetOrCreateArrayIvarWithField(self, field);
          [resultArray addValuesFromArray:otherArray];
        }
      }
    } else {  // fieldType = ACGPBFieldTypeMap
      // In the case of a map, they need to be merged, and there is no
      // _hasIvar to worry about setting.
      id otherDict = ACGPBGetObjectIvarWithFieldNoAutocreate(other, field);
      if (otherDict) {
        ACGPBDataType keyDataType = field.mapKeyDataType;
        ACGPBDataType valueDataType = field->description_->dataType;
        if (ACGPBDataTypeIsObject(keyDataType) &&
            ACGPBDataTypeIsObject(valueDataType)) {
          NSMutableDictionary *resultDict =
              GetOrCreateMapIvarWithField(self, field);
          [resultDict addEntriesFromDictionary:otherDict];
        } else if (valueDataType == ACGPBDataTypeEnum) {
          // The exact type doesn't matter, just need to know it is a
          // ACGPB*EnumDictionary.
          ACGPBInt32EnumDictionary *resultDict =
              GetOrCreateMapIvarWithField(self, field);
          [resultDict addRawEntriesFromDictionary:otherDict];
        } else {
          // The exact type doesn't matter, they all implement
          // -addEntriesFromDictionary:.
          ACGPBInt32Int32Dictionary *resultDict =
              GetOrCreateMapIvarWithField(self, field);
          [resultDict addEntriesFromDictionary:otherDict];
        }
      }
    }  // if (fieldType)..else if...else
  }  // for(fields)

  // Unknown fields.
  if (!unknownFields_) {
    [self setUnknownFields:other.unknownFields];
  } else {
    [unknownFields_ mergeUnknownFields:other.unknownFields];
  }

  // Extensions

  if (other->extensionMap_.count == 0) {
    return;
  }

  if (extensionMap_ == nil) {
    extensionMap_ =
        CloneExtensionMap(other->extensionMap_, NSZoneFromPointer(self));
  } else {
    for (ACGPBExtensionDescriptor *extension in other->extensionMap_) {
      id otherValue = [other->extensionMap_ objectForKey:extension];
      id value = [extensionMap_ objectForKey:extension];
      BOOL isMessageExtension = ACGPBExtensionIsMessage(extension);

      if (extension.repeated) {
        NSMutableArray *list = value;
        if (list == nil) {
          list = [[NSMutableArray alloc] init];
          [extensionMap_ setObject:list forKey:extension];
          [list release];
        }
        if (isMessageExtension) {
          for (ACGPBMessage *otherListValue in otherValue) {
            ACGPBMessage *copiedValue = [otherListValue copy];
            [list addObject:copiedValue];
            [copiedValue release];
          }
        } else {
          [list addObjectsFromArray:otherValue];
        }
      } else {
        if (isMessageExtension) {
          if (value) {
            [(ACGPBMessage *)value mergeFrom:(ACGPBMessage *)otherValue];
          } else {
            ACGPBMessage *copiedValue = [otherValue copy];
            [extensionMap_ setObject:copiedValue forKey:extension];
            [copiedValue release];
          }
        } else {
          [extensionMap_ setObject:otherValue forKey:extension];
        }
      }

      if (isMessageExtension && !extension.isRepeated) {
        ACGPBMessage *autocreatedValue =
            [[autocreatedExtensionMap_ objectForKey:extension] retain];
        // Must remove from the map before calling ACGPBClearMessageAutocreator()
        // so that ACGPBClearMessageAutocreator() knows its safe to clear.
        [autocreatedExtensionMap_ removeObjectForKey:extension];
        ACGPBClearMessageAutocreator(autocreatedValue);
        [autocreatedValue release];
      }
    }
  }
}

#pragma mark - isEqual: & hash Support

- (BOOL)isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBMessage class]]) {
    return NO;
  }
  ACGPBMessage *otherMsg = other;
  ACGPBDescriptor *descriptor = [[self class] descriptor];
  if ([[otherMsg class] descriptor] != descriptor) {
    return NO;
  }
  uint8_t *selfStorage = (uint8_t *)messageStorage_;
  uint8_t *otherStorage = (uint8_t *)otherMsg->messageStorage_;

  for (ACGPBFieldDescriptor *field in descriptor->fields_) {
    if (ACGPBFieldIsMapOrArray(field)) {
      // In the case of a list or map, there is no _hasIvar to worry about.
      // NOTE: These are NSArray/ACGPB*Array or NSDictionary/ACGPB*Dictionary, but
      // the type doesn't really matter as the objects all support -count and
      // -isEqual:.
      NSArray *resultMapOrArray =
          ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      NSArray *otherMapOrArray =
          ACGPBGetObjectIvarWithFieldNoAutocreate(other, field);
      // nil and empty are equal
      if (resultMapOrArray.count != 0 || otherMapOrArray.count != 0) {
        if (![resultMapOrArray isEqual:otherMapOrArray]) {
          return NO;
        }
      }
    } else {  // Single field
      int32_t hasIndex = ACGPBFieldHasIndex(field);
      uint32_t fieldNum = ACGPBFieldNumber(field);
      BOOL selfHas = ACGPBGetHasIvar(self, hasIndex, fieldNum);
      BOOL otherHas = ACGPBGetHasIvar(other, hasIndex, fieldNum);
      if (selfHas != otherHas) {
        return NO;  // Differing has values, not equal.
      }
      if (!selfHas) {
        // Same has values, was no, nothing else to check for this field.
        continue;
      }
      // Now compare the values.
      ACGPBDataType fieldDataType = ACGPBGetFieldDataType(field);
      size_t fieldOffset = field->description_->offset;
      switch (fieldDataType) {
        case ACGPBDataTypeBool: {
          // Bools are stored in has_bits to avoid needing explicit space in
          // the storage structure.
          // (the field number passed to the HasIvar helper doesn't really
          // matter since the offset is never negative)
          BOOL selfValue = ACGPBGetHasIvar(self, (int32_t)(fieldOffset), 0);
          BOOL otherValue = ACGPBGetHasIvar(other, (int32_t)(fieldOffset), 0);
          if (selfValue != otherValue) {
            return NO;
          }
          break;
        }
        case ACGPBDataTypeSFixed32:
        case ACGPBDataTypeInt32:
        case ACGPBDataTypeSInt32:
        case ACGPBDataTypeEnum:
        case ACGPBDataTypeFixed32:
        case ACGPBDataTypeUInt32:
        case ACGPBDataTypeFloat: {
          ACGPBInternalCompileAssert(sizeof(float) == sizeof(uint32_t), float_not_32_bits);
          // These are all 32bit, signed/unsigned doesn't matter for equality.
          uint32_t *selfValPtr = (uint32_t *)&selfStorage[fieldOffset];
          uint32_t *otherValPtr = (uint32_t *)&otherStorage[fieldOffset];
          if (*selfValPtr != *otherValPtr) {
            return NO;
          }
          break;
        }
        case ACGPBDataTypeSFixed64:
        case ACGPBDataTypeInt64:
        case ACGPBDataTypeSInt64:
        case ACGPBDataTypeFixed64:
        case ACGPBDataTypeUInt64:
        case ACGPBDataTypeDouble: {
          ACGPBInternalCompileAssert(sizeof(double) == sizeof(uint64_t), double_not_64_bits);
          // These are all 64bit, signed/unsigned doesn't matter for equality.
          uint64_t *selfValPtr = (uint64_t *)&selfStorage[fieldOffset];
          uint64_t *otherValPtr = (uint64_t *)&otherStorage[fieldOffset];
          if (*selfValPtr != *otherValPtr) {
            return NO;
          }
          break;
        }
        case ACGPBDataTypeBytes:
        case ACGPBDataTypeString:
        case ACGPBDataTypeMessage:
        case ACGPBDataTypeGroup: {
          // Type doesn't matter here, they all implement -isEqual:.
          id *selfValPtr = (id *)&selfStorage[fieldOffset];
          id *otherValPtr = (id *)&otherStorage[fieldOffset];
          if (![*selfValPtr isEqual:*otherValPtr]) {
            return NO;
          }
          break;
        }
      } // switch()
    }   // if(mapOrArray)...else
  }  // for(fields)

  // nil and empty are equal
  if (extensionMap_.count != 0 || otherMsg->extensionMap_.count != 0) {
    if (![extensionMap_ isEqual:otherMsg->extensionMap_]) {
      return NO;
    }
  }

  // nil and empty are equal
  ACGPBUnknownFieldSet *otherUnknowns = otherMsg->unknownFields_;
  if ([unknownFields_ countOfFields] != 0 ||
      [otherUnknowns countOfFields] != 0) {
    if (![unknownFields_ isEqual:otherUnknowns]) {
      return NO;
    }
  }

  return YES;
}

// It is very difficult to implement a generic hash for ProtoBuf messages that
// will perform well. If you need hashing on your ProtoBufs (eg you are using
// them as dictionary keys) you will probably want to implement a ProtoBuf
// message specific hash as a category on your protobuf class. Do not make it a
// category on ACGPBMessage as you will conflict with this hash, and will possibly
// override hash for all generated protobufs. A good implementation of hash will
// be really fast, so we would recommend only hashing protobufs that have an
// identifier field of some kind that you can easily hash. If you implement
// hash, we would strongly recommend overriding isEqual: in your category as
// well, as the default implementation of isEqual: is extremely slow, and may
// drastically affect performance in large sets.
- (NSUInteger)hash {
  ACGPBDescriptor *descriptor = [[self class] descriptor];
  const NSUInteger prime = 19;
  uint8_t *storage = (uint8_t *)messageStorage_;

  // Start with the descriptor and then mix it with some instance info.
  // Hopefully that will give a spread based on classes and what fields are set.
  NSUInteger result = (NSUInteger)descriptor;

  for (ACGPBFieldDescriptor *field in descriptor->fields_) {
    if (ACGPBFieldIsMapOrArray(field)) {
      // Exact type doesn't matter, just check if there are any elements.
      NSArray *mapOrArray = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
      NSUInteger count = mapOrArray.count;
      if (count) {
        // NSArray/NSDictionary use count, use the field number and the count.
        result = prime * result + ACGPBFieldNumber(field);
        result = prime * result + count;
      }
    } else if (ACGPBGetHasIvarField(self, field)) {
      // Just using the field number seemed simple/fast, but then a small
      // message class where all the same fields are always set (to different
      // things would end up all with the same hash, so pull in some data).
      ACGPBDataType fieldDataType = ACGPBGetFieldDataType(field);
      size_t fieldOffset = field->description_->offset;
      switch (fieldDataType) {
        case ACGPBDataTypeBool: {
          // Bools are stored in has_bits to avoid needing explicit space in
          // the storage structure.
          // (the field number passed to the HasIvar helper doesn't really
          // matter since the offset is never negative)
          BOOL value = ACGPBGetHasIvar(self, (int32_t)(fieldOffset), 0);
          result = prime * result + value;
          break;
        }
        case ACGPBDataTypeSFixed32:
        case ACGPBDataTypeInt32:
        case ACGPBDataTypeSInt32:
        case ACGPBDataTypeEnum:
        case ACGPBDataTypeFixed32:
        case ACGPBDataTypeUInt32:
        case ACGPBDataTypeFloat: {
          ACGPBInternalCompileAssert(sizeof(float) == sizeof(uint32_t), float_not_32_bits);
          // These are all 32bit, just mix it in.
          uint32_t *valPtr = (uint32_t *)&storage[fieldOffset];
          result = prime * result + *valPtr;
          break;
        }
        case ACGPBDataTypeSFixed64:
        case ACGPBDataTypeInt64:
        case ACGPBDataTypeSInt64:
        case ACGPBDataTypeFixed64:
        case ACGPBDataTypeUInt64:
        case ACGPBDataTypeDouble: {
          ACGPBInternalCompileAssert(sizeof(double) == sizeof(uint64_t), double_not_64_bits);
          // These are all 64bit, just mix what fits into an NSUInteger in.
          uint64_t *valPtr = (uint64_t *)&storage[fieldOffset];
          result = prime * result + (NSUInteger)(*valPtr);
          break;
        }
        case ACGPBDataTypeBytes:
        case ACGPBDataTypeString: {
          // Type doesn't matter here, they both implement -hash:.
          id *valPtr = (id *)&storage[fieldOffset];
          result = prime * result + [*valPtr hash];
          break;
        }

        case ACGPBDataTypeMessage:
        case ACGPBDataTypeGroup: {
          ACGPBMessage **valPtr = (ACGPBMessage **)&storage[fieldOffset];
          // Could call -hash on the sub message, but that could recurse pretty
          // deep; follow the lead of NSArray/NSDictionary and don't really
          // recurse for hash, instead use the field number and the descriptor
          // of the sub message.  Yes, this could suck for a bunch of messages
          // where they all only differ in the sub messages, but if you are
          // using a message with sub messages for something that needs -hash,
          // odds are you are also copying them as keys, and that deep copy
          // will also suck.
          result = prime * result + ACGPBFieldNumber(field);
          result = prime * result + (NSUInteger)[[*valPtr class] descriptor];
          break;
        }
      } // switch()
    }
  }

  // Unknowns and extensions are not included.

  return result;
}

#pragma mark - Description Support

- (NSString *)description {
  NSString *textFormat = ACGPBTextFormatForMessage(self, @"    ");
  NSString *description = [NSString
      stringWithFormat:@"<%@ %p>: {\n%@}", [self class], self, textFormat];
  return description;
}

#if defined(DEBUG) && DEBUG

// Xcode 5.1 added support for custom quick look info.
// https://developer.apple.com/library/ios/documentation/IDEs/Conceptual/CustomClassDisplay_in_QuickLook/CH01-quick_look_for_custom_objects/CH01-quick_look_for_custom_objects.html#//apple_ref/doc/uid/TP40014001-CH2-SW1
- (id)debugQuickLookObject {
  return ACGPBTextFormatForMessage(self, nil);
}

#endif  // DEBUG

#pragma mark - SerializedSize

- (size_t)serializedSize {
  ACGPBDescriptor *descriptor = [[self class] descriptor];
  size_t result = 0;

  // Has check is done explicitly, so ACGPBGetObjectIvarWithFieldNoAutocreate()
  // avoids doing the has check again.

  // Fields.
  for (ACGPBFieldDescriptor *fieldDescriptor in descriptor->fields_) {
    ACGPBFieldType fieldType = fieldDescriptor.fieldType;
    ACGPBDataType fieldDataType = ACGPBGetFieldDataType(fieldDescriptor);

    // Single Fields
    if (fieldType == ACGPBFieldTypeSingle) {
      BOOL selfHas = ACGPBGetHasIvarField(self, fieldDescriptor);
      if (!selfHas) {
        continue;  // Nothing to do.
      }

      uint32_t fieldNumber = ACGPBFieldNumber(fieldDescriptor);

      switch (fieldDataType) {
#define CASE_SINGLE_POD(NAME, TYPE, FUNC_TYPE)                                \
        case ACGPBDataType##NAME: {                                             \
          TYPE fieldVal = ACGPBGetMessage##FUNC_TYPE##Field(self, fieldDescriptor); \
          result += ACGPBCompute##NAME##Size(fieldNumber, fieldVal);            \
          break;                                                              \
        }
#define CASE_SINGLE_OBJECT(NAME)                                              \
        case ACGPBDataType##NAME: {                                             \
          id fieldVal = ACGPBGetObjectIvarWithFieldNoAutocreate(self, fieldDescriptor); \
          result += ACGPBCompute##NAME##Size(fieldNumber, fieldVal);            \
          break;                                                              \
        }
          CASE_SINGLE_POD(Bool, BOOL, Bool)
          CASE_SINGLE_POD(Fixed32, uint32_t, UInt32)
          CASE_SINGLE_POD(SFixed32, int32_t, Int32)
          CASE_SINGLE_POD(Float, float, Float)
          CASE_SINGLE_POD(Fixed64, uint64_t, UInt64)
          CASE_SINGLE_POD(SFixed64, int64_t, Int64)
          CASE_SINGLE_POD(Double, double, Double)
          CASE_SINGLE_POD(Int32, int32_t, Int32)
          CASE_SINGLE_POD(Int64, int64_t, Int64)
          CASE_SINGLE_POD(SInt32, int32_t, Int32)
          CASE_SINGLE_POD(SInt64, int64_t, Int64)
          CASE_SINGLE_POD(UInt32, uint32_t, UInt32)
          CASE_SINGLE_POD(UInt64, uint64_t, UInt64)
          CASE_SINGLE_OBJECT(Bytes)
          CASE_SINGLE_OBJECT(String)
          CASE_SINGLE_OBJECT(Message)
          CASE_SINGLE_OBJECT(Group)
          CASE_SINGLE_POD(Enum, int32_t, Int32)
#undef CASE_SINGLE_POD
#undef CASE_SINGLE_OBJECT
      }

    // Repeated Fields
    } else if (fieldType == ACGPBFieldTypeRepeated) {
      id genericArray =
          ACGPBGetObjectIvarWithFieldNoAutocreate(self, fieldDescriptor);
      NSUInteger count = [genericArray count];
      if (count == 0) {
        continue;  // Nothing to add.
      }
      __block size_t dataSize = 0;

      switch (fieldDataType) {
#define CASE_REPEATED_POD(NAME, TYPE, ARRAY_TYPE)                             \
    CASE_REPEATED_POD_EXTRA(NAME, TYPE, ARRAY_TYPE, )
#define CASE_REPEATED_POD_EXTRA(NAME, TYPE, ARRAY_TYPE, ARRAY_ACCESSOR_NAME)  \
        case ACGPBDataType##NAME: {                                             \
          ACGPB##ARRAY_TYPE##Array *array = genericArray;                       \
          [array enumerate##ARRAY_ACCESSOR_NAME##ValuesWithBlock:^(TYPE value, NSUInteger idx, BOOL *stop) { \
            _Pragma("unused(idx, stop)");                                     \
            dataSize += ACGPBCompute##NAME##SizeNoTag(value);                   \
          }];                                                                 \
          break;                                                              \
        }
#define CASE_REPEATED_OBJECT(NAME)                                            \
        case ACGPBDataType##NAME: {                                             \
          for (id value in genericArray) {                                    \
            dataSize += ACGPBCompute##NAME##SizeNoTag(value);                   \
          }                                                                   \
          break;                                                              \
        }
          CASE_REPEATED_POD(Bool, BOOL, Bool)
          CASE_REPEATED_POD(Fixed32, uint32_t, UInt32)
          CASE_REPEATED_POD(SFixed32, int32_t, Int32)
          CASE_REPEATED_POD(Float, float, Float)
          CASE_REPEATED_POD(Fixed64, uint64_t, UInt64)
          CASE_REPEATED_POD(SFixed64, int64_t, Int64)
          CASE_REPEATED_POD(Double, double, Double)
          CASE_REPEATED_POD(Int32, int32_t, Int32)
          CASE_REPEATED_POD(Int64, int64_t, Int64)
          CASE_REPEATED_POD(SInt32, int32_t, Int32)
          CASE_REPEATED_POD(SInt64, int64_t, Int64)
          CASE_REPEATED_POD(UInt32, uint32_t, UInt32)
          CASE_REPEATED_POD(UInt64, uint64_t, UInt64)
          CASE_REPEATED_OBJECT(Bytes)
          CASE_REPEATED_OBJECT(String)
          CASE_REPEATED_OBJECT(Message)
          CASE_REPEATED_OBJECT(Group)
          CASE_REPEATED_POD_EXTRA(Enum, int32_t, Enum, Raw)
#undef CASE_REPEATED_POD
#undef CASE_REPEATED_POD_EXTRA
#undef CASE_REPEATED_OBJECT
      }  // switch
      result += dataSize;
      size_t tagSize = ACGPBComputeTagSize(ACGPBFieldNumber(fieldDescriptor));
      if (fieldDataType == ACGPBDataTypeGroup) {
        // Groups have both a start and an end tag.
        tagSize *= 2;
      }
      if (fieldDescriptor.isPackable) {
        result += tagSize;
        result += ACGPBComputeSizeTSizeAsInt32NoTag(dataSize);
      } else {
        result += count * tagSize;
      }

    // Map<> Fields
    } else {  // fieldType == ACGPBFieldTypeMap
      if (ACGPBDataTypeIsObject(fieldDataType) &&
          (fieldDescriptor.mapKeyDataType == ACGPBDataTypeString)) {
        // If key type was string, then the map is an NSDictionary.
        NSDictionary *map =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, fieldDescriptor);
        if (map) {
          result += ACGPBDictionaryComputeSizeInternalHelper(map, fieldDescriptor);
        }
      } else {
        // Type will be ACGPB*GroupDictionary, exact type doesn't matter.
        ACGPBInt32Int32Dictionary *map =
            ACGPBGetObjectIvarWithFieldNoAutocreate(self, fieldDescriptor);
        result += [map computeSerializedSizeAsField:fieldDescriptor];
      }
    }
  }  // for(fields)

  // Add any unknown fields.
  if (descriptor.wireFormat) {
    result += [unknownFields_ serializedSizeAsMessageSet];
  } else {
    result += [unknownFields_ serializedSize];
  }

  // Add any extensions.
  for (ACGPBExtensionDescriptor *extension in extensionMap_) {
    id value = [extensionMap_ objectForKey:extension];
    result += ACGPBComputeExtensionSerializedSizeIncludingTag(extension, value);
  }

  return result;
}

#pragma mark - Resolve Methods Support

typedef struct ResolveIvarAccessorMethodResult {
  IMP impToAdd;
  SEL encodingSelector;
} ResolveIvarAccessorMethodResult;

// |field| can be __unsafe_unretained because they are created at startup
// and are essentially global. No need to pay for retain/release when
// they are captured in blocks.
static void ResolveIvarGet(__unsafe_unretained ACGPBFieldDescriptor *field,
                           ResolveIvarAccessorMethodResult *result) {
  ACGPBDataType fieldDataType = ACGPBGetFieldDataType(field);
  switch (fieldDataType) {
#define CASE_GET(NAME, TYPE, TRUE_NAME)                          \
    case ACGPBDataType##NAME: {                                    \
      result->impToAdd = imp_implementationWithBlock(^(id obj) { \
        return ACGPBGetMessage##TRUE_NAME##Field(obj, field);      \
       });                                                       \
      result->encodingSelector = @selector(get##NAME);           \
      break;                                                     \
    }
#define CASE_GET_OBJECT(NAME, TYPE, TRUE_NAME)                   \
    case ACGPBDataType##NAME: {                                    \
      result->impToAdd = imp_implementationWithBlock(^(id obj) { \
        return ACGPBGetObjectIvarWithField(obj, field);            \
       });                                                       \
      result->encodingSelector = @selector(get##NAME);           \
      break;                                                     \
    }
      CASE_GET(Bool, BOOL, Bool)
      CASE_GET(Fixed32, uint32_t, UInt32)
      CASE_GET(SFixed32, int32_t, Int32)
      CASE_GET(Float, float, Float)
      CASE_GET(Fixed64, uint64_t, UInt64)
      CASE_GET(SFixed64, int64_t, Int64)
      CASE_GET(Double, double, Double)
      CASE_GET(Int32, int32_t, Int32)
      CASE_GET(Int64, int64_t, Int64)
      CASE_GET(SInt32, int32_t, Int32)
      CASE_GET(SInt64, int64_t, Int64)
      CASE_GET(UInt32, uint32_t, UInt32)
      CASE_GET(UInt64, uint64_t, UInt64)
      CASE_GET_OBJECT(Bytes, id, Object)
      CASE_GET_OBJECT(String, id, Object)
      CASE_GET_OBJECT(Message, id, Object)
      CASE_GET_OBJECT(Group, id, Object)
      CASE_GET(Enum, int32_t, Enum)
#undef CASE_GET
  }
}

// See comment about __unsafe_unretained on ResolveIvarGet.
static void ResolveIvarSet(__unsafe_unretained ACGPBFieldDescriptor *field,
                           ResolveIvarAccessorMethodResult *result) {
  ACGPBDataType fieldDataType = ACGPBGetFieldDataType(field);
  switch (fieldDataType) {
#define CASE_SET(NAME, TYPE, TRUE_NAME)                                       \
    case ACGPBDataType##NAME: {                                                 \
      result->impToAdd = imp_implementationWithBlock(^(id obj, TYPE value) {  \
        return ACGPBSet##TRUE_NAME##IvarWithFieldPrivate(obj, field, value);    \
      });                                                                     \
      result->encodingSelector = @selector(set##NAME:);                       \
      break;                                                                  \
    }
#define CASE_SET_COPY(NAME)                                                   \
    case ACGPBDataType##NAME: {                                                 \
      result->impToAdd = imp_implementationWithBlock(^(id obj, id value) {    \
        return ACGPBSetRetainedObjectIvarWithFieldPrivate(obj, field, [value copy]); \
      });                                                                     \
      result->encodingSelector = @selector(set##NAME:);                       \
      break;                                                                  \
    }
      CASE_SET(Bool, BOOL, Bool)
      CASE_SET(Fixed32, uint32_t, UInt32)
      CASE_SET(SFixed32, int32_t, Int32)
      CASE_SET(Float, float, Float)
      CASE_SET(Fixed64, uint64_t, UInt64)
      CASE_SET(SFixed64, int64_t, Int64)
      CASE_SET(Double, double, Double)
      CASE_SET(Int32, int32_t, Int32)
      CASE_SET(Int64, int64_t, Int64)
      CASE_SET(SInt32, int32_t, Int32)
      CASE_SET(SInt64, int64_t, Int64)
      CASE_SET(UInt32, uint32_t, UInt32)
      CASE_SET(UInt64, uint64_t, UInt64)
      CASE_SET_COPY(Bytes)
      CASE_SET_COPY(String)
      CASE_SET(Message, id, Object)
      CASE_SET(Group, id, Object)
      CASE_SET(Enum, int32_t, Enum)
#undef CASE_SET
  }
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
  const ACGPBDescriptor *descriptor = [self descriptor];
  if (!descriptor) {
    return [super resolveInstanceMethod:sel];
  }

  // NOTE: hasOrCountSel_/setHasSel_ will be NULL if the field for the given
  // message should not have has support (done in ACGPBDescriptor.m), so there is
  // no need for checks here to see if has*/setHas* are allowed.
  ResolveIvarAccessorMethodResult result = {NULL, NULL};

  // See comment about __unsafe_unretained on ResolveIvarGet.
  for (__unsafe_unretained ACGPBFieldDescriptor *field in descriptor->fields_) {
    BOOL isMapOrArray = ACGPBFieldIsMapOrArray(field);
    if (!isMapOrArray) {
      // Single fields.
      if (sel == field->getSel_) {
        ResolveIvarGet(field, &result);
        break;
      } else if (sel == field->setSel_) {
        ResolveIvarSet(field, &result);
        break;
      } else if (sel == field->hasOrCountSel_) {
        int32_t index = ACGPBFieldHasIndex(field);
        uint32_t fieldNum = ACGPBFieldNumber(field);
        result.impToAdd = imp_implementationWithBlock(^(id obj) {
          return ACGPBGetHasIvar(obj, index, fieldNum);
        });
        result.encodingSelector = @selector(getBool);
        break;
      } else if (sel == field->setHasSel_) {
        result.impToAdd = imp_implementationWithBlock(^(id obj, BOOL value) {
          if (value) {
            [NSException raise:NSInvalidArgumentException
                        format:@"%@: %@ can only be set to NO (to clear field).",
                               [obj class],
                               NSStringFromSelector(field->setHasSel_)];
          }
          ACGPBClearMessageField(obj, field);
        });
        result.encodingSelector = @selector(setBool:);
        break;
      } else {
        ACGPBOneofDescriptor *oneof = field->containingOneof_;
        if (oneof && (sel == oneof->caseSel_)) {
          int32_t index = ACGPBFieldHasIndex(field);
          result.impToAdd = imp_implementationWithBlock(^(id obj) {
            return ACGPBGetHasOneof(obj, index);
          });
          result.encodingSelector = @selector(getEnum);
          break;
        }
      }
    } else {
      // map<>/repeated fields.
      if (sel == field->getSel_) {
        if (field.fieldType == ACGPBFieldTypeRepeated) {
          result.impToAdd = imp_implementationWithBlock(^(id obj) {
            return GetArrayIvarWithField(obj, field);
          });
        } else {
          result.impToAdd = imp_implementationWithBlock(^(id obj) {
            return GetMapIvarWithField(obj, field);
          });
        }
        result.encodingSelector = @selector(getArray);
        break;
      } else if (sel == field->setSel_) {
        // Local for syntax so the block can directly capture it and not the
        // full lookup.
        result.impToAdd = imp_implementationWithBlock(^(id obj, id value) {
          ACGPBSetObjectIvarWithFieldPrivate(obj, field, value);
        });
        result.encodingSelector = @selector(setArray:);
        break;
      } else if (sel == field->hasOrCountSel_) {
        result.impToAdd = imp_implementationWithBlock(^(id obj) {
          // Type doesn't matter, all *Array and *Dictionary types support
          // -count.
          NSArray *arrayOrMap =
              ACGPBGetObjectIvarWithFieldNoAutocreate(obj, field);
          return [arrayOrMap count];
        });
        result.encodingSelector = @selector(getArrayCount);
        break;
      }
    }
  }
  if (result.impToAdd) {
    const char *encoding =
        ACGPBMessageEncodingForSelector(result.encodingSelector, YES);
    Class msgClass = descriptor.messageClass;
    BOOL methodAdded = class_addMethod(msgClass, sel, result.impToAdd, encoding);
    // class_addMethod() is documented as also failing if the method was already
    // added; so we check if the method is already there and return success so
    // the method dispatch will still happen.  Why would it already be added?
    // Two threads could cause the same method to be bound at the same time,
    // but only one will actually bind it; the other still needs to return true
    // so things will dispatch.
    if (!methodAdded) {
      methodAdded = ACGPBClassHasSel(msgClass, sel);
    }
    return methodAdded;
  }
  return [super resolveInstanceMethod:sel];
}

+ (BOOL)resolveClassMethod:(SEL)sel {
  // Extensions scoped to a Message and looked up via class methods.
  if (ACGPBResolveExtensionClassMethod(self, sel)) {
    return YES;
  }
  return [super resolveClassMethod:sel];
}

#pragma mark - NSCoding Support

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [self init];
  if (self) {
    NSData *data =
        [aDecoder decodeObjectOfClass:[NSData class] forKey:kACGPBDataCoderKey];
    if (data.length) {
      [self mergeFromData:data extensionRegistry:nil];
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
#if defined(DEBUG) && DEBUG
  if (extensionMap_.count) {
    // Hint to go along with the docs on ACGPBMessage about this.
    //
    // Note: This is incomplete, in that it only checked the "root" message,
    // if a sub message in a field has extensions, the issue still exists. A
    // recursive check could be done here (like the work in
    // ACGPBMessageDropUnknownFieldsRecursively()), but that has the potential to
    // be expensive and could slow down serialization in DEBUG enough to cause
    // developers other problems.
    NSLog(@"Warning: writing out a ACGPBMessage (%@) via NSCoding and it"
          @" has %ld extensions; when read back in, those fields will be"
          @" in the unknownFields property instead.",
          [self class], (long)extensionMap_.count);
  }
#endif
  NSData *data = [self data];
  if (data.length) {
    [aCoder encodeObject:data forKey:kACGPBDataCoderKey];
  }
}

#pragma mark - KVC Support

+ (BOOL)accessInstanceVariablesDirectly {
  // Make sure KVC doesn't use instance variables.
  return NO;
}

@end

#pragma mark - Messages from ACGPBUtilities.h but defined here for access to helpers.

// Only exists for public api, no core code should use this.
id ACGPBGetMessageRepeatedField(ACGPBMessage *self, ACGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  if (field.fieldType != ACGPBFieldTypeRepeated) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@ is not a repeated field.",
     [self class], field.name];
  }
#endif
  return GetOrCreateArrayIvarWithField(self, field);
}

// Only exists for public api, no core code should use this.
id ACGPBGetMessageMapField(ACGPBMessage *self, ACGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  if (field.fieldType != ACGPBFieldTypeMap) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@ is not a map<> field.",
     [self class], field.name];
  }
#endif
  return GetOrCreateMapIvarWithField(self, field);
}

id ACGPBGetObjectIvarWithField(ACGPBMessage *self, ACGPBFieldDescriptor *field) {
  NSCAssert(!ACGPBFieldIsMapOrArray(field), @"Shouldn't get here");
  if (!ACGPBFieldDataTypeIsMessage(field)) {
    if (ACGPBGetHasIvarField(self, field)) {
      uint8_t *storage = (uint8_t *)self->messageStorage_;
      id *typePtr = (id *)&storage[field->description_->offset];
      return *typePtr;
    }
    // Not set...non messages (string/data), get their default.
    return field.defaultValue.valueMessage;
  }

  uint8_t *storage = (uint8_t *)self->messageStorage_;
  _Atomic(id) *typePtr = (_Atomic(id) *)&storage[field->description_->offset];
  id msg = atomic_load(typePtr);
  if (msg) {
    return msg;
  }

  id expected = nil;
  id autocreated = ACGPBCreateMessageWithAutocreator(field.msgClass, self, field);
  if (atomic_compare_exchange_strong(typePtr, &expected, autocreated)) {
    // Value was set, return it.
    return autocreated;
  }

  // Some other thread set it, release the one created and return what got set.
  ACGPBClearMessageAutocreator(autocreated);
  [autocreated release];
  return expected;
}

#pragma clang diagnostic pop
