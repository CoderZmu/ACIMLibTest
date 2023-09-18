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

#import "ACGPBUtilities_PackagePrivate.h"

#import <objc/runtime.h>

#import "ACGPBArray_PackagePrivate.h"
#import "ACGPBDescriptor_PackagePrivate.h"
#import "ACGPBDictionary_PackagePrivate.h"
#import "ACGPBMessage_PackagePrivate.h"
#import "ACGPBUnknownField.h"
#import "ACGPBUnknownFieldSet.h"

// Direct access is use for speed, to avoid even internally declaring things
// read/write, etc. The warning is enabled in the project to ensure code calling
// protos can turn on -Wdirect-ivar-access without issues.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

static void AppendTextFormatForMessage(ACGPBMessage *message,
                                       NSMutableString *toStr,
                                       NSString *lineIndent);

// Are two datatypes the same basic type representation (ex Int32 and SInt32).
// Marked unused because currently only called from asserts/debug.
static BOOL DataTypesEquivalent(ACGPBDataType type1,
                                ACGPBDataType type2) __attribute__ ((unused));

// Basic type representation for a type (ex: for SInt32 it is Int32).
// Marked unused because currently only called from asserts/debug.
static ACGPBDataType BaseDataType(ACGPBDataType type) __attribute__ ((unused));

// String name for a data type.
// Marked unused because currently only called from asserts/debug.
static NSString *TypeToString(ACGPBDataType dataType) __attribute__ ((unused));

// Helper for clearing oneofs.
static void ACGPBMaybeClearOneofPrivate(ACGPBMessage *self,
                                      ACGPBOneofDescriptor *oneof,
                                      int32_t oneofHasIndex,
                                      uint32_t fieldNumberNotToClear);

NSData *ACGPBEmptyNSData(void) {
  static dispatch_once_t onceToken;
  static NSData *defaultNSData = nil;
  dispatch_once(&onceToken, ^{
    defaultNSData = [[NSData alloc] init];
  });
  return defaultNSData;
}

void ACGPBMessageDropUnknownFieldsRecursively(ACGPBMessage *initialMessage) {
  if (!initialMessage) {
    return;
  }

  // Use an array as a list to process to avoid recursion.
  NSMutableArray *todo = [NSMutableArray arrayWithObject:initialMessage];

  while (todo.count) {
    ACGPBMessage *msg = todo.lastObject;
    [todo removeLastObject];

    // Clear unknowns.
    msg.unknownFields = nil;

    // Handle the message fields.
    ACGPBDescriptor *descriptor = [[msg class] descriptor];
    for (ACGPBFieldDescriptor *field in descriptor->fields_) {
      if (!ACGPBFieldDataTypeIsMessage(field)) {
        continue;
      }
      switch (field.fieldType) {
        case ACGPBFieldTypeSingle:
          if (ACGPBGetHasIvarField(msg, field)) {
            ACGPBMessage *fieldMessage = ACGPBGetObjectIvarWithFieldNoAutocreate(msg, field);
            [todo addObject:fieldMessage];
          }
          break;

        case ACGPBFieldTypeRepeated: {
          NSArray *fieldMessages = ACGPBGetObjectIvarWithFieldNoAutocreate(msg, field);
          if (fieldMessages.count) {
            [todo addObjectsFromArray:fieldMessages];
          }
          break;
        }

        case ACGPBFieldTypeMap: {
          id rawFieldMap = ACGPBGetObjectIvarWithFieldNoAutocreate(msg, field);
          switch (field.mapKeyDataType) {
            case ACGPBDataTypeBool:
              [(ACGPBBoolObjectDictionary*)rawFieldMap enumerateKeysAndObjectsUsingBlock:^(
                  BOOL key, id _Nonnull object, BOOL * _Nonnull stop) {
                #pragma unused(key, stop)
                [todo addObject:object];
              }];
              break;
            case ACGPBDataTypeFixed32:
            case ACGPBDataTypeUInt32:
              [(ACGPBUInt32ObjectDictionary*)rawFieldMap enumerateKeysAndObjectsUsingBlock:^(
                  uint32_t key, id _Nonnull object, BOOL * _Nonnull stop) {
                #pragma unused(key, stop)
                [todo addObject:object];
              }];
              break;
            case ACGPBDataTypeInt32:
            case ACGPBDataTypeSFixed32:
            case ACGPBDataTypeSInt32:
              [(ACGPBInt32ObjectDictionary*)rawFieldMap enumerateKeysAndObjectsUsingBlock:^(
                  int32_t key, id _Nonnull object, BOOL * _Nonnull stop) {
                #pragma unused(key, stop)
                [todo addObject:object];
              }];
              break;
            case ACGPBDataTypeFixed64:
            case ACGPBDataTypeUInt64:
              [(ACGPBUInt64ObjectDictionary*)rawFieldMap enumerateKeysAndObjectsUsingBlock:^(
                  uint64_t key, id _Nonnull object, BOOL * _Nonnull stop) {
                #pragma unused(key, stop)
                [todo addObject:object];
              }];
              break;
            case ACGPBDataTypeInt64:
            case ACGPBDataTypeSFixed64:
            case ACGPBDataTypeSInt64:
              [(ACGPBInt64ObjectDictionary*)rawFieldMap enumerateKeysAndObjectsUsingBlock:^(
                  int64_t key, id _Nonnull object, BOOL * _Nonnull stop) {
                #pragma unused(key, stop)
                [todo addObject:object];
              }];
              break;
            case ACGPBDataTypeString:
              [(NSDictionary*)rawFieldMap enumerateKeysAndObjectsUsingBlock:^(
                  NSString * _Nonnull key, ACGPBMessage * _Nonnull obj, BOOL * _Nonnull stop) {
                #pragma unused(key, stop)
                [todo addObject:obj];
              }];
              break;
            case ACGPBDataTypeFloat:
            case ACGPBDataTypeDouble:
            case ACGPBDataTypeEnum:
            case ACGPBDataTypeBytes:
            case ACGPBDataTypeGroup:
            case ACGPBDataTypeMessage:
              NSCAssert(NO, @"Aren't valid key types.");
          }
          break;
        }  // switch(field.mapKeyDataType)
      }  // switch(field.fieldType)
    }  // for(fields)

    // Handle any extensions holding messages.
    for (ACGPBExtensionDescriptor *extension in [msg extensionsCurrentlySet]) {
      if (!ACGPBDataTypeIsMessage(extension.dataType)) {
        continue;
      }
      if (extension.isRepeated) {
        NSArray *extMessages = [msg getExtension:extension];
        [todo addObjectsFromArray:extMessages];
      } else {
        ACGPBMessage *extMessage = [msg getExtension:extension];
        [todo addObject:extMessage];
      }
    }  // for(extensionsCurrentlySet)

  }  // while(todo.count)
}


// -- About Version Checks --
// There's actually 3 places these checks all come into play:
// 1. When the generated source is compile into .o files, the header check
//    happens. This is checking the protoc used matches the library being used
//    when making the .o.
// 2. Every place a generated proto header is included in a developer's code,
//    the header check comes into play again. But this time it is checking that
//    the current library headers being used still support/match the ones for
//    the generated code.
// 3. At runtime the final check here (ACGPBCheckRuntimeVersionsInternal), is
//    called from the generated code passing in values captured when the
//    generated code's .o was made. This checks that at runtime the generated
//    code and runtime library match.

void ACGPBCheckRuntimeVersionSupport(int32_t objcRuntimeVersion) {
  // NOTE: This is passing the value captured in the compiled code to check
  // against the values captured when the runtime support was compiled. This
  // ensures the library code isn't in a different framework/library that
  // was generated with a non matching version.
  if (GOOGLE_PROTOBUF_OBJC_VERSION < objcRuntimeVersion) {
    // Library is too old for headers.
    [NSException raise:NSInternalInconsistencyException
                format:@"Linked to ProtocolBuffer runtime version %d,"
                       @" but code compiled needing at least %d!",
                       GOOGLE_PROTOBUF_OBJC_VERSION, objcRuntimeVersion];
  }
  if (objcRuntimeVersion < GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION) {
    // Headers are too old for library.
    [NSException raise:NSInternalInconsistencyException
                format:@"Proto generation source compiled against runtime"
                       @" version %d, but this version of the runtime only"
                       @" supports back to %d!",
                       objcRuntimeVersion,
                       GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION];
  }
}

// This api is no longer used for version checks. 30001 is the last version
// using this old versioning model. When that support is removed, this function
// can be removed (along with the declaration in ACGPBUtilities_PackagePrivate.h).
void ACGPBCheckRuntimeVersionInternal(int32_t version) {
  ACGPBInternalCompileAssert(GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION == 30001,
                           time_to_remove_this_old_version_shim);
  if (version != GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION) {
    [NSException raise:NSInternalInconsistencyException
                format:@"Linked to ProtocolBuffer runtime version %d,"
                       @" but code compiled with version %d!",
                       GOOGLE_PROTOBUF_OBJC_GEN_VERSION, version];
  }
}

BOOL ACGPBMessageHasFieldNumberSet(ACGPBMessage *self, uint32_t fieldNumber) {
  ACGPBDescriptor *descriptor = [self descriptor];
  ACGPBFieldDescriptor *field = [descriptor fieldWithNumber:fieldNumber];
  return ACGPBMessageHasFieldSet(self, field);
}

BOOL ACGPBMessageHasFieldSet(ACGPBMessage *self, ACGPBFieldDescriptor *field) {
  if (self == nil || field == nil) return NO;

  // Repeated/Map don't use the bit, they check the count.
  if (ACGPBFieldIsMapOrArray(field)) {
    // Array/map type doesn't matter, since ACGPB*Array/NSArray and
    // ACGPB*Dictionary/NSDictionary all support -count;
    NSArray *arrayOrMap = ACGPBGetObjectIvarWithFieldNoAutocreate(self, field);
    return (arrayOrMap.count > 0);
  } else {
    return ACGPBGetHasIvarField(self, field);
  }
}

void ACGPBClearMessageField(ACGPBMessage *self, ACGPBFieldDescriptor *field) {
  // If not set, nothing to do.
  if (!ACGPBGetHasIvarField(self, field)) {
    return;
  }

  ACGPBMessageFieldDescription *fieldDesc = field->description_;
  if (ACGPBFieldStoresObject(field)) {
    // Object types are handled slightly differently, they need to be released.
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    id *typePtr = (id *)&storage[fieldDesc->offset];
    [*typePtr release];
    *typePtr = nil;
  } else {
    // POD types just need to clear the has bit as the Get* method will
    // fetch the default when needed.
  }
  ACGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, NO);
}

void ACGPBClearOneof(ACGPBMessage *self, ACGPBOneofDescriptor *oneof) {
  #if defined(DEBUG) && DEBUG
    NSCAssert([[self descriptor] oneofWithName:oneof.name] == oneof,
              @"OneofDescriptor %@ doesn't appear to be for %@ messages.",
              oneof.name, [self class]);
  #endif
  ACGPBFieldDescriptor *firstField = oneof->fields_[0];
  ACGPBMaybeClearOneofPrivate(self, oneof, firstField->description_->hasIndex, 0);
}

BOOL ACGPBGetHasIvar(ACGPBMessage *self, int32_t idx, uint32_t fieldNumber) {
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
  if (idx < 0) {
    NSCAssert(fieldNumber != 0, @"Invalid field number.");
    BOOL hasIvar = (self->messageStorage_->_has_storage_[-idx] == fieldNumber);
    return hasIvar;
  } else {
    NSCAssert(idx != ACGPBNoHasBit, @"Invalid has bit.");
    uint32_t byteIndex = idx / 32;
    uint32_t bitMask = (1U << (idx % 32));
    BOOL hasIvar =
        (self->messageStorage_->_has_storage_[byteIndex] & bitMask) ? YES : NO;
    return hasIvar;
  }
}

uint32_t ACGPBGetHasOneof(ACGPBMessage *self, int32_t idx) {
  NSCAssert(idx < 0, @"%@: invalid index (%d) for oneof.",
            [self class], idx);
  uint32_t result = self->messageStorage_->_has_storage_[-idx];
  return result;
}

void ACGPBSetHasIvar(ACGPBMessage *self, int32_t idx, uint32_t fieldNumber,
                   BOOL value) {
  if (idx < 0) {
    NSCAssert(fieldNumber != 0, @"Invalid field number.");
    uint32_t *has_storage = self->messageStorage_->_has_storage_;
    has_storage[-idx] = (value ? fieldNumber : 0);
  } else {
    NSCAssert(idx != ACGPBNoHasBit, @"Invalid has bit.");
    uint32_t *has_storage = self->messageStorage_->_has_storage_;
    uint32_t byte = idx / 32;
    uint32_t bitMask = (1U << (idx % 32));
    if (value) {
      has_storage[byte] |= bitMask;
    } else {
      has_storage[byte] &= ~bitMask;
    }
  }
}

static void ACGPBMaybeClearOneofPrivate(ACGPBMessage *self,
                                      ACGPBOneofDescriptor *oneof,
                                      int32_t oneofHasIndex,
                                      uint32_t fieldNumberNotToClear) {
  uint32_t fieldNumberSet = ACGPBGetHasOneof(self, oneofHasIndex);
  if ((fieldNumberSet == fieldNumberNotToClear) || (fieldNumberSet == 0)) {
    // Do nothing/nothing set in the oneof.
    return;
  }

  // Like ACGPBClearMessageField(), free the memory if an objecttype is set,
  // pod types don't need to do anything.
  ACGPBFieldDescriptor *fieldSet = [oneof fieldWithNumber:fieldNumberSet];
  NSCAssert(fieldSet,
            @"%@: oneof set to something (%u) not in the oneof?",
            [self class], fieldNumberSet);
  if (fieldSet && ACGPBFieldStoresObject(fieldSet)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    id *typePtr = (id *)&storage[fieldSet->description_->offset];
    [*typePtr release];
    *typePtr = nil;
  }

  // Set to nothing stored in the oneof.
  // (field number doesn't matter since setting to nothing).
  ACGPBSetHasIvar(self, oneofHasIndex, 1, NO);
}

#pragma mark - IVar accessors

//%PDDM-DEFINE IVAR_POD_ACCESSORS_DEFN(NAME, TYPE)
//%TYPE ACGPBGetMessage##NAME##Field(ACGPBMessage *self,
//% TYPE$S            NAME$S       ACGPBFieldDescriptor *field) {
//%#if defined(DEBUG) && DEBUG
//%  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
//%            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
//%            field.name, [self class]);
//%  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
//%                                ACGPBDataType##NAME),
//%            @"Attempting to get value of TYPE from field %@ "
//%            @"of %@ which is of type %@.",
//%            [self class], field.name,
//%            TypeToString(ACGPBGetFieldDataType(field)));
//%#endif
//%  if (ACGPBGetHasIvarField(self, field)) {
//%    uint8_t *storage = (uint8_t *)self->messageStorage_;
//%    TYPE *typePtr = (TYPE *)&storage[field->description_->offset];
//%    return *typePtr;
//%  } else {
//%    return field.defaultValue.value##NAME;
//%  }
//%}
//%
//%// Only exists for public api, no core code should use this.
//%void ACGPBSetMessage##NAME##Field(ACGPBMessage *self,
//%                   NAME$S     ACGPBFieldDescriptor *field,
//%                   NAME$S     TYPE value) {
//%  if (self == nil || field == nil) return;
//%#if defined(DEBUG) && DEBUG
//%  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
//%            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
//%            field.name, [self class]);
//%  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
//%                                ACGPBDataType##NAME),
//%            @"Attempting to set field %@ of %@ which is of type %@ with "
//%            @"value of type TYPE.",
//%            [self class], field.name,
//%            TypeToString(ACGPBGetFieldDataType(field)));
//%#endif
//%  ACGPBSet##NAME##IvarWithFieldPrivate(self, field, value);
//%}
//%
//%void ACGPBSet##NAME##IvarWithFieldPrivate(ACGPBMessage *self,
//%            NAME$S                    ACGPBFieldDescriptor *field,
//%            NAME$S                    TYPE value) {
//%  ACGPBOneofDescriptor *oneof = field->containingOneof_;
//%  ACGPBMessageFieldDescription *fieldDesc = field->description_;
//%  if (oneof) {
//%    ACGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
//%  }
//%#if defined(DEBUG) && DEBUG
//%  NSCAssert(self->messageStorage_ != NULL,
//%            @"%@: All messages should have storage (from init)",
//%            [self class]);
//%#endif
//%#if defined(__clang_analyzer__)
//%  if (self->messageStorage_ == NULL) return;
//%#endif
//%  uint8_t *storage = (uint8_t *)self->messageStorage_;
//%  TYPE *typePtr = (TYPE *)&storage[fieldDesc->offset];
//%  *typePtr = value;
//%  // If the value is zero, then we only count the field as "set" if the field
//%  // shouldn't auto clear on zero.
//%  BOOL hasValue = ((value != (TYPE)0)
//%                   || ((fieldDesc->flags & ACGPBFieldClearHasIvarOnZero) == 0));
//%  ACGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
//%  ACGPBBecomeVisibleToAutocreator(self);
//%}
//%
//%PDDM-DEFINE IVAR_ALIAS_DEFN_OBJECT(NAME, TYPE)
//%// Only exists for public api, no core code should use this.
//%TYPE *ACGPBGetMessage##NAME##Field(ACGPBMessage *self,
//% TYPE$S             NAME$S       ACGPBFieldDescriptor *field) {
//%#if defined(DEBUG) && DEBUG
//%  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
//%                                ACGPBDataType##NAME),
//%            @"Attempting to get value of TYPE from field %@ "
//%            @"of %@ which is of type %@.",
//%            [self class], field.name,
//%            TypeToString(ACGPBGetFieldDataType(field)));
//%#endif
//%  return (TYPE *)ACGPBGetObjectIvarWithField(self, field);
//%}
//%
//%// Only exists for public api, no core code should use this.
//%void ACGPBSetMessage##NAME##Field(ACGPBMessage *self,
//%                   NAME$S     ACGPBFieldDescriptor *field,
//%                   NAME$S     TYPE *value) {
//%#if defined(DEBUG) && DEBUG
//%  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
//%                                ACGPBDataType##NAME),
//%            @"Attempting to set field %@ of %@ which is of type %@ with "
//%            @"value of type TYPE.",
//%            [self class], field.name,
//%            TypeToString(ACGPBGetFieldDataType(field)));
//%#endif
//%  ACGPBSetObjectIvarWithField(self, field, (id)value);
//%}
//%
//%PDDM-DEFINE IVAR_ALIAS_DEFN_COPY_OBJECT(NAME, TYPE)
//%// Only exists for public api, no core code should use this.
//%TYPE *ACGPBGetMessage##NAME##Field(ACGPBMessage *self,
//% TYPE$S             NAME$S       ACGPBFieldDescriptor *field) {
//%#if defined(DEBUG) && DEBUG
//%  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
//%                                ACGPBDataType##NAME),
//%            @"Attempting to get value of TYPE from field %@ "
//%            @"of %@ which is of type %@.",
//%            [self class], field.name,
//%            TypeToString(ACGPBGetFieldDataType(field)));
//%#endif
//%  return (TYPE *)ACGPBGetObjectIvarWithField(self, field);
//%}
//%
//%// Only exists for public api, no core code should use this.
//%void ACGPBSetMessage##NAME##Field(ACGPBMessage *self,
//%                   NAME$S     ACGPBFieldDescriptor *field,
//%                   NAME$S     TYPE *value) {
//%#if defined(DEBUG) && DEBUG
//%  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
//%                                ACGPBDataType##NAME),
//%            @"Attempting to set field %@ of %@ which is of type %@ with "
//%            @"value of type TYPE.",
//%            [self class], field.name,
//%            TypeToString(ACGPBGetFieldDataType(field)));
//%#endif
//%  ACGPBSetCopyObjectIvarWithField(self, field, (id)value);
//%}
//%

// Object types are handled slightly differently, they need to be released
// and retained.

void ACGPBClearAutocreatedMessageIvarWithField(ACGPBMessage *self,
                                             ACGPBFieldDescriptor *field) {
  if (ACGPBGetHasIvarField(self, field)) {
    return;
  }
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  id *typePtr = (id *)&storage[field->description_->offset];
  ACGPBMessage *oldValue = *typePtr;
  *typePtr = NULL;
  ACGPBClearMessageAutocreator(oldValue);
  [oldValue release];
}

// This exists only for bridging some aliased types, nothing else should use it.
static void ACGPBSetObjectIvarWithField(ACGPBMessage *self,
                                      ACGPBFieldDescriptor *field, id value) {
  if (self == nil || field == nil) return;
  ACGPBSetRetainedObjectIvarWithFieldPrivate(self, field, [value retain]);
}

static void ACGPBSetCopyObjectIvarWithField(ACGPBMessage *self,
                                          ACGPBFieldDescriptor *field, id value);

// ACGPBSetCopyObjectIvarWithField is blocked from the analyzer because it flags
// a leak for the -copy even though ACGPBSetRetainedObjectIvarWithFieldPrivate
// is marked as consuming the value. Note: For some reason this doesn't happen
// with the -retain in ACGPBSetObjectIvarWithField.
#if !defined(__clang_analyzer__)
// This exists only for bridging some aliased types, nothing else should use it.
static void ACGPBSetCopyObjectIvarWithField(ACGPBMessage *self,
                                          ACGPBFieldDescriptor *field, id value) {
  if (self == nil || field == nil) return;
  ACGPBSetRetainedObjectIvarWithFieldPrivate(self, field, [value copy]);
}
#endif  // !defined(__clang_analyzer__)

void ACGPBSetObjectIvarWithFieldPrivate(ACGPBMessage *self,
                                      ACGPBFieldDescriptor *field, id value) {
  ACGPBSetRetainedObjectIvarWithFieldPrivate(self, field, [value retain]);
}

void ACGPBSetRetainedObjectIvarWithFieldPrivate(ACGPBMessage *self,
                                              ACGPBFieldDescriptor *field,
                                              id value) {
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  ACGPBDataType fieldType = ACGPBGetFieldDataType(field);
  BOOL isMapOrArray = ACGPBFieldIsMapOrArray(field);
  BOOL fieldIsMessage = ACGPBDataTypeIsMessage(fieldType);
#if defined(DEBUG) && DEBUG
  if (value == nil && !isMapOrArray && !fieldIsMessage &&
      field.hasDefaultValue) {
    // Setting a message to nil is an obvious way to "clear" the value
    // as there is no way to set a non-empty default value for messages.
    //
    // For Strings and Bytes that have default values set it is not clear what
    // should be done when their value is set to nil. Is the intention just to
    // clear the set value and reset to default, or is the intention to set the
    // value to the empty string/data? Arguments can be made for both cases.
    // 'nil' has been abused as a replacement for an empty string/data in ObjC.
    // We decided to be consistent with all "object" types and clear the has
    // field, and fall back on the default value. The warning below will only
    // appear in debug, but the could should be changed so the intention is
    // clear.
    NSString *hasSel = NSStringFromSelector(field->hasOrCountSel_);
    NSString *propName = field.name;
    NSString *className = self.descriptor.name;
    NSLog(@"warning: '%@.%@ = nil;' is not clearly defined for fields with "
          @"default values. Please use '%@.%@ = %@' if you want to set it to "
          @"empty, or call '%@.%@ = NO' to reset it to it's default value of "
          @"'%@'. Defaulting to resetting default value.",
          className, propName, className, propName,
          (fieldType == ACGPBDataTypeString) ? @"@\"\"" : @"ACGPBEmptyNSData()",
          className, hasSel, field.defaultValue.valueString);
    // Note: valueString, depending on the type, it could easily be
    // valueData/valueMessage.
  }
#endif  // DEBUG
  ACGPBMessageFieldDescription *fieldDesc = field->description_;
  if (!isMapOrArray) {
    // Non repeated/map can be in an oneof, clear any existing value from the
    // oneof.
    ACGPBOneofDescriptor *oneof = field->containingOneof_;
    if (oneof) {
      ACGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
    }
    // Clear "has" if they are being set to nil.
    BOOL setHasValue = (value != nil);
    // If the field should clear on a "zero" value, then check if the string/data
    // was zero length, and clear instead.
    if (((fieldDesc->flags & ACGPBFieldClearHasIvarOnZero) != 0) &&
        ([value length] == 0)) {
      setHasValue = NO;
      // The value passed in was retained, it must be released since we
      // aren't saving anything in the field.
      [value release];
      value = nil;
    }
    ACGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, setHasValue);
  }
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  id *typePtr = (id *)&storage[fieldDesc->offset];

  id oldValue = *typePtr;

  *typePtr = value;

  if (oldValue) {
    if (isMapOrArray) {
      if (field.fieldType == ACGPBFieldTypeRepeated) {
        // If the old array was autocreated by us, then clear it.
        if (ACGPBDataTypeIsObject(fieldType)) {
          if ([oldValue isKindOfClass:[ACGPBAutocreatedArray class]]) {
            ACGPBAutocreatedArray *autoArray = oldValue;
            if (autoArray->_autocreator == self) {
              autoArray->_autocreator = nil;
            }
          }
        } else {
          // Type doesn't matter, it is a ACGPB*Array.
          ACGPBInt32Array *gpbArray = oldValue;
          if (gpbArray->_autocreator == self) {
            gpbArray->_autocreator = nil;
          }
        }
      } else { // ACGPBFieldTypeMap
        // If the old map was autocreated by us, then clear it.
        if ((field.mapKeyDataType == ACGPBDataTypeString) &&
            ACGPBDataTypeIsObject(fieldType)) {
          if ([oldValue isKindOfClass:[ACGPBAutocreatedDictionary class]]) {
            ACGPBAutocreatedDictionary *autoDict = oldValue;
            if (autoDict->_autocreator == self) {
              autoDict->_autocreator = nil;
            }
          }
        } else {
          // Type doesn't matter, it is a ACGPB*Dictionary.
          ACGPBInt32Int32Dictionary *gpbDict = oldValue;
          if (gpbDict->_autocreator == self) {
            gpbDict->_autocreator = nil;
          }
        }
      }
    } else if (fieldIsMessage) {
      // If the old message value was autocreated by us, then clear it.
      ACGPBMessage *oldMessageValue = oldValue;
      if (ACGPBWasMessageAutocreatedBy(oldMessageValue, self)) {
        ACGPBClearMessageAutocreator(oldMessageValue);
      }
    }
    [oldValue release];
  }

  ACGPBBecomeVisibleToAutocreator(self);
}

id ACGPBGetObjectIvarWithFieldNoAutocreate(ACGPBMessage *self,
                                         ACGPBFieldDescriptor *field) {
  if (self->messageStorage_ == nil) {
    return nil;
  }
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  id *typePtr = (id *)&storage[field->description_->offset];
  return *typePtr;
}

// Only exists for public api, no core code should use this.
int32_t ACGPBGetMessageEnumField(ACGPBMessage *self, ACGPBFieldDescriptor *field) {
  #if defined(DEBUG) && DEBUG
    NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
              @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
              field.name, [self class]);
    NSCAssert(ACGPBGetFieldDataType(field) == ACGPBDataTypeEnum,
              @"Attempting to get value of type Enum from field %@ "
              @"of %@ which is of type %@.",
              [self class], field.name,
              TypeToString(ACGPBGetFieldDataType(field)));
  #endif

  int32_t result = ACGPBGetMessageInt32Field(self, field);
  // If this is presevering unknown enums, make sure the value is valid before
  // returning it.

  ACGPBFileSyntax syntax = [self descriptor].file.syntax;
  if (ACGPBHasPreservingUnknownEnumSemantics(syntax) &&
      ![field isValidEnumValue:result]) {
    result = kACGPBUnrecognizedEnumeratorValue;
  }
  return result;
}

// Only exists for public api, no core code should use this.
void ACGPBSetMessageEnumField(ACGPBMessage *self, ACGPBFieldDescriptor *field,
                            int32_t value) {
  #if defined(DEBUG) && DEBUG
    NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
              @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
              field.name, [self class]);
    NSCAssert(ACGPBGetFieldDataType(field) == ACGPBDataTypeEnum,
              @"Attempting to set field %@ of %@ which is of type %@ with "
              @"value of type Enum.",
              [self class], field.name,
              TypeToString(ACGPBGetFieldDataType(field)));
  #endif
  ACGPBSetEnumIvarWithFieldPrivate(self, field, value);
}

void ACGPBSetEnumIvarWithFieldPrivate(ACGPBMessage *self,
                                    ACGPBFieldDescriptor *field, int32_t value) {
  // Don't allow in unknown values.  Proto3 can use the Raw method.
  if (![field isValidEnumValue:value]) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@: Attempt to set an unknown enum value (%d)",
                       [self class], field.name, value];
  }
  ACGPBSetInt32IvarWithFieldPrivate(self, field, value);
}

// Only exists for public api, no core code should use this.
int32_t ACGPBGetMessageRawEnumField(ACGPBMessage *self,
                                  ACGPBFieldDescriptor *field) {
  int32_t result = ACGPBGetMessageInt32Field(self, field);
  return result;
}

// Only exists for public api, no core code should use this.
void ACGPBSetMessageRawEnumField(ACGPBMessage *self, ACGPBFieldDescriptor *field,
                               int32_t value) {
  ACGPBSetInt32IvarWithFieldPrivate(self, field, value);
}

BOOL ACGPBGetMessageBoolField(ACGPBMessage *self,
                            ACGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field), ACGPBDataTypeBool),
            @"Attempting to get value of type bool from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  if (ACGPBGetHasIvarField(self, field)) {
    // Bools are stored in the has bits to avoid needing explicit space in the
    // storage structure.
    // (the field number passed to the HasIvar helper doesn't really matter
    // since the offset is never negative)
    ACGPBMessageFieldDescription *fieldDesc = field->description_;
    return ACGPBGetHasIvar(self, (int32_t)(fieldDesc->offset), fieldDesc->number);
  } else {
    return field.defaultValue.valueBool;
  }
}

// Only exists for public api, no core code should use this.
void ACGPBSetMessageBoolField(ACGPBMessage *self,
                            ACGPBFieldDescriptor *field,
                            BOOL value) {
  if (self == nil || field == nil) return;
  #if defined(DEBUG) && DEBUG
    NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
              @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
              field.name, [self class]);
    NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field), ACGPBDataTypeBool),
              @"Attempting to set field %@ of %@ which is of type %@ with "
              @"value of type bool.",
              [self class], field.name,
              TypeToString(ACGPBGetFieldDataType(field)));
  #endif
  ACGPBSetBoolIvarWithFieldPrivate(self, field, value);
}

void ACGPBSetBoolIvarWithFieldPrivate(ACGPBMessage *self,
                                    ACGPBFieldDescriptor *field,
                                    BOOL value) {
  ACGPBMessageFieldDescription *fieldDesc = field->description_;
  ACGPBOneofDescriptor *oneof = field->containingOneof_;
  if (oneof) {
    ACGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }

  // Bools are stored in the has bits to avoid needing explicit space in the
  // storage structure.
  // (the field number passed to the HasIvar helper doesn't really matter since
  // the offset is never negative)
  ACGPBSetHasIvar(self, (int32_t)(fieldDesc->offset), fieldDesc->number, value);

  // If the value is zero, then we only count the field as "set" if the field
  // shouldn't auto clear on zero.
  BOOL hasValue = ((value != (BOOL)0)
                   || ((fieldDesc->flags & ACGPBFieldClearHasIvarOnZero) == 0));
  ACGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
  ACGPBBecomeVisibleToAutocreator(self);
}

//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(Int32, int32_t)
// This block of code is generated, do not edit it directly.
// clang-format off

int32_t ACGPBGetMessageInt32Field(ACGPBMessage *self,
                                ACGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeInt32),
            @"Attempting to get value of int32_t from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  if (ACGPBGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    int32_t *typePtr = (int32_t *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueInt32;
  }
}

// Only exists for public api, no core code should use this.
void ACGPBSetMessageInt32Field(ACGPBMessage *self,
                             ACGPBFieldDescriptor *field,
                             int32_t value) {
  if (self == nil || field == nil) return;
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeInt32),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type int32_t.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  ACGPBSetInt32IvarWithFieldPrivate(self, field, value);
}

void ACGPBSetInt32IvarWithFieldPrivate(ACGPBMessage *self,
                                     ACGPBFieldDescriptor *field,
                                     int32_t value) {
  ACGPBOneofDescriptor *oneof = field->containingOneof_;
  ACGPBMessageFieldDescription *fieldDesc = field->description_;
  if (oneof) {
    ACGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
#if defined(DEBUG) && DEBUG
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#endif
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  int32_t *typePtr = (int32_t *)&storage[fieldDesc->offset];
  *typePtr = value;
  // If the value is zero, then we only count the field as "set" if the field
  // shouldn't auto clear on zero.
  BOOL hasValue = ((value != (int32_t)0)
                   || ((fieldDesc->flags & ACGPBFieldClearHasIvarOnZero) == 0));
  ACGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
  ACGPBBecomeVisibleToAutocreator(self);
}

// clang-format on
//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(UInt32, uint32_t)
// This block of code is generated, do not edit it directly.
// clang-format off

uint32_t ACGPBGetMessageUInt32Field(ACGPBMessage *self,
                                  ACGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeUInt32),
            @"Attempting to get value of uint32_t from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  if (ACGPBGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    uint32_t *typePtr = (uint32_t *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueUInt32;
  }
}

// Only exists for public api, no core code should use this.
void ACGPBSetMessageUInt32Field(ACGPBMessage *self,
                              ACGPBFieldDescriptor *field,
                              uint32_t value) {
  if (self == nil || field == nil) return;
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeUInt32),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type uint32_t.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  ACGPBSetUInt32IvarWithFieldPrivate(self, field, value);
}

void ACGPBSetUInt32IvarWithFieldPrivate(ACGPBMessage *self,
                                      ACGPBFieldDescriptor *field,
                                      uint32_t value) {
  ACGPBOneofDescriptor *oneof = field->containingOneof_;
  ACGPBMessageFieldDescription *fieldDesc = field->description_;
  if (oneof) {
    ACGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
#if defined(DEBUG) && DEBUG
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#endif
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  uint32_t *typePtr = (uint32_t *)&storage[fieldDesc->offset];
  *typePtr = value;
  // If the value is zero, then we only count the field as "set" if the field
  // shouldn't auto clear on zero.
  BOOL hasValue = ((value != (uint32_t)0)
                   || ((fieldDesc->flags & ACGPBFieldClearHasIvarOnZero) == 0));
  ACGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
  ACGPBBecomeVisibleToAutocreator(self);
}

// clang-format on
//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(Int64, int64_t)
// This block of code is generated, do not edit it directly.
// clang-format off

int64_t ACGPBGetMessageInt64Field(ACGPBMessage *self,
                                ACGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeInt64),
            @"Attempting to get value of int64_t from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  if (ACGPBGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    int64_t *typePtr = (int64_t *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueInt64;
  }
}

// Only exists for public api, no core code should use this.
void ACGPBSetMessageInt64Field(ACGPBMessage *self,
                             ACGPBFieldDescriptor *field,
                             int64_t value) {
  if (self == nil || field == nil) return;
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeInt64),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type int64_t.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  ACGPBSetInt64IvarWithFieldPrivate(self, field, value);
}

void ACGPBSetInt64IvarWithFieldPrivate(ACGPBMessage *self,
                                     ACGPBFieldDescriptor *field,
                                     int64_t value) {
  ACGPBOneofDescriptor *oneof = field->containingOneof_;
  ACGPBMessageFieldDescription *fieldDesc = field->description_;
  if (oneof) {
    ACGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
#if defined(DEBUG) && DEBUG
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#endif
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  int64_t *typePtr = (int64_t *)&storage[fieldDesc->offset];
  *typePtr = value;
  // If the value is zero, then we only count the field as "set" if the field
  // shouldn't auto clear on zero.
  BOOL hasValue = ((value != (int64_t)0)
                   || ((fieldDesc->flags & ACGPBFieldClearHasIvarOnZero) == 0));
  ACGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
  ACGPBBecomeVisibleToAutocreator(self);
}

// clang-format on
//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(UInt64, uint64_t)
// This block of code is generated, do not edit it directly.
// clang-format off

uint64_t ACGPBGetMessageUInt64Field(ACGPBMessage *self,
                                  ACGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeUInt64),
            @"Attempting to get value of uint64_t from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  if (ACGPBGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    uint64_t *typePtr = (uint64_t *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueUInt64;
  }
}

// Only exists for public api, no core code should use this.
void ACGPBSetMessageUInt64Field(ACGPBMessage *self,
                              ACGPBFieldDescriptor *field,
                              uint64_t value) {
  if (self == nil || field == nil) return;
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeUInt64),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type uint64_t.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  ACGPBSetUInt64IvarWithFieldPrivate(self, field, value);
}

void ACGPBSetUInt64IvarWithFieldPrivate(ACGPBMessage *self,
                                      ACGPBFieldDescriptor *field,
                                      uint64_t value) {
  ACGPBOneofDescriptor *oneof = field->containingOneof_;
  ACGPBMessageFieldDescription *fieldDesc = field->description_;
  if (oneof) {
    ACGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
#if defined(DEBUG) && DEBUG
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#endif
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  uint64_t *typePtr = (uint64_t *)&storage[fieldDesc->offset];
  *typePtr = value;
  // If the value is zero, then we only count the field as "set" if the field
  // shouldn't auto clear on zero.
  BOOL hasValue = ((value != (uint64_t)0)
                   || ((fieldDesc->flags & ACGPBFieldClearHasIvarOnZero) == 0));
  ACGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
  ACGPBBecomeVisibleToAutocreator(self);
}

// clang-format on
//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(Float, float)
// This block of code is generated, do not edit it directly.
// clang-format off

float ACGPBGetMessageFloatField(ACGPBMessage *self,
                              ACGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeFloat),
            @"Attempting to get value of float from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  if (ACGPBGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    float *typePtr = (float *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueFloat;
  }
}

// Only exists for public api, no core code should use this.
void ACGPBSetMessageFloatField(ACGPBMessage *self,
                             ACGPBFieldDescriptor *field,
                             float value) {
  if (self == nil || field == nil) return;
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeFloat),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type float.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  ACGPBSetFloatIvarWithFieldPrivate(self, field, value);
}

void ACGPBSetFloatIvarWithFieldPrivate(ACGPBMessage *self,
                                     ACGPBFieldDescriptor *field,
                                     float value) {
  ACGPBOneofDescriptor *oneof = field->containingOneof_;
  ACGPBMessageFieldDescription *fieldDesc = field->description_;
  if (oneof) {
    ACGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
#if defined(DEBUG) && DEBUG
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#endif
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  float *typePtr = (float *)&storage[fieldDesc->offset];
  *typePtr = value;
  // If the value is zero, then we only count the field as "set" if the field
  // shouldn't auto clear on zero.
  BOOL hasValue = ((value != (float)0)
                   || ((fieldDesc->flags & ACGPBFieldClearHasIvarOnZero) == 0));
  ACGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
  ACGPBBecomeVisibleToAutocreator(self);
}

// clang-format on
//%PDDM-EXPAND IVAR_POD_ACCESSORS_DEFN(Double, double)
// This block of code is generated, do not edit it directly.
// clang-format off

double ACGPBGetMessageDoubleField(ACGPBMessage *self,
                                ACGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeDouble),
            @"Attempting to get value of double from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  if (ACGPBGetHasIvarField(self, field)) {
    uint8_t *storage = (uint8_t *)self->messageStorage_;
    double *typePtr = (double *)&storage[field->description_->offset];
    return *typePtr;
  } else {
    return field.defaultValue.valueDouble;
  }
}

// Only exists for public api, no core code should use this.
void ACGPBSetMessageDoubleField(ACGPBMessage *self,
                              ACGPBFieldDescriptor *field,
                              double value) {
  if (self == nil || field == nil) return;
#if defined(DEBUG) && DEBUG
  NSCAssert([[self descriptor] fieldWithNumber:field.number] == field,
            @"FieldDescriptor %@ doesn't appear to be for %@ messages.",
            field.name, [self class]);
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeDouble),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type double.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  ACGPBSetDoubleIvarWithFieldPrivate(self, field, value);
}

void ACGPBSetDoubleIvarWithFieldPrivate(ACGPBMessage *self,
                                      ACGPBFieldDescriptor *field,
                                      double value) {
  ACGPBOneofDescriptor *oneof = field->containingOneof_;
  ACGPBMessageFieldDescription *fieldDesc = field->description_;
  if (oneof) {
    ACGPBMaybeClearOneofPrivate(self, oneof, fieldDesc->hasIndex, fieldDesc->number);
  }
#if defined(DEBUG) && DEBUG
  NSCAssert(self->messageStorage_ != NULL,
            @"%@: All messages should have storage (from init)",
            [self class]);
#endif
#if defined(__clang_analyzer__)
  if (self->messageStorage_ == NULL) return;
#endif
  uint8_t *storage = (uint8_t *)self->messageStorage_;
  double *typePtr = (double *)&storage[fieldDesc->offset];
  *typePtr = value;
  // If the value is zero, then we only count the field as "set" if the field
  // shouldn't auto clear on zero.
  BOOL hasValue = ((value != (double)0)
                   || ((fieldDesc->flags & ACGPBFieldClearHasIvarOnZero) == 0));
  ACGPBSetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number, hasValue);
  ACGPBBecomeVisibleToAutocreator(self);
}

// clang-format on
//%PDDM-EXPAND-END (6 expansions)

// Aliases are function calls that are virtually the same.

//%PDDM-EXPAND IVAR_ALIAS_DEFN_COPY_OBJECT(String, NSString)
// This block of code is generated, do not edit it directly.
// clang-format off

// Only exists for public api, no core code should use this.
NSString *ACGPBGetMessageStringField(ACGPBMessage *self,
                                   ACGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeString),
            @"Attempting to get value of NSString from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  return (NSString *)ACGPBGetObjectIvarWithField(self, field);
}

// Only exists for public api, no core code should use this.
void ACGPBSetMessageStringField(ACGPBMessage *self,
                              ACGPBFieldDescriptor *field,
                              NSString *value) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeString),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type NSString.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  ACGPBSetCopyObjectIvarWithField(self, field, (id)value);
}

// clang-format on
//%PDDM-EXPAND IVAR_ALIAS_DEFN_COPY_OBJECT(Bytes, NSData)
// This block of code is generated, do not edit it directly.
// clang-format off

// Only exists for public api, no core code should use this.
NSData *ACGPBGetMessageBytesField(ACGPBMessage *self,
                                ACGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeBytes),
            @"Attempting to get value of NSData from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  return (NSData *)ACGPBGetObjectIvarWithField(self, field);
}

// Only exists for public api, no core code should use this.
void ACGPBSetMessageBytesField(ACGPBMessage *self,
                             ACGPBFieldDescriptor *field,
                             NSData *value) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeBytes),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type NSData.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  ACGPBSetCopyObjectIvarWithField(self, field, (id)value);
}

// clang-format on
//%PDDM-EXPAND IVAR_ALIAS_DEFN_OBJECT(Message, ACGPBMessage)
// This block of code is generated, do not edit it directly.
// clang-format off

// Only exists for public api, no core code should use this.
ACGPBMessage *ACGPBGetMessageMessageField(ACGPBMessage *self,
                                      ACGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeMessage),
            @"Attempting to get value of ACGPBMessage from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  return (ACGPBMessage *)ACGPBGetObjectIvarWithField(self, field);
}

// Only exists for public api, no core code should use this.
void ACGPBSetMessageMessageField(ACGPBMessage *self,
                               ACGPBFieldDescriptor *field,
                               ACGPBMessage *value) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeMessage),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type ACGPBMessage.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  ACGPBSetObjectIvarWithField(self, field, (id)value);
}

// clang-format on
//%PDDM-EXPAND IVAR_ALIAS_DEFN_OBJECT(Group, ACGPBMessage)
// This block of code is generated, do not edit it directly.
// clang-format off

// Only exists for public api, no core code should use this.
ACGPBMessage *ACGPBGetMessageGroupField(ACGPBMessage *self,
                                    ACGPBFieldDescriptor *field) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeGroup),
            @"Attempting to get value of ACGPBMessage from field %@ "
            @"of %@ which is of type %@.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  return (ACGPBMessage *)ACGPBGetObjectIvarWithField(self, field);
}

// Only exists for public api, no core code should use this.
void ACGPBSetMessageGroupField(ACGPBMessage *self,
                             ACGPBFieldDescriptor *field,
                             ACGPBMessage *value) {
#if defined(DEBUG) && DEBUG
  NSCAssert(DataTypesEquivalent(ACGPBGetFieldDataType(field),
                                ACGPBDataTypeGroup),
            @"Attempting to set field %@ of %@ which is of type %@ with "
            @"value of type ACGPBMessage.",
            [self class], field.name,
            TypeToString(ACGPBGetFieldDataType(field)));
#endif
  ACGPBSetObjectIvarWithField(self, field, (id)value);
}

// clang-format on
//%PDDM-EXPAND-END (4 expansions)

// ACGPBGetMessageRepeatedField is defined in ACGPBMessage.m

// Only exists for public api, no core code should use this.
void ACGPBSetMessageRepeatedField(ACGPBMessage *self, ACGPBFieldDescriptor *field, id array) {
#if defined(DEBUG) && DEBUG
  if (field.fieldType != ACGPBFieldTypeRepeated) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@ is not a repeated field.",
                       [self class], field.name];
  }
  Class expectedClass = Nil;
  switch (ACGPBGetFieldDataType(field)) {
    case ACGPBDataTypeBool:
      expectedClass = [ACGPBBoolArray class];
      break;
    case ACGPBDataTypeSFixed32:
    case ACGPBDataTypeInt32:
    case ACGPBDataTypeSInt32:
      expectedClass = [ACGPBInt32Array class];
      break;
    case ACGPBDataTypeFixed32:
    case ACGPBDataTypeUInt32:
      expectedClass = [ACGPBUInt32Array class];
      break;
    case ACGPBDataTypeSFixed64:
    case ACGPBDataTypeInt64:
    case ACGPBDataTypeSInt64:
      expectedClass = [ACGPBInt64Array class];
      break;
    case ACGPBDataTypeFixed64:
    case ACGPBDataTypeUInt64:
      expectedClass = [ACGPBUInt64Array class];
      break;
    case ACGPBDataTypeFloat:
      expectedClass = [ACGPBFloatArray class];
      break;
    case ACGPBDataTypeDouble:
      expectedClass = [ACGPBDoubleArray class];
      break;
    case ACGPBDataTypeBytes:
    case ACGPBDataTypeString:
    case ACGPBDataTypeMessage:
    case ACGPBDataTypeGroup:
      expectedClass = [NSMutableArray class];
      break;
    case ACGPBDataTypeEnum:
      expectedClass = [ACGPBEnumArray class];
      break;
  }
  if (array && ![array isKindOfClass:expectedClass]) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@: Expected %@ object, got %@.",
                       [self class], field.name, expectedClass, [array class]];
  }
#endif
  ACGPBSetObjectIvarWithField(self, field, array);
}

static ACGPBDataType BaseDataType(ACGPBDataType type) {
  switch (type) {
    case ACGPBDataTypeSFixed32:
    case ACGPBDataTypeInt32:
    case ACGPBDataTypeSInt32:
    case ACGPBDataTypeEnum:
      return ACGPBDataTypeInt32;
    case ACGPBDataTypeFixed32:
    case ACGPBDataTypeUInt32:
      return ACGPBDataTypeUInt32;
    case ACGPBDataTypeSFixed64:
    case ACGPBDataTypeInt64:
    case ACGPBDataTypeSInt64:
      return ACGPBDataTypeInt64;
    case ACGPBDataTypeFixed64:
    case ACGPBDataTypeUInt64:
      return ACGPBDataTypeUInt64;
    case ACGPBDataTypeMessage:
    case ACGPBDataTypeGroup:
      return ACGPBDataTypeMessage;
    case ACGPBDataTypeBool:
    case ACGPBDataTypeFloat:
    case ACGPBDataTypeDouble:
    case ACGPBDataTypeBytes:
    case ACGPBDataTypeString:
      return type;
   }
}

static BOOL DataTypesEquivalent(ACGPBDataType type1, ACGPBDataType type2) {
  return BaseDataType(type1) == BaseDataType(type2);
}

static NSString *TypeToString(ACGPBDataType dataType) {
  switch (dataType) {
    case ACGPBDataTypeBool:
      return @"Bool";
    case ACGPBDataTypeSFixed32:
    case ACGPBDataTypeInt32:
    case ACGPBDataTypeSInt32:
      return @"Int32";
    case ACGPBDataTypeFixed32:
    case ACGPBDataTypeUInt32:
      return @"UInt32";
    case ACGPBDataTypeSFixed64:
    case ACGPBDataTypeInt64:
    case ACGPBDataTypeSInt64:
      return @"Int64";
    case ACGPBDataTypeFixed64:
    case ACGPBDataTypeUInt64:
      return @"UInt64";
    case ACGPBDataTypeFloat:
      return @"Float";
    case ACGPBDataTypeDouble:
      return @"Double";
    case ACGPBDataTypeBytes:
    case ACGPBDataTypeString:
    case ACGPBDataTypeMessage:
    case ACGPBDataTypeGroup:
      return @"Object";
    case ACGPBDataTypeEnum:
      return @"Enum";
  }
}

// ACGPBGetMessageMapField is defined in ACGPBMessage.m

// Only exists for public api, no core code should use this.
void ACGPBSetMessageMapField(ACGPBMessage *self, ACGPBFieldDescriptor *field,
                           id dictionary) {
#if defined(DEBUG) && DEBUG
  if (field.fieldType != ACGPBFieldTypeMap) {
    [NSException raise:NSInvalidArgumentException
                format:@"%@.%@ is not a map<> field.",
                       [self class], field.name];
  }
  if (dictionary) {
    ACGPBDataType keyDataType = field.mapKeyDataType;
    ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
    NSString *keyStr = TypeToString(keyDataType);
    NSString *valueStr = TypeToString(valueDataType);
    if (keyDataType == ACGPBDataTypeString) {
      keyStr = @"String";
    }
    Class expectedClass = Nil;
    if ((keyDataType == ACGPBDataTypeString) &&
        ACGPBDataTypeIsObject(valueDataType)) {
      expectedClass = [NSMutableDictionary class];
    } else {
      NSString *className =
          [NSString stringWithFormat:@"ACGPB%@%@Dictionary", keyStr, valueStr];
      expectedClass = NSClassFromString(className);
      NSCAssert(expectedClass, @"Missing a class (%@)?", expectedClass);
    }
    if (![dictionary isKindOfClass:expectedClass]) {
      [NSException raise:NSInvalidArgumentException
                  format:@"%@.%@: Expected %@ object, got %@.",
                         [self class], field.name, expectedClass,
                         [dictionary class]];
    }
  }
#endif
  ACGPBSetObjectIvarWithField(self, field, dictionary);
}

#pragma mark - Misc Dynamic Runtime Utils

const char *ACGPBMessageEncodingForSelector(SEL selector, BOOL instanceSel) {
  Protocol *protocol =
      objc_getProtocol(ACGPBStringifySymbol(ACGPBMessageSignatureProtocol));
  NSCAssert(protocol, @"Missing ACGPBMessageSignatureProtocol");
  struct objc_method_description description =
      protocol_getMethodDescription(protocol, selector, NO, instanceSel);
  NSCAssert(description.name != Nil && description.types != nil,
            @"Missing method for selector %@", NSStringFromSelector(selector));
  return description.types;
}

#pragma mark - Text Format Support

static void AppendStringEscaped(NSString *toPrint, NSMutableString *destStr) {
  [destStr appendString:@"\""];
  NSUInteger len = [toPrint length];
  for (NSUInteger i = 0; i < len; ++i) {
    unichar aChar = [toPrint characterAtIndex:i];
    switch (aChar) {
      case '\n': [destStr appendString:@"\\n"];  break;
      case '\r': [destStr appendString:@"\\r"];  break;
      case '\t': [destStr appendString:@"\\t"];  break;
      case '\"': [destStr appendString:@"\\\""]; break;
      case '\'': [destStr appendString:@"\\\'"]; break;
      case '\\': [destStr appendString:@"\\\\"]; break;
      default:
        // This differs slightly from the C++ code in that the C++ doesn't
        // generate UTF8; it looks at the string in UTF8, but escapes every
        // byte > 0x7E.
        if (aChar < 0x20) {
          [destStr appendFormat:@"\\%d%d%d",
                                (aChar / 64), ((aChar % 64) / 8), (aChar % 8)];
        } else {
          [destStr appendFormat:@"%C", aChar];
        }
        break;
    }
  }
  [destStr appendString:@"\""];
}

static void AppendBufferAsString(NSData *buffer, NSMutableString *destStr) {
  const char *src = (const char *)[buffer bytes];
  size_t srcLen = [buffer length];
  [destStr appendString:@"\""];
  for (const char *srcEnd = src + srcLen; src < srcEnd; src++) {
    switch (*src) {
      case '\n': [destStr appendString:@"\\n"];  break;
      case '\r': [destStr appendString:@"\\r"];  break;
      case '\t': [destStr appendString:@"\\t"];  break;
      case '\"': [destStr appendString:@"\\\""]; break;
      case '\'': [destStr appendString:@"\\\'"]; break;
      case '\\': [destStr appendString:@"\\\\"]; break;
      default:
        if (isprint(*src)) {
          [destStr appendFormat:@"%c", *src];
        } else {
          // NOTE: doing hex means you have to worry about the letter after
          // the hex being another hex char and forcing that to be escaped, so
          // use octal to keep it simple.
          [destStr appendFormat:@"\\%03o", (uint8_t)(*src)];
        }
        break;
    }
  }
  [destStr appendString:@"\""];
}

static void AppendTextFormatForMapMessageField(
    id map, ACGPBFieldDescriptor *field, NSMutableString *toStr,
    NSString *lineIndent, NSString *fieldName, NSString *lineEnding) {
  ACGPBDataType keyDataType = field.mapKeyDataType;
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  BOOL isMessageValue = ACGPBDataTypeIsMessage(valueDataType);

  NSString *msgStartFirst =
      [NSString stringWithFormat:@"%@%@ {%@\n", lineIndent, fieldName, lineEnding];
  NSString *msgStart =
      [NSString stringWithFormat:@"%@%@ {\n", lineIndent, fieldName];
  NSString *msgEnd = [NSString stringWithFormat:@"%@}\n", lineIndent];

  NSString *keyLine = [NSString stringWithFormat:@"%@  key: ", lineIndent];
  NSString *valueLine = [NSString stringWithFormat:@"%@  value%s ", lineIndent,
                                                   (isMessageValue ? "" : ":")];

  __block BOOL isFirst = YES;

  if ((keyDataType == ACGPBDataTypeString) &&
      ACGPBDataTypeIsObject(valueDataType)) {
    // map is an NSDictionary.
    NSDictionary *dict = map;
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
      #pragma unused(stop)
      [toStr appendString:(isFirst ? msgStartFirst : msgStart)];
      isFirst = NO;

      [toStr appendString:keyLine];
      AppendStringEscaped(key, toStr);
      [toStr appendString:@"\n"];

      [toStr appendString:valueLine];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
      switch (valueDataType) {
        case ACGPBDataTypeString:
          AppendStringEscaped(value, toStr);
          break;

        case ACGPBDataTypeBytes:
          AppendBufferAsString(value, toStr);
          break;

        case ACGPBDataTypeMessage:
          [toStr appendString:@"{\n"];
          NSString *subIndent = [lineIndent stringByAppendingString:@"    "];
          AppendTextFormatForMessage(value, toStr, subIndent);
          [toStr appendFormat:@"%@  }", lineIndent];
          break;

        default:
          NSCAssert(NO, @"Can't happen");
          break;
      }
#pragma clang diagnostic pop
      [toStr appendString:@"\n"];

      [toStr appendString:msgEnd];
    }];
  } else {
    // map is one of the ACGPB*Dictionary classes, type doesn't matter.
    ACGPBInt32Int32Dictionary *dict = map;
    [dict enumerateForTextFormat:^(id keyObj, id valueObj) {
      [toStr appendString:(isFirst ? msgStartFirst : msgStart)];
      isFirst = NO;

      // Key always is a NSString.
      if (keyDataType == ACGPBDataTypeString) {
        [toStr appendString:keyLine];
        AppendStringEscaped(keyObj, toStr);
        [toStr appendString:@"\n"];
      } else {
        [toStr appendFormat:@"%@%@\n", keyLine, keyObj];
      }

      [toStr appendString:valueLine];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
      switch (valueDataType) {
        case ACGPBDataTypeString:
          AppendStringEscaped(valueObj, toStr);
          break;

        case ACGPBDataTypeBytes:
          AppendBufferAsString(valueObj, toStr);
          break;

        case ACGPBDataTypeMessage:
          [toStr appendString:@"{\n"];
          NSString *subIndent = [lineIndent stringByAppendingString:@"    "];
          AppendTextFormatForMessage(valueObj, toStr, subIndent);
          [toStr appendFormat:@"%@  }", lineIndent];
          break;

        case ACGPBDataTypeEnum: {
          int32_t enumValue = [valueObj intValue];
          NSString *valueStr = nil;
          ACGPBEnumDescriptor *descriptor = field.enumDescriptor;
          if (descriptor) {
            valueStr = [descriptor textFormatNameForValue:enumValue];
          }
          if (valueStr) {
            [toStr appendString:valueStr];
          } else {
            [toStr appendFormat:@"%d", enumValue];
          }
          break;
        }

        default:
          NSCAssert(valueDataType != ACGPBDataTypeGroup, @"Can't happen");
          // Everything else is a NSString.
          [toStr appendString:valueObj];
          break;
      }
#pragma clang diagnostic pop
      [toStr appendString:@"\n"];

      [toStr appendString:msgEnd];
    }];
  }
}

static void AppendTextFormatForMessageField(ACGPBMessage *message,
                                            ACGPBFieldDescriptor *field,
                                            NSMutableString *toStr,
                                            NSString *lineIndent) {
  id arrayOrMap;
  NSUInteger count;
  ACGPBFieldType fieldType = field.fieldType;
  switch (fieldType) {
    case ACGPBFieldTypeSingle:
      arrayOrMap = nil;
      count = (ACGPBGetHasIvarField(message, field) ? 1 : 0);
      break;

    case ACGPBFieldTypeRepeated:
      // Will be NSArray or ACGPB*Array, type doesn't matter, they both
      // implement count.
      arrayOrMap = ACGPBGetObjectIvarWithFieldNoAutocreate(message, field);
      count = [(NSArray *)arrayOrMap count];
      break;

    case ACGPBFieldTypeMap: {
      // Will be ACGPB*Dictionary or NSMutableDictionary, type doesn't matter,
      // they both implement count.
      arrayOrMap = ACGPBGetObjectIvarWithFieldNoAutocreate(message, field);
      count = [(NSDictionary *)arrayOrMap count];
      break;
    }
  }

  if (count == 0) {
    // Nothing to print, out of here.
    return;
  }

  NSString *lineEnding = @"";

  // If the name can't be reversed or support for extra info was turned off,
  // this can return nil.
  NSString *fieldName = [field textFormatName];
  if ([fieldName length] == 0) {
    fieldName = [NSString stringWithFormat:@"%u", ACGPBFieldNumber(field)];
    // If there is only one entry, put the objc name as a comment, other wise
    // add it before the repeated values.
    if (count > 1) {
      [toStr appendFormat:@"%@# %@\n", lineIndent, field.name];
    } else {
      lineEnding = [NSString stringWithFormat:@"  # %@", field.name];
    }
  }

  if (fieldType == ACGPBFieldTypeMap) {
    AppendTextFormatForMapMessageField(arrayOrMap, field, toStr, lineIndent,
                                       fieldName, lineEnding);
    return;
  }

  id array = arrayOrMap;
  const BOOL isRepeated = (array != nil);

  ACGPBDataType fieldDataType = ACGPBGetFieldDataType(field);
  BOOL isMessageField = ACGPBDataTypeIsMessage(fieldDataType);
  for (NSUInteger j = 0; j < count; ++j) {
    // Start the line.
    [toStr appendFormat:@"%@%@%s ", lineIndent, fieldName,
                        (isMessageField ? "" : ":")];

    // The value.
    switch (fieldDataType) {
#define FIELD_CASE(ACGPBDATATYPE, CTYPE, REAL_TYPE, ...)                        \
  case ACGPBDataType##ACGPBDATATYPE: {                                            \
    CTYPE v = (isRepeated ? [(ACGPB##REAL_TYPE##Array *)array valueAtIndex:j]   \
                          : ACGPBGetMessage##REAL_TYPE##Field(message, field)); \
    [toStr appendFormat:__VA_ARGS__, v];                                      \
    break;                                                                    \
  }

      FIELD_CASE(Int32, int32_t, Int32, @"%d")
      FIELD_CASE(SInt32, int32_t, Int32, @"%d")
      FIELD_CASE(SFixed32, int32_t, Int32, @"%d")
      FIELD_CASE(UInt32, uint32_t, UInt32, @"%u")
      FIELD_CASE(Fixed32, uint32_t, UInt32, @"%u")
      FIELD_CASE(Int64, int64_t, Int64, @"%lld")
      FIELD_CASE(SInt64, int64_t, Int64, @"%lld")
      FIELD_CASE(SFixed64, int64_t, Int64, @"%lld")
      FIELD_CASE(UInt64, uint64_t, UInt64, @"%llu")
      FIELD_CASE(Fixed64, uint64_t, UInt64, @"%llu")
      FIELD_CASE(Float, float, Float, @"%.*g", FLT_DIG)
      FIELD_CASE(Double, double, Double, @"%.*lg", DBL_DIG)

#undef FIELD_CASE

      case ACGPBDataTypeEnum: {
        int32_t v = (isRepeated ? [(ACGPBEnumArray *)array rawValueAtIndex:j]
                                : ACGPBGetMessageInt32Field(message, field));
        NSString *valueStr = nil;
        ACGPBEnumDescriptor *descriptor = field.enumDescriptor;
        if (descriptor) {
          valueStr = [descriptor textFormatNameForValue:v];
        }
        if (valueStr) {
          [toStr appendString:valueStr];
        } else {
          [toStr appendFormat:@"%d", v];
        }
        break;
      }

      case ACGPBDataTypeBool: {
        BOOL v = (isRepeated ? [(ACGPBBoolArray *)array valueAtIndex:j]
                             : ACGPBGetMessageBoolField(message, field));
        [toStr appendString:(v ? @"true" : @"false")];
        break;
      }

      case ACGPBDataTypeString: {
        NSString *v = (isRepeated ? [(NSArray *)array objectAtIndex:j]
                                  : ACGPBGetMessageStringField(message, field));
        AppendStringEscaped(v, toStr);
        break;
      }

      case ACGPBDataTypeBytes: {
        NSData *v = (isRepeated ? [(NSArray *)array objectAtIndex:j]
                                : ACGPBGetMessageBytesField(message, field));
        AppendBufferAsString(v, toStr);
        break;
      }

      case ACGPBDataTypeGroup:
      case ACGPBDataTypeMessage: {
        ACGPBMessage *v =
            (isRepeated ? [(NSArray *)array objectAtIndex:j]
                        : ACGPBGetObjectIvarWithField(message, field));
        [toStr appendFormat:@"{%@\n", lineEnding];
        NSString *subIndent = [lineIndent stringByAppendingString:@"  "];
        AppendTextFormatForMessage(v, toStr, subIndent);
        [toStr appendFormat:@"%@}", lineIndent];
        lineEnding = @"";
        break;
      }

    }  // switch(fieldDataType)

    // End the line.
    [toStr appendFormat:@"%@\n", lineEnding];

  }  // for(count)
}

static void AppendTextFormatForMessageExtensionRange(ACGPBMessage *message,
                                                     NSArray *activeExtensions,
                                                     ACGPBExtensionRange range,
                                                     NSMutableString *toStr,
                                                     NSString *lineIndent) {
  uint32_t start = range.start;
  uint32_t end = range.end;
  for (ACGPBExtensionDescriptor *extension in activeExtensions) {
    uint32_t fieldNumber = extension.fieldNumber;
    if (fieldNumber < start) {
      // Not there yet.
      continue;
    }
    if (fieldNumber >= end) {
      // Done.
      break;
    }

    id rawExtValue = [message getExtension:extension];
    BOOL isRepeated = extension.isRepeated;

    NSUInteger numValues = 1;
    NSString *lineEnding = @"";
    if (isRepeated) {
      numValues = [(NSArray *)rawExtValue count];
    }

    NSString *singletonName = extension.singletonName;
    if (numValues == 1) {
      lineEnding = [NSString stringWithFormat:@"  # [%@]", singletonName];
    } else {
      [toStr appendFormat:@"%@# [%@]\n", lineIndent, singletonName];
    }

    ACGPBDataType extDataType = extension.dataType;
    for (NSUInteger j = 0; j < numValues; ++j) {
      id curValue = (isRepeated ? [rawExtValue objectAtIndex:j] : rawExtValue);

      // Start the line.
      [toStr appendFormat:@"%@%u%s ", lineIndent, fieldNumber,
                          (ACGPBDataTypeIsMessage(extDataType) ? "" : ":")];

      // The value.
      switch (extDataType) {
#define FIELD_CASE(ACGPBDATATYPE, CTYPE, NUMSELECTOR, ...) \
  case ACGPBDataType##ACGPBDATATYPE: {                       \
    CTYPE v = [(NSNumber *)curValue NUMSELECTOR];        \
    [toStr appendFormat:__VA_ARGS__, v];                 \
    break;                                               \
  }

        FIELD_CASE(Int32, int32_t, intValue, @"%d")
        FIELD_CASE(SInt32, int32_t, intValue, @"%d")
        FIELD_CASE(SFixed32, int32_t, unsignedIntValue, @"%d")
        FIELD_CASE(UInt32, uint32_t, unsignedIntValue, @"%u")
        FIELD_CASE(Fixed32, uint32_t, unsignedIntValue, @"%u")
        FIELD_CASE(Int64, int64_t, longLongValue, @"%lld")
        FIELD_CASE(SInt64, int64_t, longLongValue, @"%lld")
        FIELD_CASE(SFixed64, int64_t, longLongValue, @"%lld")
        FIELD_CASE(UInt64, uint64_t, unsignedLongLongValue, @"%llu")
        FIELD_CASE(Fixed64, uint64_t, unsignedLongLongValue, @"%llu")
        FIELD_CASE(Float, float, floatValue, @"%.*g", FLT_DIG)
        FIELD_CASE(Double, double, doubleValue, @"%.*lg", DBL_DIG)
        // TODO: Add a comment with the enum name from enum descriptors
        // (might not be real value, so leave it as a comment, ObjC compiler
        // name mangles differently).  Doesn't look like we actually generate
        // an enum descriptor reference like we do for normal fields, so this
        // will take a compiler change.
        FIELD_CASE(Enum, int32_t, intValue, @"%d")

#undef FIELD_CASE

        case ACGPBDataTypeBool:
          [toStr appendString:([(NSNumber *)curValue boolValue] ? @"true"
                                                                : @"false")];
          break;

        case ACGPBDataTypeString:
          AppendStringEscaped(curValue, toStr);
          break;

        case ACGPBDataTypeBytes:
          AppendBufferAsString((NSData *)curValue, toStr);
          break;

        case ACGPBDataTypeGroup:
        case ACGPBDataTypeMessage: {
          [toStr appendFormat:@"{%@\n", lineEnding];
          NSString *subIndent = [lineIndent stringByAppendingString:@"  "];
          AppendTextFormatForMessage(curValue, toStr, subIndent);
          [toStr appendFormat:@"%@}", lineIndent];
          lineEnding = @"";
          break;
        }

      }  // switch(extDataType)

      // End the line.
      [toStr appendFormat:@"%@\n", lineEnding];

    }  //  for(numValues)

  }  // for..in(activeExtensions)
}

static void AppendTextFormatForMessage(ACGPBMessage *message,
                                       NSMutableString *toStr,
                                       NSString *lineIndent) {
  ACGPBDescriptor *descriptor = [message descriptor];
  NSArray *fieldsArray = descriptor->fields_;
  NSUInteger fieldCount = fieldsArray.count;
  const ACGPBExtensionRange *extensionRanges = descriptor.extensionRanges;
  NSUInteger extensionRangesCount = descriptor.extensionRangesCount;
  NSArray *activeExtensions = [[message extensionsCurrentlySet]
      sortedArrayUsingSelector:@selector(compareByFieldNumber:)];
  for (NSUInteger i = 0, j = 0; i < fieldCount || j < extensionRangesCount;) {
    if (i == fieldCount) {
      AppendTextFormatForMessageExtensionRange(
          message, activeExtensions, extensionRanges[j++], toStr, lineIndent);
    } else if (j == extensionRangesCount ||
               ACGPBFieldNumber(fieldsArray[i]) < extensionRanges[j].start) {
      AppendTextFormatForMessageField(message, fieldsArray[i++], toStr,
                                      lineIndent);
    } else {
      AppendTextFormatForMessageExtensionRange(
          message, activeExtensions, extensionRanges[j++], toStr, lineIndent);
    }
  }

  NSString *unknownFieldsStr =
      ACGPBTextFormatForUnknownFieldSet(message.unknownFields, lineIndent);
  if ([unknownFieldsStr length] > 0) {
    [toStr appendFormat:@"%@# --- Unknown fields ---\n", lineIndent];
    [toStr appendString:unknownFieldsStr];
  }
}

NSString *ACGPBTextFormatForMessage(ACGPBMessage *message, NSString *lineIndent) {
  if (message == nil) return @"";
  if (lineIndent == nil) lineIndent = @"";

  NSMutableString *buildString = [NSMutableString string];
  AppendTextFormatForMessage(message, buildString, lineIndent);
  return buildString;
}

NSString *ACGPBTextFormatForUnknownFieldSet(ACGPBUnknownFieldSet *unknownSet,
                                          NSString *lineIndent) {
  if (unknownSet == nil) return @"";
  if (lineIndent == nil) lineIndent = @"";

  NSMutableString *result = [NSMutableString string];
  for (ACGPBUnknownField *field in [unknownSet sortedFields]) {
    int32_t fieldNumber = [field number];

#define PRINT_LOOP(PROPNAME, CTYPE, FORMAT)                                   \
  [field.PROPNAME                                                             \
      enumerateValuesWithBlock:^(CTYPE value, NSUInteger idx, BOOL * stop) {  \
    _Pragma("unused(idx, stop)");                                             \
    [result                                                                   \
        appendFormat:@"%@%d: " #FORMAT "\n", lineIndent, fieldNumber, value]; \
      }];

    PRINT_LOOP(varintList, uint64_t, %llu);
    PRINT_LOOP(fixed32List, uint32_t, 0x%X);
    PRINT_LOOP(fixed64List, uint64_t, 0x%llX);

#undef PRINT_LOOP

    // NOTE: C++ version of TextFormat tries to parse this as a message
    // and print that if it succeeds.
    for (NSData *data in field.lengthDelimitedList) {
      [result appendFormat:@"%@%d: ", lineIndent, fieldNumber];
      AppendBufferAsString(data, result);
      [result appendString:@"\n"];
    }

    for (ACGPBUnknownFieldSet *subUnknownSet in field.groupList) {
      [result appendFormat:@"%@%d: {\n", lineIndent, fieldNumber];
      NSString *subIndent = [lineIndent stringByAppendingString:@"  "];
      NSString *subUnknownSetStr =
          ACGPBTextFormatForUnknownFieldSet(subUnknownSet, subIndent);
      [result appendString:subUnknownSetStr];
      [result appendFormat:@"%@}\n", lineIndent];
    }
  }
  return result;
}

// Helpers to decode a varint. Not using ACGPBCodedInputStream version because
// that needs a state object, and we don't want to create an input stream out
// of the data.
ACGPB_INLINE int8_t ReadRawByteFromData(const uint8_t **data) {
  int8_t result = *((int8_t *)(*data));
  ++(*data);
  return result;
}

static int32_t ReadRawVarint32FromData(const uint8_t **data) {
  int8_t tmp = ReadRawByteFromData(data);
  if (tmp >= 0) {
    return tmp;
  }
  int32_t result = tmp & 0x7f;
  if ((tmp = ReadRawByteFromData(data)) >= 0) {
    result |= tmp << 7;
  } else {
    result |= (tmp & 0x7f) << 7;
    if ((tmp = ReadRawByteFromData(data)) >= 0) {
      result |= tmp << 14;
    } else {
      result |= (tmp & 0x7f) << 14;
      if ((tmp = ReadRawByteFromData(data)) >= 0) {
        result |= tmp << 21;
      } else {
        result |= (tmp & 0x7f) << 21;
        result |= (tmp = ReadRawByteFromData(data)) << 28;
        if (tmp < 0) {
          // Discard upper 32 bits.
          for (int i = 0; i < 5; i++) {
            if (ReadRawByteFromData(data) >= 0) {
              return result;
            }
          }
          [NSException raise:NSParseErrorException
                      format:@"Unable to read varint32"];
        }
      }
    }
  }
  return result;
}

NSString *ACGPBDecodeTextFormatName(const uint8_t *decodeData, int32_t key,
                                  NSString *inputStr) {
  // decodData form:
  //  varint32: num entries
  //  for each entry:
  //    varint32: key
  //    bytes*: decode data
  //
  // decode data one of two forms:
  //  1: a \0 followed by the string followed by an \0
  //  2: bytecodes to transform an input into the right thing, ending with \0
  //
  // the bytes codes are of the form:
  //  0xabbccccc
  //  0x0 (all zeros), end.
  //  a - if set, add an underscore
  //  bb - 00 ccccc bytes as is
  //  bb - 10 ccccc upper first, as is on rest, ccccc byte total
  //  bb - 01 ccccc lower first, as is on rest, ccccc byte total
  //  bb - 11 ccccc all upper, ccccc byte total

  if (!decodeData || !inputStr) {
    return nil;
  }

  // Find key
  const uint8_t *scan = decodeData;
  int32_t numEntries = ReadRawVarint32FromData(&scan);
  BOOL foundKey = NO;
  while (!foundKey && (numEntries > 0)) {
    --numEntries;
    int32_t dataKey = ReadRawVarint32FromData(&scan);
    if (dataKey == key) {
      foundKey = YES;
    } else {
      // If it is a inlined string, it will start with \0; if it is bytecode it
      // will start with a code. So advance one (skipping the inline string
      // marker), and then loop until reaching the end marker (\0).
      ++scan;
      while (*scan != 0) ++scan;
      // Now move past the end marker.
      ++scan;
    }
  }

  if (!foundKey) {
    return nil;
  }

  // Decode

  if (*scan == 0) {
    // Inline string. Move over the marker, and NSString can take it as
    // UTF8.
    ++scan;
    NSString *result = [NSString stringWithUTF8String:(const char *)scan];
    return result;
  }

  NSMutableString *result =
      [NSMutableString stringWithCapacity:[inputStr length]];

  const uint8_t kAddUnderscore  = 0b10000000;
  const uint8_t kOpMask         = 0b01100000;
  // const uint8_t kOpAsIs        = 0b00000000;
  const uint8_t kOpFirstUpper     = 0b01000000;
  const uint8_t kOpFirstLower     = 0b00100000;
  const uint8_t kOpAllUpper       = 0b01100000;
  const uint8_t kSegmentLenMask = 0b00011111;

  NSInteger i = 0;
  for (; *scan != 0; ++scan) {
    if (*scan & kAddUnderscore) {
      [result appendString:@"_"];
    }
    int segmentLen = *scan & kSegmentLenMask;
    uint8_t decodeOp = *scan & kOpMask;

    // Do op specific handling of the first character.
    if (decodeOp == kOpFirstUpper) {
      unichar c = [inputStr characterAtIndex:i];
      [result appendFormat:@"%c", toupper((char)c)];
      ++i;
      --segmentLen;
    } else if (decodeOp == kOpFirstLower) {
      unichar c = [inputStr characterAtIndex:i];
      [result appendFormat:@"%c", tolower((char)c)];
      ++i;
      --segmentLen;
    }
    // else op == kOpAsIs || op == kOpAllUpper

    // Now pull over the rest of the length for this segment.
    for (int x = 0; x < segmentLen; ++x) {
      unichar c = [inputStr characterAtIndex:(i + x)];
      if (decodeOp == kOpAllUpper) {
        [result appendFormat:@"%c", toupper((char)c)];
      } else {
        [result appendFormat:@"%C", c];
      }
    }
    i += segmentLen;
  }

  return result;
}

#pragma mark Legacy methods old generated code calls

// Shim from the older generated code into the runtime.
void ACGPBSetInt32IvarWithFieldInternal(ACGPBMessage *self,
                                      ACGPBFieldDescriptor *field,
                                      int32_t value,
                                      ACGPBFileSyntax syntax) {
#pragma unused(syntax)
  ACGPBSetMessageInt32Field(self, field, value);
}

void ACGPBMaybeClearOneof(ACGPBMessage *self, ACGPBOneofDescriptor *oneof,
                        int32_t oneofHasIndex, uint32_t fieldNumberNotToClear) {
#pragma unused(fieldNumberNotToClear)
  #if defined(DEBUG) && DEBUG
    NSCAssert([[self descriptor] oneofWithName:oneof.name] == oneof,
              @"OneofDescriptor %@ doesn't appear to be for %@ messages.",
              oneof.name, [self class]);
    ACGPBFieldDescriptor *firstField = oneof->fields_[0];
    NSCAssert(firstField->description_->hasIndex == oneofHasIndex,
              @"Internal error, oneofHasIndex (%d) doesn't match (%d).",
              firstField->description_->hasIndex, oneofHasIndex);
  #endif
  ACGPBMaybeClearOneofPrivate(self, oneof, oneofHasIndex, 0);
}

#pragma clang diagnostic pop

#pragma mark Misc Helpers

BOOL ACGPBClassHasSel(Class aClass, SEL sel) {
  // NOTE: We have to use class_copyMethodList, all other runtime method
  // lookups actually also resolve the method implementation and this
  // is called from within those methods.

  BOOL result = NO;
  unsigned int methodCount = 0;
  Method *methodList = class_copyMethodList(aClass, &methodCount);
  for (unsigned int i = 0; i < methodCount; ++i) {
    SEL methodSelector = method_getName(methodList[i]);
    if (methodSelector == sel) {
      result = YES;
      break;
    }
  }
  free(methodList);
  return result;
}
