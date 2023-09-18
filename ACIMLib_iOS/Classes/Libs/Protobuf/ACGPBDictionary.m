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

#import "ACGPBDictionary_PackagePrivate.h"

#import "ACGPBCodedInputStream_PackagePrivate.h"
#import "ACGPBCodedOutputStream_PackagePrivate.h"
#import "ACGPBDescriptor_PackagePrivate.h"
#import "ACGPBMessage_PackagePrivate.h"
#import "ACGPBUtilities_PackagePrivate.h"

// ------------------------------ NOTE ------------------------------
// At the moment, this is all using NSNumbers in NSDictionaries under
// the hood, but it is all hidden so we can come back and optimize
// with direct CFDictionary usage later.  The reason that wasn't
// done yet is needing to support 32bit iOS builds.  Otherwise
// it would be pretty simple to store all this data in CFDictionaries
// directly.
// ------------------------------------------------------------------

// Direct access is use for speed, to avoid even internally declaring things
// read/write, etc. The warning is enabled in the project to ensure code calling
// protos can turn on -Wdirect-ivar-access without issues.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

// Used to include code only visible to specific versions of the static
// analyzer. Useful for wrapping code that only exists to silence the analyzer.
// Determine the values you want to use for BEGIN_APPLE_BUILD_VERSION,
// END_APPLE_BUILD_VERSION using:
//   xcrun clang -dM -E -x c /dev/null | grep __apple_build_version__
// Example usage:
//  #if ACGPB_STATIC_ANALYZER_ONLY(5621, 5623) ... #endif
#define ACGPB_STATIC_ANALYZER_ONLY(BEGIN_APPLE_BUILD_VERSION, END_APPLE_BUILD_VERSION) \
    (defined(__clang_analyzer__) && \
     (__apple_build_version__ >= BEGIN_APPLE_BUILD_VERSION && \
      __apple_build_version__ <= END_APPLE_BUILD_VERSION))

enum {
  kMapKeyFieldNumber = 1,
  kMapValueFieldNumber = 2,
};

static BOOL DictDefault_IsValidValue(int32_t value) {
  // Anything but the bad value marker is allowed.
  return (value != kACGPBUnrecognizedEnumeratorValue);
}

//%PDDM-DEFINE SERIALIZE_SUPPORT_2_TYPE(VALUE_NAME, VALUE_TYPE, ACGPBDATATYPE_NAME1, ACGPBDATATYPE_NAME2)
//%static size_t ComputeDict##VALUE_NAME##FieldSize(VALUE_TYPE value, uint32_t fieldNum, ACGPBDataType dataType) {
//%  if (dataType == ACGPBDataType##ACGPBDATATYPE_NAME1) {
//%    return ACGPBCompute##ACGPBDATATYPE_NAME1##Size(fieldNum, value);
//%  } else if (dataType == ACGPBDataType##ACGPBDATATYPE_NAME2) {
//%    return ACGPBCompute##ACGPBDATATYPE_NAME2##Size(fieldNum, value);
//%  } else {
//%    NSCAssert(NO, @"Unexpected type %d", dataType);
//%    return 0;
//%  }
//%}
//%
//%static void WriteDict##VALUE_NAME##Field(ACGPBCodedOutputStream *stream, VALUE_TYPE value, uint32_t fieldNum, ACGPBDataType dataType) {
//%  if (dataType == ACGPBDataType##ACGPBDATATYPE_NAME1) {
//%    [stream write##ACGPBDATATYPE_NAME1##:fieldNum value:value];
//%  } else if (dataType == ACGPBDataType##ACGPBDATATYPE_NAME2) {
//%    [stream write##ACGPBDATATYPE_NAME2##:fieldNum value:value];
//%  } else {
//%    NSCAssert(NO, @"Unexpected type %d", dataType);
//%  }
//%}
//%
//%PDDM-DEFINE SERIALIZE_SUPPORT_3_TYPE(VALUE_NAME, VALUE_TYPE, ACGPBDATATYPE_NAME1, ACGPBDATATYPE_NAME2, ACGPBDATATYPE_NAME3)
//%static size_t ComputeDict##VALUE_NAME##FieldSize(VALUE_TYPE value, uint32_t fieldNum, ACGPBDataType dataType) {
//%  if (dataType == ACGPBDataType##ACGPBDATATYPE_NAME1) {
//%    return ACGPBCompute##ACGPBDATATYPE_NAME1##Size(fieldNum, value);
//%  } else if (dataType == ACGPBDataType##ACGPBDATATYPE_NAME2) {
//%    return ACGPBCompute##ACGPBDATATYPE_NAME2##Size(fieldNum, value);
//%  } else if (dataType == ACGPBDataType##ACGPBDATATYPE_NAME3) {
//%    return ACGPBCompute##ACGPBDATATYPE_NAME3##Size(fieldNum, value);
//%  } else {
//%    NSCAssert(NO, @"Unexpected type %d", dataType);
//%    return 0;
//%  }
//%}
//%
//%static void WriteDict##VALUE_NAME##Field(ACGPBCodedOutputStream *stream, VALUE_TYPE value, uint32_t fieldNum, ACGPBDataType dataType) {
//%  if (dataType == ACGPBDataType##ACGPBDATATYPE_NAME1) {
//%    [stream write##ACGPBDATATYPE_NAME1##:fieldNum value:value];
//%  } else if (dataType == ACGPBDataType##ACGPBDATATYPE_NAME2) {
//%    [stream write##ACGPBDATATYPE_NAME2##:fieldNum value:value];
//%  } else if (dataType == ACGPBDataType##ACGPBDATATYPE_NAME3) {
//%    [stream write##ACGPBDATATYPE_NAME3##:fieldNum value:value];
//%  } else {
//%    NSCAssert(NO, @"Unexpected type %d", dataType);
//%  }
//%}
//%
//%PDDM-DEFINE SIMPLE_SERIALIZE_SUPPORT(VALUE_NAME, VALUE_TYPE, VisP)
//%static size_t ComputeDict##VALUE_NAME##FieldSize(VALUE_TYPE VisP##value, uint32_t fieldNum, ACGPBDataType dataType) {
//%  NSCAssert(dataType == ACGPBDataType##VALUE_NAME, @"bad type: %d", dataType);
//%  #pragma unused(dataType)  // For when asserts are off in release.
//%  return ACGPBCompute##VALUE_NAME##Size(fieldNum, value);
//%}
//%
//%static void WriteDict##VALUE_NAME##Field(ACGPBCodedOutputStream *stream, VALUE_TYPE VisP##value, uint32_t fieldNum, ACGPBDataType dataType) {
//%  NSCAssert(dataType == ACGPBDataType##VALUE_NAME, @"bad type: %d", dataType);
//%  #pragma unused(dataType)  // For when asserts are off in release.
//%  [stream write##VALUE_NAME##:fieldNum value:value];
//%}
//%
//%PDDM-DEFINE SERIALIZE_SUPPORT_HELPERS()
//%SERIALIZE_SUPPORT_3_TYPE(Int32, int32_t, Int32, SInt32, SFixed32)
//%SERIALIZE_SUPPORT_2_TYPE(UInt32, uint32_t, UInt32, Fixed32)
//%SERIALIZE_SUPPORT_3_TYPE(Int64, int64_t, Int64, SInt64, SFixed64)
//%SERIALIZE_SUPPORT_2_TYPE(UInt64, uint64_t, UInt64, Fixed64)
//%SIMPLE_SERIALIZE_SUPPORT(Bool, BOOL, )
//%SIMPLE_SERIALIZE_SUPPORT(Enum, int32_t, )
//%SIMPLE_SERIALIZE_SUPPORT(Float, float, )
//%SIMPLE_SERIALIZE_SUPPORT(Double, double, )
//%SIMPLE_SERIALIZE_SUPPORT(String, NSString, *)
//%SERIALIZE_SUPPORT_3_TYPE(Object, id, Message, String, Bytes)
//%PDDM-EXPAND SERIALIZE_SUPPORT_HELPERS()
// This block of code is generated, do not edit it directly.
// clang-format off

static size_t ComputeDictInt32FieldSize(int32_t value, uint32_t fieldNum, ACGPBDataType dataType) {
  if (dataType == ACGPBDataTypeInt32) {
    return ACGPBComputeInt32Size(fieldNum, value);
  } else if (dataType == ACGPBDataTypeSInt32) {
    return ACGPBComputeSInt32Size(fieldNum, value);
  } else if (dataType == ACGPBDataTypeSFixed32) {
    return ACGPBComputeSFixed32Size(fieldNum, value);
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
    return 0;
  }
}

static void WriteDictInt32Field(ACGPBCodedOutputStream *stream, int32_t value, uint32_t fieldNum, ACGPBDataType dataType) {
  if (dataType == ACGPBDataTypeInt32) {
    [stream writeInt32:fieldNum value:value];
  } else if (dataType == ACGPBDataTypeSInt32) {
    [stream writeSInt32:fieldNum value:value];
  } else if (dataType == ACGPBDataTypeSFixed32) {
    [stream writeSFixed32:fieldNum value:value];
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
  }
}

static size_t ComputeDictUInt32FieldSize(uint32_t value, uint32_t fieldNum, ACGPBDataType dataType) {
  if (dataType == ACGPBDataTypeUInt32) {
    return ACGPBComputeUInt32Size(fieldNum, value);
  } else if (dataType == ACGPBDataTypeFixed32) {
    return ACGPBComputeFixed32Size(fieldNum, value);
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
    return 0;
  }
}

static void WriteDictUInt32Field(ACGPBCodedOutputStream *stream, uint32_t value, uint32_t fieldNum, ACGPBDataType dataType) {
  if (dataType == ACGPBDataTypeUInt32) {
    [stream writeUInt32:fieldNum value:value];
  } else if (dataType == ACGPBDataTypeFixed32) {
    [stream writeFixed32:fieldNum value:value];
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
  }
}

static size_t ComputeDictInt64FieldSize(int64_t value, uint32_t fieldNum, ACGPBDataType dataType) {
  if (dataType == ACGPBDataTypeInt64) {
    return ACGPBComputeInt64Size(fieldNum, value);
  } else if (dataType == ACGPBDataTypeSInt64) {
    return ACGPBComputeSInt64Size(fieldNum, value);
  } else if (dataType == ACGPBDataTypeSFixed64) {
    return ACGPBComputeSFixed64Size(fieldNum, value);
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
    return 0;
  }
}

static void WriteDictInt64Field(ACGPBCodedOutputStream *stream, int64_t value, uint32_t fieldNum, ACGPBDataType dataType) {
  if (dataType == ACGPBDataTypeInt64) {
    [stream writeInt64:fieldNum value:value];
  } else if (dataType == ACGPBDataTypeSInt64) {
    [stream writeSInt64:fieldNum value:value];
  } else if (dataType == ACGPBDataTypeSFixed64) {
    [stream writeSFixed64:fieldNum value:value];
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
  }
}

static size_t ComputeDictUInt64FieldSize(uint64_t value, uint32_t fieldNum, ACGPBDataType dataType) {
  if (dataType == ACGPBDataTypeUInt64) {
    return ACGPBComputeUInt64Size(fieldNum, value);
  } else if (dataType == ACGPBDataTypeFixed64) {
    return ACGPBComputeFixed64Size(fieldNum, value);
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
    return 0;
  }
}

static void WriteDictUInt64Field(ACGPBCodedOutputStream *stream, uint64_t value, uint32_t fieldNum, ACGPBDataType dataType) {
  if (dataType == ACGPBDataTypeUInt64) {
    [stream writeUInt64:fieldNum value:value];
  } else if (dataType == ACGPBDataTypeFixed64) {
    [stream writeFixed64:fieldNum value:value];
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
  }
}

static size_t ComputeDictBoolFieldSize(BOOL value, uint32_t fieldNum, ACGPBDataType dataType) {
  NSCAssert(dataType == ACGPBDataTypeBool, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  return ACGPBComputeBoolSize(fieldNum, value);
}

static void WriteDictBoolField(ACGPBCodedOutputStream *stream, BOOL value, uint32_t fieldNum, ACGPBDataType dataType) {
  NSCAssert(dataType == ACGPBDataTypeBool, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  [stream writeBool:fieldNum value:value];
}

static size_t ComputeDictEnumFieldSize(int32_t value, uint32_t fieldNum, ACGPBDataType dataType) {
  NSCAssert(dataType == ACGPBDataTypeEnum, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  return ACGPBComputeEnumSize(fieldNum, value);
}

static void WriteDictEnumField(ACGPBCodedOutputStream *stream, int32_t value, uint32_t fieldNum, ACGPBDataType dataType) {
  NSCAssert(dataType == ACGPBDataTypeEnum, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  [stream writeEnum:fieldNum value:value];
}

static size_t ComputeDictFloatFieldSize(float value, uint32_t fieldNum, ACGPBDataType dataType) {
  NSCAssert(dataType == ACGPBDataTypeFloat, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  return ACGPBComputeFloatSize(fieldNum, value);
}

static void WriteDictFloatField(ACGPBCodedOutputStream *stream, float value, uint32_t fieldNum, ACGPBDataType dataType) {
  NSCAssert(dataType == ACGPBDataTypeFloat, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  [stream writeFloat:fieldNum value:value];
}

static size_t ComputeDictDoubleFieldSize(double value, uint32_t fieldNum, ACGPBDataType dataType) {
  NSCAssert(dataType == ACGPBDataTypeDouble, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  return ACGPBComputeDoubleSize(fieldNum, value);
}

static void WriteDictDoubleField(ACGPBCodedOutputStream *stream, double value, uint32_t fieldNum, ACGPBDataType dataType) {
  NSCAssert(dataType == ACGPBDataTypeDouble, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  [stream writeDouble:fieldNum value:value];
}

static size_t ComputeDictStringFieldSize(NSString *value, uint32_t fieldNum, ACGPBDataType dataType) {
  NSCAssert(dataType == ACGPBDataTypeString, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  return ACGPBComputeStringSize(fieldNum, value);
}

static void WriteDictStringField(ACGPBCodedOutputStream *stream, NSString *value, uint32_t fieldNum, ACGPBDataType dataType) {
  NSCAssert(dataType == ACGPBDataTypeString, @"bad type: %d", dataType);
  #pragma unused(dataType)  // For when asserts are off in release.
  [stream writeString:fieldNum value:value];
}

static size_t ComputeDictObjectFieldSize(id value, uint32_t fieldNum, ACGPBDataType dataType) {
  if (dataType == ACGPBDataTypeMessage) {
    return ACGPBComputeMessageSize(fieldNum, value);
  } else if (dataType == ACGPBDataTypeString) {
    return ACGPBComputeStringSize(fieldNum, value);
  } else if (dataType == ACGPBDataTypeBytes) {
    return ACGPBComputeBytesSize(fieldNum, value);
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
    return 0;
  }
}

static void WriteDictObjectField(ACGPBCodedOutputStream *stream, id value, uint32_t fieldNum, ACGPBDataType dataType) {
  if (dataType == ACGPBDataTypeMessage) {
    [stream writeMessage:fieldNum value:value];
  } else if (dataType == ACGPBDataTypeString) {
    [stream writeString:fieldNum value:value];
  } else if (dataType == ACGPBDataTypeBytes) {
    [stream writeBytes:fieldNum value:value];
  } else {
    NSCAssert(NO, @"Unexpected type %d", dataType);
  }
}

// clang-format on
//%PDDM-EXPAND-END SERIALIZE_SUPPORT_HELPERS()

size_t ACGPBDictionaryComputeSizeInternalHelper(NSDictionary *dict, ACGPBFieldDescriptor *field) {
  ACGPBDataType mapValueType = ACGPBGetFieldDataType(field);
  size_t result = 0;
  NSString *key;
  NSEnumerator *keys = [dict keyEnumerator];
  while ((key = [keys nextObject])) {
    id obj = dict[key];
    size_t msgSize = ACGPBComputeStringSize(kMapKeyFieldNumber, key);
    msgSize += ComputeDictObjectFieldSize(obj, kMapValueFieldNumber, mapValueType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * dict.count;
  return result;
}

void ACGPBDictionaryWriteToStreamInternalHelper(ACGPBCodedOutputStream *outputStream,
                                              NSDictionary *dict,
                                              ACGPBFieldDescriptor *field) {
  NSCAssert(field.mapKeyDataType == ACGPBDataTypeString, @"Unexpected key type");
  ACGPBDataType mapValueType = ACGPBGetFieldDataType(field);
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSString *key;
  NSEnumerator *keys = [dict keyEnumerator];
  while ((key = [keys nextObject])) {
    id obj = dict[key];
    // Write the tag.
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    size_t msgSize = ACGPBComputeStringSize(kMapKeyFieldNumber, key);
    msgSize += ComputeDictObjectFieldSize(obj, kMapValueFieldNumber, mapValueType);

    // Write the size and fields.
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    [outputStream writeString:kMapKeyFieldNumber value:key];
    WriteDictObjectField(outputStream, obj, kMapValueFieldNumber, mapValueType);
  }
}

BOOL ACGPBDictionaryIsInitializedInternalHelper(NSDictionary *dict, ACGPBFieldDescriptor *field) {
  NSCAssert(field.mapKeyDataType == ACGPBDataTypeString, @"Unexpected key type");
  NSCAssert(ACGPBGetFieldDataType(field) == ACGPBDataTypeMessage, @"Unexpected value type");
  #pragma unused(field)  // For when asserts are off in release.
  ACGPBMessage *msg;
  NSEnumerator *objects = [dict objectEnumerator];
  while ((msg = [objects nextObject])) {
    if (!msg.initialized) {
      return NO;
    }
  }
  return YES;
}

// Note: if the type is an object, it the retain pass back to the caller.
static void ReadValue(ACGPBCodedInputStream *stream,
                      ACGPBGenericValue *valueToFill,
                      ACGPBDataType type,
                      ACGPBExtensionRegistry *registry,
                      ACGPBFieldDescriptor *field) {
  switch (type) {
    case ACGPBDataTypeBool:
      valueToFill->valueBool = ACGPBCodedInputStreamReadBool(&stream->state_);
      break;
    case ACGPBDataTypeFixed32:
      valueToFill->valueUInt32 = ACGPBCodedInputStreamReadFixed32(&stream->state_);
      break;
    case ACGPBDataTypeSFixed32:
      valueToFill->valueInt32 = ACGPBCodedInputStreamReadSFixed32(&stream->state_);
      break;
    case ACGPBDataTypeFloat:
      valueToFill->valueFloat = ACGPBCodedInputStreamReadFloat(&stream->state_);
      break;
    case ACGPBDataTypeFixed64:
      valueToFill->valueUInt64 = ACGPBCodedInputStreamReadFixed64(&stream->state_);
      break;
    case ACGPBDataTypeSFixed64:
      valueToFill->valueInt64 = ACGPBCodedInputStreamReadSFixed64(&stream->state_);
      break;
    case ACGPBDataTypeDouble:
      valueToFill->valueDouble = ACGPBCodedInputStreamReadDouble(&stream->state_);
      break;
    case ACGPBDataTypeInt32:
      valueToFill->valueInt32 = ACGPBCodedInputStreamReadInt32(&stream->state_);
      break;
    case ACGPBDataTypeInt64:
      valueToFill->valueInt64 = ACGPBCodedInputStreamReadInt64(&stream->state_);
      break;
    case ACGPBDataTypeSInt32:
      valueToFill->valueInt32 = ACGPBCodedInputStreamReadSInt32(&stream->state_);
      break;
    case ACGPBDataTypeSInt64:
      valueToFill->valueInt64 = ACGPBCodedInputStreamReadSInt64(&stream->state_);
      break;
    case ACGPBDataTypeUInt32:
      valueToFill->valueUInt32 = ACGPBCodedInputStreamReadUInt32(&stream->state_);
      break;
    case ACGPBDataTypeUInt64:
      valueToFill->valueUInt64 = ACGPBCodedInputStreamReadUInt64(&stream->state_);
      break;
    case ACGPBDataTypeBytes:
      [valueToFill->valueData release];
      valueToFill->valueData = ACGPBCodedInputStreamReadRetainedBytes(&stream->state_);
      break;
    case ACGPBDataTypeString:
      [valueToFill->valueString release];
      valueToFill->valueString = ACGPBCodedInputStreamReadRetainedString(&stream->state_);
      break;
    case ACGPBDataTypeMessage: {
      ACGPBMessage *message = [[field.msgClass alloc] init];
      [stream readMessage:message extensionRegistry:registry];
      [valueToFill->valueMessage release];
      valueToFill->valueMessage = message;
      break;
    }
    case ACGPBDataTypeGroup:
      NSCAssert(NO, @"Can't happen");
      break;
    case ACGPBDataTypeEnum:
      valueToFill->valueEnum = ACGPBCodedInputStreamReadEnum(&stream->state_);
      break;
  }
}

void ACGPBDictionaryReadEntry(id mapDictionary,
                            ACGPBCodedInputStream *stream,
                            ACGPBExtensionRegistry *registry,
                            ACGPBFieldDescriptor *field,
                            ACGPBMessage *parentMessage) {
  ACGPBDataType keyDataType = field.mapKeyDataType;
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);

  ACGPBGenericValue key;
  ACGPBGenericValue value;
  // Zero them (but pick up any enum default for proto2).
  key.valueString = value.valueString = nil;
  if (valueDataType == ACGPBDataTypeEnum) {
    value = field.defaultValue;
  }

  ACGPBCodedInputStreamState *state = &stream->state_;
  uint32_t keyTag =
      ACGPBWireFormatMakeTag(kMapKeyFieldNumber, ACGPBWireFormatForType(keyDataType, NO));
  uint32_t valueTag =
      ACGPBWireFormatMakeTag(kMapValueFieldNumber, ACGPBWireFormatForType(valueDataType, NO));

  BOOL hitError = NO;
  while (YES) {
    uint32_t tag = ACGPBCodedInputStreamReadTag(state);
    if (tag == keyTag) {
      ReadValue(stream, &key, keyDataType, registry, field);
    } else if (tag == valueTag) {
      ReadValue(stream, &value, valueDataType, registry, field);
    } else if (tag == 0) {
      // zero signals EOF / limit reached
      break;
    } else {  // Unknown
      if (![stream skipField:tag]){
        hitError = YES;
        break;
      }
    }
  }

  if (!hitError) {
    // Handle the special defaults and/or missing key/value.
    if ((keyDataType == ACGPBDataTypeString) && (key.valueString == nil)) {
      key.valueString = [@"" retain];
    }
    if (ACGPBDataTypeIsObject(valueDataType) && value.valueString == nil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
      switch (valueDataType) {
        case ACGPBDataTypeString:
          value.valueString = [@"" retain];
          break;
        case ACGPBDataTypeBytes:
          value.valueData = [ACGPBEmptyNSData() retain];
          break;
#if defined(__clang_analyzer__)
        case ACGPBDataTypeGroup:
          // Maps can't really have Groups as the value type, but this case is needed
          // so the analyzer won't report the possibility of send nil in for the value
          // in the NSMutableDictionary case below.
#endif
        case ACGPBDataTypeMessage: {
          value.valueMessage = [[field.msgClass alloc] init];
          break;
        }
        default:
          // Nothing
          break;
      }
#pragma clang diagnostic pop
    }

    if ((keyDataType == ACGPBDataTypeString) && ACGPBDataTypeIsObject(valueDataType)) {
#if ACGPB_STATIC_ANALYZER_ONLY(6020053, 7000181)
     // Limited to Xcode 6.4 - 7.2, are known to fail here. The upper end can
     // be raised as needed for new Xcodes.
     //
     // This is only needed on a "shallow" analyze; on a "deep" analyze, the
     // existing code path gets this correct. In shallow, the analyzer decides
     // ACGPBDataTypeIsObject(valueDataType) is both false and true on a single
     // path through this function, allowing nil to be used for the
     // setObject:forKey:.
     if (value.valueString == nil) {
       value.valueString = [@"" retain];
     }
#endif
      // mapDictionary is an NSMutableDictionary
      [(NSMutableDictionary *)mapDictionary setObject:value.valueString
                                               forKey:key.valueString];
    } else {
      if (valueDataType == ACGPBDataTypeEnum) {
        if (ACGPBHasPreservingUnknownEnumSemantics([parentMessage descriptor].file.syntax) ||
            [field isValidEnumValue:value.valueEnum]) {
          [mapDictionary setACGPBGenericValue:&value forACGPBGenericValueKey:&key];
        } else {
          NSData *data = [mapDictionary serializedDataForUnknownValue:value.valueEnum
                                                               forKey:&key
                                                          keyDataType:keyDataType];
          [parentMessage addUnknownMapEntry:ACGPBFieldNumber(field) value:data];
        }
      } else {
        [mapDictionary setACGPBGenericValue:&value forACGPBGenericValueKey:&key];
      }
    }
  }

  if (ACGPBDataTypeIsObject(keyDataType)) {
    [key.valueString release];
  }
  if (ACGPBDataTypeIsObject(valueDataType)) {
    [value.valueString release];
  }
}

//
// Macros for the common basic cases.
//

//%PDDM-DEFINE DICTIONARY_IMPL_FOR_POD_KEY(KEY_NAME, KEY_TYPE)
//%DICTIONARY_POD_IMPL_FOR_KEY(KEY_NAME, KEY_TYPE, , POD)
//%DICTIONARY_POD_KEY_TO_OBJECT_IMPL(KEY_NAME, KEY_TYPE, Object, id)

//%PDDM-DEFINE DICTIONARY_POD_IMPL_FOR_KEY(KEY_NAME, KEY_TYPE, KisP, KHELPER)
//%DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, UInt32, uint32_t, KHELPER)
//%DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, Int32, int32_t, KHELPER)
//%DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, UInt64, uint64_t, KHELPER)
//%DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, Int64, int64_t, KHELPER)
//%DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, Bool, BOOL, KHELPER)
//%DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, Float, float, KHELPER)
//%DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, Double, double, KHELPER)
//%DICTIONARY_KEY_TO_ENUM_IMPL(KEY_NAME, KEY_TYPE, KisP, Enum, int32_t, KHELPER)

//%PDDM-DEFINE DICTIONARY_KEY_TO_POD_IMPL(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER)
//%DICTIONARY_COMMON_IMPL(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, POD, VALUE_NAME, value)

//%PDDM-DEFINE DICTIONARY_POD_KEY_TO_OBJECT_IMPL(KEY_NAME, KEY_TYPE, VALUE_NAME, VALUE_TYPE)
//%DICTIONARY_COMMON_IMPL(KEY_NAME, KEY_TYPE, , VALUE_NAME, VALUE_TYPE, POD, OBJECT, Object, object)

//%PDDM-DEFINE DICTIONARY_COMMON_IMPL(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, VNAME, VNAME_VAR)
//%#pragma mark - KEY_NAME -> VALUE_NAME
//%
//%@implementation ACGPB##KEY_NAME##VALUE_NAME##Dictionary {
//% @package
//%  NSMutableDictionary *_dictionary;
//%}
//%
//%- (instancetype)init {
//%  return [self initWith##VNAME##s:NULL forKeys:NULL count:0];
//%}
//%
//%- (instancetype)initWith##VNAME##s:(const VALUE_TYPE [])##VNAME_VAR##s
//%                ##VNAME$S##  forKeys:(const KEY_TYPE##KisP$S##KisP [])keys
//%                ##VNAME$S##    count:(NSUInteger)count {
//%  self = [super init];
//%  if (self) {
//%    _dictionary = [[NSMutableDictionary alloc] init];
//%    if (count && VNAME_VAR##s && keys) {
//%      for (NSUInteger i = 0; i < count; ++i) {
//%DICTIONARY_VALIDATE_VALUE_##VHELPER(VNAME_VAR##s[i], ______)##DICTIONARY_VALIDATE_KEY_##KHELPER(keys[i], ______)        [_dictionary setObject:WRAPPED##VHELPER(VNAME_VAR##s[i]) forKey:WRAPPED##KHELPER(keys[i])];
//%      }
//%    }
//%  }
//%  return self;
//%}
//%
//%- (instancetype)initWithDictionary:(ACGPB##KEY_NAME##VALUE_NAME##Dictionary *)dictionary {
//%  self = [self initWith##VNAME##s:NULL forKeys:NULL count:0];
//%  if (self) {
//%    if (dictionary) {
//%      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
//%    }
//%  }
//%  return self;
//%}
//%
//%- (instancetype)initWithCapacity:(NSUInteger)numItems {
//%  #pragma unused(numItems)
//%  return [self initWith##VNAME##s:NULL forKeys:NULL count:0];
//%}
//%
//%DICTIONARY_IMMUTABLE_CORE(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, VNAME, VNAME_VAR, )
//%
//%VALUE_FOR_KEY_##VHELPER(KEY_TYPE##KisP$S##KisP, VALUE_NAME, VALUE_TYPE, KHELPER)
//%
//%DICTIONARY_MUTABLE_CORE(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, VNAME, VNAME_VAR, )
//%
//%@end
//%

//%PDDM-DEFINE DICTIONARY_KEY_TO_ENUM_IMPL(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER)
//%DICTIONARY_KEY_TO_ENUM_IMPL2(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, POD)
//%PDDM-DEFINE DICTIONARY_KEY_TO_ENUM_IMPL2(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER)
//%#pragma mark - KEY_NAME -> VALUE_NAME
//%
//%@implementation ACGPB##KEY_NAME##VALUE_NAME##Dictionary {
//% @package
//%  NSMutableDictionary *_dictionary;
//%  ACGPBEnumValidationFunc _validationFunc;
//%}
//%
//%@synthesize validationFunc = _validationFunc;
//%
//%- (instancetype)init {
//%  return [self initWithValidationFunction:NULL rawValues:NULL forKeys:NULL count:0];
//%}
//%
//%- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func {
//%  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
//%}
//%
//%- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func
//%                                 rawValues:(const VALUE_TYPE [])rawValues
//%                                   forKeys:(const KEY_TYPE##KisP$S##KisP [])keys
//%                                     count:(NSUInteger)count {
//%  self = [super init];
//%  if (self) {
//%    _dictionary = [[NSMutableDictionary alloc] init];
//%    _validationFunc = (func != NULL ? func : DictDefault_IsValidValue);
//%    if (count && rawValues && keys) {
//%      for (NSUInteger i = 0; i < count; ++i) {
//%DICTIONARY_VALIDATE_KEY_##KHELPER(keys[i], ______)        [_dictionary setObject:WRAPPED##VHELPER(rawValues[i]) forKey:WRAPPED##KHELPER(keys[i])];
//%      }
//%    }
//%  }
//%  return self;
//%}
//%
//%- (instancetype)initWithDictionary:(ACGPB##KEY_NAME##VALUE_NAME##Dictionary *)dictionary {
//%  self = [self initWithValidationFunction:dictionary.validationFunc
//%                                rawValues:NULL
//%                                  forKeys:NULL
//%                                    count:0];
//%  if (self) {
//%    if (dictionary) {
//%      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
//%    }
//%  }
//%  return self;
//%}
//%
//%- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func
//%                                  capacity:(NSUInteger)numItems {
//%  #pragma unused(numItems)
//%  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
//%}
//%
//%DICTIONARY_IMMUTABLE_CORE(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, Value, value, Raw)
//%
//%- (BOOL)getEnum:(VALUE_TYPE *)value forKey:(KEY_TYPE##KisP$S##KisP)key {
//%  NSNumber *wrapped = [_dictionary objectForKey:WRAPPED##KHELPER(key)];
//%  if (wrapped && value) {
//%    VALUE_TYPE result = UNWRAP##VALUE_NAME(wrapped);
//%    if (!_validationFunc(result)) {
//%      result = kACGPBUnrecognizedEnumeratorValue;
//%    }
//%    *value = result;
//%  }
//%  return (wrapped != NULL);
//%}
//%
//%- (BOOL)getRawValue:(VALUE_TYPE *)rawValue forKey:(KEY_TYPE##KisP$S##KisP)key {
//%  NSNumber *wrapped = [_dictionary objectForKey:WRAPPED##KHELPER(key)];
//%  if (wrapped && rawValue) {
//%    *rawValue = UNWRAP##VALUE_NAME(wrapped);
//%  }
//%  return (wrapped != NULL);
//%}
//%
//%- (void)enumerateKeysAndEnumsUsingBlock:
//%    (void (NS_NOESCAPE ^)(KEY_TYPE KisP##key, VALUE_TYPE value, BOOL *stop))block {
//%  ACGPBEnumValidationFunc func = _validationFunc;
//%  BOOL stop = NO;
//%  NSEnumerator *keys = [_dictionary keyEnumerator];
//%  ENUM_TYPE##KHELPER(KEY_TYPE)##aKey;
//%  while ((aKey = [keys nextObject])) {
//%    ENUM_TYPE##VHELPER(VALUE_TYPE)##aValue = _dictionary[aKey];
//%      VALUE_TYPE unwrapped = UNWRAP##VALUE_NAME(aValue);
//%      if (!func(unwrapped)) {
//%        unwrapped = kACGPBUnrecognizedEnumeratorValue;
//%      }
//%    block(UNWRAP##KEY_NAME(aKey), unwrapped, &stop);
//%    if (stop) {
//%      break;
//%    }
//%  }
//%}
//%
//%DICTIONARY_MUTABLE_CORE2(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, Value, Enum, value, Raw)
//%
//%- (void)setEnum:(VALUE_TYPE)value forKey:(KEY_TYPE##KisP$S##KisP)key {
//%DICTIONARY_VALIDATE_KEY_##KHELPER(key, )  if (!_validationFunc(value)) {
//%    [NSException raise:NSInvalidArgumentException
//%                format:@"ACGPB##KEY_NAME##VALUE_NAME##Dictionary: Attempt to set an unknown enum value (%d)",
//%                       value];
//%  }
//%
//%  [_dictionary setObject:WRAPPED##VHELPER(value) forKey:WRAPPED##KHELPER(key)];
//%  if (_autocreator) {
//%    ACGPBAutocreatedDictionaryModified(_autocreator, self);
//%  }
//%}
//%
//%@end
//%

//%PDDM-DEFINE DICTIONARY_IMMUTABLE_CORE(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, VNAME, VNAME_VAR, ACCESSOR_NAME)
//%- (void)dealloc {
//%  NSAssert(!_autocreator,
//%           @"%@: Autocreator must be cleared before release, autocreator: %@",
//%           [self class], _autocreator);
//%  [_dictionary release];
//%  [super dealloc];
//%}
//%
//%- (instancetype)copyWithZone:(NSZone *)zone {
//%  return [[ACGPB##KEY_NAME##VALUE_NAME##Dictionary allocWithZone:zone] initWithDictionary:self];
//%}
//%
//%- (BOOL)isEqual:(id)other {
//%  if (self == other) {
//%    return YES;
//%  }
//%  if (![other isKindOfClass:[ACGPB##KEY_NAME##VALUE_NAME##Dictionary class]]) {
//%    return NO;
//%  }
//%  ACGPB##KEY_NAME##VALUE_NAME##Dictionary *otherDictionary = other;
//%  return [_dictionary isEqual:otherDictionary->_dictionary];
//%}
//%
//%- (NSUInteger)hash {
//%  return _dictionary.count;
//%}
//%
//%- (NSString *)description {
//%  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
//%}
//%
//%- (NSUInteger)count {
//%  return _dictionary.count;
//%}
//%
//%- (void)enumerateKeysAnd##ACCESSOR_NAME##VNAME##sUsingBlock:
//%    (void (NS_NOESCAPE ^)(KEY_TYPE KisP##key, VALUE_TYPE VNAME_VAR, BOOL *stop))block {
//%  BOOL stop = NO;
//%  NSDictionary *internal = _dictionary;
//%  NSEnumerator *keys = [internal keyEnumerator];
//%  ENUM_TYPE##KHELPER(KEY_TYPE)##aKey;
//%  while ((aKey = [keys nextObject])) {
//%    ENUM_TYPE##VHELPER(VALUE_TYPE)##a##VNAME_VAR$u = internal[aKey];
//%    block(UNWRAP##KEY_NAME(aKey), UNWRAP##VALUE_NAME(a##VNAME_VAR$u), &stop);
//%    if (stop) {
//%      break;
//%    }
//%  }
//%}
//%
//%EXTRA_METHODS_##VHELPER(KEY_NAME, VALUE_NAME)- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
//%  NSDictionary *internal = _dictionary;
//%  NSUInteger count = internal.count;
//%  if (count == 0) {
//%    return 0;
//%  }
//%
//%  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
//%  ACGPBDataType keyDataType = field.mapKeyDataType;
//%  size_t result = 0;
//%  NSEnumerator *keys = [internal keyEnumerator];
//%  ENUM_TYPE##KHELPER(KEY_TYPE)##aKey;
//%  while ((aKey = [keys nextObject])) {
//%    ENUM_TYPE##VHELPER(VALUE_TYPE)##a##VNAME_VAR$u = internal[aKey];
//%    size_t msgSize = ComputeDict##KEY_NAME##FieldSize(UNWRAP##KEY_NAME(aKey), kMapKeyFieldNumber, keyDataType);
//%    msgSize += ComputeDict##VALUE_NAME##FieldSize(UNWRAP##VALUE_NAME(a##VNAME_VAR$u), kMapValueFieldNumber, valueDataType);
//%    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
//%  }
//%  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
//%  result += tagSize * count;
//%  return result;
//%}
//%
//%- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
//%                         asField:(ACGPBFieldDescriptor *)field {
//%  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
//%  ACGPBDataType keyDataType = field.mapKeyDataType;
//%  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
//%  NSDictionary *internal = _dictionary;
//%  NSEnumerator *keys = [internal keyEnumerator];
//%  ENUM_TYPE##KHELPER(KEY_TYPE)##aKey;
//%  while ((aKey = [keys nextObject])) {
//%    ENUM_TYPE##VHELPER(VALUE_TYPE)##a##VNAME_VAR$u = internal[aKey];
//%    [outputStream writeInt32NoTag:tag];
//%    // Write the size of the message.
//%    KEY_TYPE KisP##unwrappedKey = UNWRAP##KEY_NAME(aKey);
//%    VALUE_TYPE unwrappedValue = UNWRAP##VALUE_NAME(a##VNAME_VAR$u);
//%    size_t msgSize = ComputeDict##KEY_NAME##FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
//%    msgSize += ComputeDict##VALUE_NAME##FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
//%    [outputStream writeInt32NoTag:(int32_t)msgSize];
//%    // Write the fields.
//%    WriteDict##KEY_NAME##Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
//%    WriteDict##VALUE_NAME##Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
//%  }
//%}
//%
//%SERIAL_DATA_FOR_ENTRY_##VHELPER(KEY_NAME, VALUE_NAME)- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
//%     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
//%  [_dictionary setObject:WRAPPED##VHELPER(value->##ACGPBVALUE_##VHELPER(VALUE_NAME)##) forKey:WRAPPED##KHELPER(key->value##KEY_NAME)];
//%}
//%
//%- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
//%  [self enumerateKeysAnd##ACCESSOR_NAME##VNAME##sUsingBlock:^(KEY_TYPE KisP##key, VALUE_TYPE VNAME_VAR, BOOL *stop) {
//%      #pragma unused(stop)
//%      block(TEXT_FORMAT_OBJ##KEY_NAME(key), TEXT_FORMAT_OBJ##VALUE_NAME(VNAME_VAR));
//%  }];
//%}
//%PDDM-DEFINE DICTIONARY_MUTABLE_CORE(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, VNAME, VNAME_VAR, ACCESSOR_NAME)
//%DICTIONARY_MUTABLE_CORE2(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, VNAME, VNAME, VNAME_VAR, ACCESSOR_NAME)
//%PDDM-DEFINE DICTIONARY_MUTABLE_CORE2(KEY_NAME, KEY_TYPE, KisP, VALUE_NAME, VALUE_TYPE, KHELPER, VHELPER, VNAME, VNAME_REMOVE, VNAME_VAR, ACCESSOR_NAME)
//%- (void)add##ACCESSOR_NAME##EntriesFromDictionary:(ACGPB##KEY_NAME##VALUE_NAME##Dictionary *)otherDictionary {
//%  if (otherDictionary) {
//%    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
//%    if (_autocreator) {
//%      ACGPBAutocreatedDictionaryModified(_autocreator, self);
//%    }
//%  }
//%}
//%
//%- (void)set##ACCESSOR_NAME##VNAME##:(VALUE_TYPE)VNAME_VAR forKey:(KEY_TYPE##KisP$S##KisP)key {
//%DICTIONARY_VALIDATE_VALUE_##VHELPER(VNAME_VAR, )##DICTIONARY_VALIDATE_KEY_##KHELPER(key, )  [_dictionary setObject:WRAPPED##VHELPER(VNAME_VAR) forKey:WRAPPED##KHELPER(key)];
//%  if (_autocreator) {
//%    ACGPBAutocreatedDictionaryModified(_autocreator, self);
//%  }
//%}
//%
//%- (void)remove##VNAME_REMOVE##ForKey:(KEY_TYPE##KisP$S##KisP)aKey {
//%  [_dictionary removeObjectForKey:WRAPPED##KHELPER(aKey)];
//%}
//%
//%- (void)removeAll {
//%  [_dictionary removeAllObjects];
//%}

//
// Custom Generation for Bool keys
//

//%PDDM-DEFINE DICTIONARY_BOOL_KEY_TO_POD_IMPL(VALUE_NAME, VALUE_TYPE)
//%DICTIONARY_BOOL_KEY_TO_VALUE_IMPL(VALUE_NAME, VALUE_TYPE, POD, VALUE_NAME, value)
//%PDDM-DEFINE DICTIONARY_BOOL_KEY_TO_OBJECT_IMPL(VALUE_NAME, VALUE_TYPE)
//%DICTIONARY_BOOL_KEY_TO_VALUE_IMPL(VALUE_NAME, VALUE_TYPE, OBJECT, Object, object)

//%PDDM-DEFINE DICTIONARY_BOOL_KEY_TO_VALUE_IMPL(VALUE_NAME, VALUE_TYPE, HELPER, VNAME, VNAME_VAR)
//%#pragma mark - Bool -> VALUE_NAME
//%
//%@implementation ACGPBBool##VALUE_NAME##Dictionary {
//% @package
//%  VALUE_TYPE _values[2];
//%BOOL_DICT_HAS_STORAGE_##HELPER()}
//%
//%- (instancetype)init {
//%  return [self initWith##VNAME##s:NULL forKeys:NULL count:0];
//%}
//%
//%BOOL_DICT_INITS_##HELPER(VALUE_NAME, VALUE_TYPE)
//%
//%- (instancetype)initWithCapacity:(NSUInteger)numItems {
//%  #pragma unused(numItems)
//%  return [self initWith##VNAME##s:NULL forKeys:NULL count:0];
//%}
//%
//%BOOL_DICT_DEALLOC##HELPER()
//%
//%- (instancetype)copyWithZone:(NSZone *)zone {
//%  return [[ACGPBBool##VALUE_NAME##Dictionary allocWithZone:zone] initWithDictionary:self];
//%}
//%
//%- (BOOL)isEqual:(id)other {
//%  if (self == other) {
//%    return YES;
//%  }
//%  if (![other isKindOfClass:[ACGPBBool##VALUE_NAME##Dictionary class]]) {
//%    return NO;
//%  }
//%  ACGPBBool##VALUE_NAME##Dictionary *otherDictionary = other;
//%  if ((BOOL_DICT_W_HAS##HELPER(0, ) != BOOL_DICT_W_HAS##HELPER(0, otherDictionary->)) ||
//%      (BOOL_DICT_W_HAS##HELPER(1, ) != BOOL_DICT_W_HAS##HELPER(1, otherDictionary->))) {
//%    return NO;
//%  }
//%  if ((BOOL_DICT_W_HAS##HELPER(0, ) && (NEQ_##HELPER(_values[0], otherDictionary->_values[0]))) ||
//%      (BOOL_DICT_W_HAS##HELPER(1, ) && (NEQ_##HELPER(_values[1], otherDictionary->_values[1])))) {
//%    return NO;
//%  }
//%  return YES;
//%}
//%
//%- (NSUInteger)hash {
//%  return (BOOL_DICT_W_HAS##HELPER(0, ) ? 1 : 0) + (BOOL_DICT_W_HAS##HELPER(1, ) ? 1 : 0);
//%}
//%
//%- (NSString *)description {
//%  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
//%  if (BOOL_DICT_W_HAS##HELPER(0, )) {
//%    [result appendFormat:@"NO: STR_FORMAT_##HELPER(VALUE_NAME)", _values[0]];
//%  }
//%  if (BOOL_DICT_W_HAS##HELPER(1, )) {
//%    [result appendFormat:@"YES: STR_FORMAT_##HELPER(VALUE_NAME)", _values[1]];
//%  }
//%  [result appendString:@" }"];
//%  return result;
//%}
//%
//%- (NSUInteger)count {
//%  return (BOOL_DICT_W_HAS##HELPER(0, ) ? 1 : 0) + (BOOL_DICT_W_HAS##HELPER(1, ) ? 1 : 0);
//%}
//%
//%BOOL_VALUE_FOR_KEY_##HELPER(VALUE_NAME, VALUE_TYPE)
//%
//%BOOL_SET_ACGPBVALUE_FOR_KEY_##HELPER(VALUE_NAME, VALUE_TYPE, VisP)
//%
//%- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
//%  if (BOOL_DICT_HAS##HELPER(0, )) {
//%    block(@"false", TEXT_FORMAT_OBJ##VALUE_NAME(_values[0]));
//%  }
//%  if (BOOL_DICT_W_HAS##HELPER(1, )) {
//%    block(@"true", TEXT_FORMAT_OBJ##VALUE_NAME(_values[1]));
//%  }
//%}
//%
//%- (void)enumerateKeysAnd##VNAME##sUsingBlock:
//%    (void (NS_NOESCAPE ^)(BOOL key, VALUE_TYPE VNAME_VAR, BOOL *stop))block {
//%  BOOL stop = NO;
//%  if (BOOL_DICT_HAS##HELPER(0, )) {
//%    block(NO, _values[0], &stop);
//%  }
//%  if (!stop && BOOL_DICT_W_HAS##HELPER(1, )) {
//%    block(YES, _values[1], &stop);
//%  }
//%}
//%
//%BOOL_EXTRA_METHODS_##HELPER(Bool, VALUE_NAME)- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
//%  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
//%  NSUInteger count = 0;
//%  size_t result = 0;
//%  for (int i = 0; i < 2; ++i) {
//%    if (BOOL_DICT_HAS##HELPER(i, )) {
//%      ++count;
//%      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
//%      msgSize += ComputeDict##VALUE_NAME##FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
//%      result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
//%    }
//%  }
//%  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
//%  result += tagSize * count;
//%  return result;
//%}
//%
//%- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
//%                         asField:(ACGPBFieldDescriptor *)field {
//%  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
//%  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
//%  for (int i = 0; i < 2; ++i) {
//%    if (BOOL_DICT_HAS##HELPER(i, )) {
//%      // Write the tag.
//%      [outputStream writeInt32NoTag:tag];
//%      // Write the size of the message.
//%      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
//%      msgSize += ComputeDict##VALUE_NAME##FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
//%      [outputStream writeInt32NoTag:(int32_t)msgSize];
//%      // Write the fields.
//%      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
//%      WriteDict##VALUE_NAME##Field(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
//%    }
//%  }
//%}
//%
//%BOOL_DICT_MUTATIONS_##HELPER(VALUE_NAME, VALUE_TYPE)
//%
//%@end
//%


//
// Helpers for PODs
//

//%PDDM-DEFINE VALUE_FOR_KEY_POD(KEY_TYPE, VALUE_NAME, VALUE_TYPE, KHELPER)
//%- (BOOL)get##VALUE_NAME##:(nullable VALUE_TYPE *)value forKey:(KEY_TYPE)key {
//%  NSNumber *wrapped = [_dictionary objectForKey:WRAPPED##KHELPER(key)];
//%  if (wrapped && value) {
//%    *value = UNWRAP##VALUE_NAME(wrapped);
//%  }
//%  return (wrapped != NULL);
//%}
//%PDDM-DEFINE WRAPPEDPOD(VALUE)
//%@(VALUE)
//%PDDM-DEFINE UNWRAPUInt32(VALUE)
//%[VALUE unsignedIntValue]
//%PDDM-DEFINE UNWRAPInt32(VALUE)
//%[VALUE intValue]
//%PDDM-DEFINE UNWRAPUInt64(VALUE)
//%[VALUE unsignedLongLongValue]
//%PDDM-DEFINE UNWRAPInt64(VALUE)
//%[VALUE longLongValue]
//%PDDM-DEFINE UNWRAPBool(VALUE)
//%[VALUE boolValue]
//%PDDM-DEFINE UNWRAPFloat(VALUE)
//%[VALUE floatValue]
//%PDDM-DEFINE UNWRAPDouble(VALUE)
//%[VALUE doubleValue]
//%PDDM-DEFINE UNWRAPEnum(VALUE)
//%[VALUE intValue]
//%PDDM-DEFINE TEXT_FORMAT_OBJUInt32(VALUE)
//%[NSString stringWithFormat:@"%u", VALUE]
//%PDDM-DEFINE TEXT_FORMAT_OBJInt32(VALUE)
//%[NSString stringWithFormat:@"%d", VALUE]
//%PDDM-DEFINE TEXT_FORMAT_OBJUInt64(VALUE)
//%[NSString stringWithFormat:@"%llu", VALUE]
//%PDDM-DEFINE TEXT_FORMAT_OBJInt64(VALUE)
//%[NSString stringWithFormat:@"%lld", VALUE]
//%PDDM-DEFINE TEXT_FORMAT_OBJBool(VALUE)
//%(VALUE ? @"true" : @"false")
//%PDDM-DEFINE TEXT_FORMAT_OBJFloat(VALUE)
//%[NSString stringWithFormat:@"%.*g", FLT_DIG, VALUE]
//%PDDM-DEFINE TEXT_FORMAT_OBJDouble(VALUE)
//%[NSString stringWithFormat:@"%.*lg", DBL_DIG, VALUE]
//%PDDM-DEFINE TEXT_FORMAT_OBJEnum(VALUE)
//%@(VALUE)
//%PDDM-DEFINE ENUM_TYPEPOD(TYPE)
//%NSNumber *
//%PDDM-DEFINE NEQ_POD(VAL1, VAL2)
//%VAL1 != VAL2
//%PDDM-DEFINE EXTRA_METHODS_POD(KEY_NAME, VALUE_NAME)
// Empty
//%PDDM-DEFINE BOOL_EXTRA_METHODS_POD(KEY_NAME, VALUE_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD(KEY_NAME, VALUE_NAME)
//%SERIAL_DATA_FOR_ENTRY_POD_##VALUE_NAME(KEY_NAME)
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_UInt32(KEY_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_Int32(KEY_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_UInt64(KEY_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_Int64(KEY_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_Bool(KEY_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_Float(KEY_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_Double(KEY_NAME)
// Empty
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_POD_Enum(KEY_NAME)
//%- (NSData *)serializedDataForUnknownValue:(int32_t)value
//%                                   forKey:(ACGPBGenericValue *)key
//%                              keyDataType:(ACGPBDataType)keyDataType {
//%  size_t msgSize = ComputeDict##KEY_NAME##FieldSize(key->value##KEY_NAME, kMapKeyFieldNumber, keyDataType);
//%  msgSize += ComputeDictEnumFieldSize(value, kMapValueFieldNumber, ACGPBDataTypeEnum);
//%  NSMutableData *data = [NSMutableData dataWithLength:msgSize];
//%  ACGPBCodedOutputStream *outputStream = [[ACGPBCodedOutputStream alloc] initWithData:data];
//%  WriteDict##KEY_NAME##Field(outputStream, key->value##KEY_NAME, kMapKeyFieldNumber, keyDataType);
//%  WriteDictEnumField(outputStream, value, kMapValueFieldNumber, ACGPBDataTypeEnum);
//%  [outputStream release];
//%  return data;
//%}
//%
//%PDDM-DEFINE ACGPBVALUE_POD(VALUE_NAME)
//%value##VALUE_NAME
//%PDDM-DEFINE DICTIONARY_VALIDATE_VALUE_POD(VALUE_NAME, EXTRA_INDENT)
// Empty
//%PDDM-DEFINE DICTIONARY_VALIDATE_KEY_POD(KEY_NAME, EXTRA_INDENT)
// Empty

//%PDDM-DEFINE BOOL_DICT_HAS_STORAGE_POD()
//%  BOOL _valueSet[2];
//%
//%PDDM-DEFINE BOOL_DICT_INITS_POD(VALUE_NAME, VALUE_TYPE)
//%- (instancetype)initWith##VALUE_NAME##s:(const VALUE_TYPE [])values
//%                 ##VALUE_NAME$S## forKeys:(const BOOL [])keys
//%                 ##VALUE_NAME$S##   count:(NSUInteger)count {
//%  self = [super init];
//%  if (self) {
//%    for (NSUInteger i = 0; i < count; ++i) {
//%      int idx = keys[i] ? 1 : 0;
//%      _values[idx] = values[i];
//%      _valueSet[idx] = YES;
//%    }
//%  }
//%  return self;
//%}
//%
//%- (instancetype)initWithDictionary:(ACGPBBool##VALUE_NAME##Dictionary *)dictionary {
//%  self = [self initWith##VALUE_NAME##s:NULL forKeys:NULL count:0];
//%  if (self) {
//%    if (dictionary) {
//%      for (int i = 0; i < 2; ++i) {
//%        if (dictionary->_valueSet[i]) {
//%          _values[i] = dictionary->_values[i];
//%          _valueSet[i] = YES;
//%        }
//%      }
//%    }
//%  }
//%  return self;
//%}
//%PDDM-DEFINE BOOL_DICT_DEALLOCPOD()
//%#if !defined(NS_BLOCK_ASSERTIONS)
//%- (void)dealloc {
//%  NSAssert(!_autocreator,
//%           @"%@: Autocreator must be cleared before release, autocreator: %@",
//%           [self class], _autocreator);
//%  [super dealloc];
//%}
//%#endif  // !defined(NS_BLOCK_ASSERTIONS)
//%PDDM-DEFINE BOOL_DICT_W_HASPOD(IDX, REF)
//%BOOL_DICT_HASPOD(IDX, REF)
//%PDDM-DEFINE BOOL_DICT_HASPOD(IDX, REF)
//%REF##_valueSet[IDX]
//%PDDM-DEFINE BOOL_VALUE_FOR_KEY_POD(VALUE_NAME, VALUE_TYPE)
//%- (BOOL)get##VALUE_NAME##:(VALUE_TYPE *)value forKey:(BOOL)key {
//%  int idx = (key ? 1 : 0);
//%  if (_valueSet[idx]) {
//%    if (value) {
//%      *value = _values[idx];
//%    }
//%    return YES;
//%  }
//%  return NO;
//%}
//%PDDM-DEFINE BOOL_SET_ACGPBVALUE_FOR_KEY_POD(VALUE_NAME, VALUE_TYPE, VisP)
//%- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
//%     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
//%  int idx = (key->valueBool ? 1 : 0);
//%  _values[idx] = value->value##VALUE_NAME;
//%  _valueSet[idx] = YES;
//%}
//%PDDM-DEFINE BOOL_DICT_MUTATIONS_POD(VALUE_NAME, VALUE_TYPE)
//%- (void)addEntriesFromDictionary:(ACGPBBool##VALUE_NAME##Dictionary *)otherDictionary {
//%  if (otherDictionary) {
//%    for (int i = 0; i < 2; ++i) {
//%      if (otherDictionary->_valueSet[i]) {
//%        _valueSet[i] = YES;
//%        _values[i] = otherDictionary->_values[i];
//%      }
//%    }
//%    if (_autocreator) {
//%      ACGPBAutocreatedDictionaryModified(_autocreator, self);
//%    }
//%  }
//%}
//%
//%- (void)set##VALUE_NAME:(VALUE_TYPE)value forKey:(BOOL)key {
//%  int idx = (key ? 1 : 0);
//%  _values[idx] = value;
//%  _valueSet[idx] = YES;
//%  if (_autocreator) {
//%    ACGPBAutocreatedDictionaryModified(_autocreator, self);
//%  }
//%}
//%
//%- (void)remove##VALUE_NAME##ForKey:(BOOL)aKey {
//%  _valueSet[aKey ? 1 : 0] = NO;
//%}
//%
//%- (void)removeAll {
//%  _valueSet[0] = NO;
//%  _valueSet[1] = NO;
//%}
//%PDDM-DEFINE STR_FORMAT_POD(VALUE_NAME)
//%STR_FORMAT_##VALUE_NAME()
//%PDDM-DEFINE STR_FORMAT_UInt32()
//%%u
//%PDDM-DEFINE STR_FORMAT_Int32()
//%%d
//%PDDM-DEFINE STR_FORMAT_UInt64()
//%%llu
//%PDDM-DEFINE STR_FORMAT_Int64()
//%%lld
//%PDDM-DEFINE STR_FORMAT_Bool()
//%%d
//%PDDM-DEFINE STR_FORMAT_Float()
//%%f
//%PDDM-DEFINE STR_FORMAT_Double()
//%%lf

//
// Helpers for Objects
//

//%PDDM-DEFINE VALUE_FOR_KEY_OBJECT(KEY_TYPE, VALUE_NAME, VALUE_TYPE, KHELPER)
//%- (VALUE_TYPE)objectForKey:(KEY_TYPE)key {
//%  VALUE_TYPE result = [_dictionary objectForKey:WRAPPED##KHELPER(key)];
//%  return result;
//%}
//%PDDM-DEFINE WRAPPEDOBJECT(VALUE)
//%VALUE
//%PDDM-DEFINE UNWRAPString(VALUE)
//%VALUE
//%PDDM-DEFINE UNWRAPObject(VALUE)
//%VALUE
//%PDDM-DEFINE TEXT_FORMAT_OBJString(VALUE)
//%VALUE
//%PDDM-DEFINE TEXT_FORMAT_OBJObject(VALUE)
//%VALUE
//%PDDM-DEFINE ENUM_TYPEOBJECT(TYPE)
//%ENUM_TYPEOBJECT_##TYPE()
//%PDDM-DEFINE ENUM_TYPEOBJECT_NSString()
//%NSString *
//%PDDM-DEFINE ENUM_TYPEOBJECT_id()
//%id ##
//%PDDM-DEFINE NEQ_OBJECT(VAL1, VAL2)
//%![VAL1 isEqual:VAL2]
//%PDDM-DEFINE EXTRA_METHODS_OBJECT(KEY_NAME, VALUE_NAME)
//%- (BOOL)isInitialized {
//%  for (ACGPBMessage *msg in [_dictionary objectEnumerator]) {
//%    if (!msg.initialized) {
//%      return NO;
//%    }
//%  }
//%  return YES;
//%}
//%
//%- (instancetype)deepCopyWithZone:(NSZone *)zone {
//%  ACGPB##KEY_NAME##VALUE_NAME##Dictionary *newDict =
//%      [[ACGPB##KEY_NAME##VALUE_NAME##Dictionary alloc] init];
//%  NSEnumerator *keys = [_dictionary keyEnumerator];
//%  id aKey;
//%  NSMutableDictionary *internalDict = newDict->_dictionary;
//%  while ((aKey = [keys nextObject])) {
//%    ACGPBMessage *msg = _dictionary[aKey];
//%    ACGPBMessage *copiedMsg = [msg copyWithZone:zone];
//%    [internalDict setObject:copiedMsg forKey:aKey];
//%    [copiedMsg release];
//%  }
//%  return newDict;
//%}
//%
//%
//%PDDM-DEFINE BOOL_EXTRA_METHODS_OBJECT(KEY_NAME, VALUE_NAME)
//%- (BOOL)isInitialized {
//%  if (_values[0] && ![_values[0] isInitialized]) {
//%    return NO;
//%  }
//%  if (_values[1] && ![_values[1] isInitialized]) {
//%    return NO;
//%  }
//%  return YES;
//%}
//%
//%- (instancetype)deepCopyWithZone:(NSZone *)zone {
//%  ACGPB##KEY_NAME##VALUE_NAME##Dictionary *newDict =
//%      [[ACGPB##KEY_NAME##VALUE_NAME##Dictionary alloc] init];
//%  for (int i = 0; i < 2; ++i) {
//%    if (_values[i] != nil) {
//%      newDict->_values[i] = [_values[i] copyWithZone:zone];
//%    }
//%  }
//%  return newDict;
//%}
//%
//%
//%PDDM-DEFINE SERIAL_DATA_FOR_ENTRY_OBJECT(KEY_NAME, VALUE_NAME)
// Empty
//%PDDM-DEFINE ACGPBVALUE_OBJECT(VALUE_NAME)
//%valueString
//%PDDM-DEFINE DICTIONARY_VALIDATE_VALUE_OBJECT(VALUE_NAME, EXTRA_INDENT)
//%##EXTRA_INDENT$S##  if (!##VALUE_NAME) {
//%##EXTRA_INDENT$S##    [NSException raise:NSInvalidArgumentException
//%##EXTRA_INDENT$S##                format:@"Attempting to add nil object to a Dictionary"];
//%##EXTRA_INDENT$S##  }
//%
//%PDDM-DEFINE DICTIONARY_VALIDATE_KEY_OBJECT(KEY_NAME, EXTRA_INDENT)
//%##EXTRA_INDENT$S##  if (!##KEY_NAME) {
//%##EXTRA_INDENT$S##    [NSException raise:NSInvalidArgumentException
//%##EXTRA_INDENT$S##                format:@"Attempting to add nil key to a Dictionary"];
//%##EXTRA_INDENT$S##  }
//%

//%PDDM-DEFINE BOOL_DICT_HAS_STORAGE_OBJECT()
// Empty
//%PDDM-DEFINE BOOL_DICT_INITS_OBJECT(VALUE_NAME, VALUE_TYPE)
//%- (instancetype)initWithObjects:(const VALUE_TYPE [])objects
//%                        forKeys:(const BOOL [])keys
//%                          count:(NSUInteger)count {
//%  self = [super init];
//%  if (self) {
//%    for (NSUInteger i = 0; i < count; ++i) {
//%      if (!objects[i]) {
//%        [NSException raise:NSInvalidArgumentException
//%                    format:@"Attempting to add nil object to a Dictionary"];
//%      }
//%      int idx = keys[i] ? 1 : 0;
//%      [_values[idx] release];
//%      _values[idx] = (VALUE_TYPE)[objects[i] retain];
//%    }
//%  }
//%  return self;
//%}
//%
//%- (instancetype)initWithDictionary:(ACGPBBool##VALUE_NAME##Dictionary *)dictionary {
//%  self = [self initWithObjects:NULL forKeys:NULL count:0];
//%  if (self) {
//%    if (dictionary) {
//%      _values[0] = [dictionary->_values[0] retain];
//%      _values[1] = [dictionary->_values[1] retain];
//%    }
//%  }
//%  return self;
//%}
//%PDDM-DEFINE BOOL_DICT_DEALLOCOBJECT()
//%- (void)dealloc {
//%  NSAssert(!_autocreator,
//%           @"%@: Autocreator must be cleared before release, autocreator: %@",
//%           [self class], _autocreator);
//%  [_values[0] release];
//%  [_values[1] release];
//%  [super dealloc];
//%}
//%PDDM-DEFINE BOOL_DICT_W_HASOBJECT(IDX, REF)
//%(BOOL_DICT_HASOBJECT(IDX, REF))
//%PDDM-DEFINE BOOL_DICT_HASOBJECT(IDX, REF)
//%REF##_values[IDX] != nil
//%PDDM-DEFINE BOOL_VALUE_FOR_KEY_OBJECT(VALUE_NAME, VALUE_TYPE)
//%- (VALUE_TYPE)objectForKey:(BOOL)key {
//%  return _values[key ? 1 : 0];
//%}
//%PDDM-DEFINE BOOL_SET_ACGPBVALUE_FOR_KEY_OBJECT(VALUE_NAME, VALUE_TYPE, VisP)
//%- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
//%     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
//%  int idx = (key->valueBool ? 1 : 0);
//%  [_values[idx] release];
//%  _values[idx] = [value->valueString retain];
//%}

//%PDDM-DEFINE BOOL_DICT_MUTATIONS_OBJECT(VALUE_NAME, VALUE_TYPE)
//%- (void)addEntriesFromDictionary:(ACGPBBool##VALUE_NAME##Dictionary *)otherDictionary {
//%  if (otherDictionary) {
//%    for (int i = 0; i < 2; ++i) {
//%      if (otherDictionary->_values[i] != nil) {
//%        [_values[i] release];
//%        _values[i] = [otherDictionary->_values[i] retain];
//%      }
//%    }
//%    if (_autocreator) {
//%      ACGPBAutocreatedDictionaryModified(_autocreator, self);
//%    }
//%  }
//%}
//%
//%- (void)setObject:(VALUE_TYPE)object forKey:(BOOL)key {
//%  if (!object) {
//%    [NSException raise:NSInvalidArgumentException
//%                format:@"Attempting to add nil object to a Dictionary"];
//%  }
//%  int idx = (key ? 1 : 0);
//%  [_values[idx] release];
//%  _values[idx] = [object retain];
//%  if (_autocreator) {
//%    ACGPBAutocreatedDictionaryModified(_autocreator, self);
//%  }
//%}
//%
//%- (void)removeObjectForKey:(BOOL)aKey {
//%  int idx = (aKey ? 1 : 0);
//%  [_values[idx] release];
//%  _values[idx] = nil;
//%}
//%
//%- (void)removeAll {
//%  for (int i = 0; i < 2; ++i) {
//%    [_values[i] release];
//%    _values[i] = nil;
//%  }
//%}
//%PDDM-DEFINE STR_FORMAT_OBJECT(VALUE_NAME)
//%%@


//%PDDM-EXPAND DICTIONARY_IMPL_FOR_POD_KEY(UInt32, uint32_t)
// This block of code is generated, do not edit it directly.
// clang-format off

#pragma mark - UInt32 -> UInt32

@implementation ACGPBUInt32UInt32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt32s:(const uint32_t [])values
                        forKeys:(const uint32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt32UInt32Dictionary *)dictionary {
  self = [self initWithUInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt32UInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt32UInt32Dictionary class]]) {
    return NO;
  }
  ACGPBUInt32UInt32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt32sUsingBlock:
    (void (NS_NOESCAPE ^)(uint32_t key, uint32_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedIntValue], [aValue unsignedIntValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize([aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint32_t unwrappedKey = [aKey unsignedIntValue];
    uint32_t unwrappedValue = [aValue unsignedIntValue];
    size_t msgSize = ComputeDictUInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictUInt32Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt32) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt32sUsingBlock:^(uint32_t key, uint32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], [NSString stringWithFormat:@"%u", value]);
  }];
}

- (BOOL)getUInt32:(nullable uint32_t *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedIntValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBUInt32UInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt32:(uint32_t)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt32ForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt32 -> Int32

@implementation ACGPBUInt32Int32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt32s:(const int32_t [])values
                       forKeys:(const uint32_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt32Int32Dictionary *)dictionary {
  self = [self initWithInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt32Int32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt32Int32Dictionary class]]) {
    return NO;
  }
  ACGPBUInt32Int32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt32sUsingBlock:
    (void (NS_NOESCAPE ^)(uint32_t key, int32_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedIntValue], [aValue intValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint32_t unwrappedKey = [aKey unsignedIntValue];
    int32_t unwrappedValue = [aValue intValue];
    size_t msgSize = ComputeDictUInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictInt32Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt32) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt32sUsingBlock:^(uint32_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], [NSString stringWithFormat:@"%d", value]);
  }];
}

- (BOOL)getInt32:(nullable int32_t *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBUInt32Int32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt32:(int32_t)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt32ForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt32 -> UInt64

@implementation ACGPBUInt32UInt64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt64s:(const uint64_t [])values
                        forKeys:(const uint32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt32UInt64Dictionary *)dictionary {
  self = [self initWithUInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt32UInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt32UInt64Dictionary class]]) {
    return NO;
  }
  ACGPBUInt32UInt64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt64sUsingBlock:
    (void (NS_NOESCAPE ^)(uint32_t key, uint64_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedIntValue], [aValue unsignedLongLongValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize([aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint32_t unwrappedKey = [aKey unsignedIntValue];
    uint64_t unwrappedValue = [aValue unsignedLongLongValue];
    size_t msgSize = ComputeDictUInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictUInt64Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt64) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt64sUsingBlock:^(uint32_t key, uint64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], [NSString stringWithFormat:@"%llu", value]);
  }];
}

- (BOOL)getUInt64:(nullable uint64_t *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedLongLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBUInt32UInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt64:(uint64_t)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt64ForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt32 -> Int64

@implementation ACGPBUInt32Int64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt64s:(const int64_t [])values
                       forKeys:(const uint32_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt32Int64Dictionary *)dictionary {
  self = [self initWithInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt32Int64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt32Int64Dictionary class]]) {
    return NO;
  }
  ACGPBUInt32Int64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt64sUsingBlock:
    (void (NS_NOESCAPE ^)(uint32_t key, int64_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedIntValue], [aValue longLongValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize([aValue longLongValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint32_t unwrappedKey = [aKey unsignedIntValue];
    int64_t unwrappedValue = [aValue longLongValue];
    size_t msgSize = ComputeDictUInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictInt64Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt64) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt64sUsingBlock:^(uint32_t key, int64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], [NSString stringWithFormat:@"%lld", value]);
  }];
}

- (BOOL)getInt64:(nullable int64_t *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped longLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBUInt32Int64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt64:(int64_t)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt64ForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt32 -> Bool

@implementation ACGPBUInt32BoolDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (instancetype)initWithBools:(const BOOL [])values
                      forKeys:(const uint32_t [])keys
                        count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt32BoolDictionary *)dictionary {
  self = [self initWithBools:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt32BoolDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt32BoolDictionary class]]) {
    return NO;
  }
  ACGPBUInt32BoolDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndBoolsUsingBlock:
    (void (NS_NOESCAPE ^)(uint32_t key, BOOL value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedIntValue], [aValue boolValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize([aValue boolValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint32_t unwrappedKey = [aKey unsignedIntValue];
    BOOL unwrappedValue = [aValue boolValue];
    size_t msgSize = ComputeDictUInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictBoolField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueBool) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndBoolsUsingBlock:^(uint32_t key, BOOL value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], (value ? @"true" : @"false"));
  }];
}

- (BOOL)getBool:(nullable BOOL *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped boolValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBUInt32BoolDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setBool:(BOOL)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeBoolForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt32 -> Float

@implementation ACGPBUInt32FloatDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (instancetype)initWithFloats:(const float [])values
                       forKeys:(const uint32_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt32FloatDictionary *)dictionary {
  self = [self initWithFloats:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt32FloatDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt32FloatDictionary class]]) {
    return NO;
  }
  ACGPBUInt32FloatDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndFloatsUsingBlock:
    (void (NS_NOESCAPE ^)(uint32_t key, float value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedIntValue], [aValue floatValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize([aValue floatValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint32_t unwrappedKey = [aKey unsignedIntValue];
    float unwrappedValue = [aValue floatValue];
    size_t msgSize = ComputeDictUInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictFloatField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueFloat) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndFloatsUsingBlock:^(uint32_t key, float value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], [NSString stringWithFormat:@"%.*g", FLT_DIG, value]);
  }];
}

- (BOOL)getFloat:(nullable float *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped floatValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBUInt32FloatDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setFloat:(float)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeFloatForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt32 -> Double

@implementation ACGPBUInt32DoubleDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (instancetype)initWithDoubles:(const double [])values
                        forKeys:(const uint32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt32DoubleDictionary *)dictionary {
  self = [self initWithDoubles:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt32DoubleDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt32DoubleDictionary class]]) {
    return NO;
  }
  ACGPBUInt32DoubleDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndDoublesUsingBlock:
    (void (NS_NOESCAPE ^)(uint32_t key, double value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedIntValue], [aValue doubleValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize([aValue doubleValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint32_t unwrappedKey = [aKey unsignedIntValue];
    double unwrappedValue = [aValue doubleValue];
    size_t msgSize = ComputeDictUInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictDoubleField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueDouble) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndDoublesUsingBlock:^(uint32_t key, double value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], [NSString stringWithFormat:@"%.*lg", DBL_DIG, value]);
  }];
}

- (BOOL)getDouble:(nullable double *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped doubleValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBUInt32DoubleDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setDouble:(double)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeDoubleForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt32 -> Enum

@implementation ACGPBUInt32EnumDictionary {
 @package
  NSMutableDictionary *_dictionary;
  ACGPBEnumValidationFunc _validationFunc;
}

@synthesize validationFunc = _validationFunc;

- (instancetype)init {
  return [self initWithValidationFunction:NULL rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func {
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func
                                 rawValues:(const int32_t [])rawValues
                                   forKeys:(const uint32_t [])keys
                                     count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    _validationFunc = (func != NULL ? func : DictDefault_IsValidValue);
    if (count && rawValues && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(rawValues[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt32EnumDictionary *)dictionary {
  self = [self initWithValidationFunction:dictionary.validationFunc
                                rawValues:NULL
                                  forKeys:NULL
                                    count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func
                                  capacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt32EnumDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt32EnumDictionary class]]) {
    return NO;
  }
  ACGPBUInt32EnumDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndRawValuesUsingBlock:
    (void (NS_NOESCAPE ^)(uint32_t key, int32_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedIntValue], [aValue intValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint32_t unwrappedKey = [aKey unsignedIntValue];
    int32_t unwrappedValue = [aValue intValue];
    size_t msgSize = ComputeDictUInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictEnumField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(ACGPBGenericValue *)key
                              keyDataType:(ACGPBDataType)keyDataType {
  size_t msgSize = ComputeDictUInt32FieldSize(key->valueUInt32, kMapKeyFieldNumber, keyDataType);
  msgSize += ComputeDictEnumFieldSize(value, kMapValueFieldNumber, ACGPBDataTypeEnum);
  NSMutableData *data = [NSMutableData dataWithLength:msgSize];
  ACGPBCodedOutputStream *outputStream = [[ACGPBCodedOutputStream alloc] initWithData:data];
  WriteDictUInt32Field(outputStream, key->valueUInt32, kMapKeyFieldNumber, keyDataType);
  WriteDictEnumField(outputStream, value, kMapValueFieldNumber, ACGPBDataTypeEnum);
  [outputStream release];
  return data;
}
- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueEnum) forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndRawValuesUsingBlock:^(uint32_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], @(value));
  }];
}

- (BOOL)getEnum:(int32_t *)value forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    int32_t result = [wrapped intValue];
    if (!_validationFunc(result)) {
      result = kACGPBUnrecognizedEnumeratorValue;
    }
    *value = result;
  }
  return (wrapped != NULL);
}

- (BOOL)getRawValue:(int32_t *)rawValue forKey:(uint32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && rawValue) {
    *rawValue = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)enumerateKeysAndEnumsUsingBlock:
    (void (NS_NOESCAPE ^)(uint32_t key, int32_t value, BOOL *stop))block {
  ACGPBEnumValidationFunc func = _validationFunc;
  BOOL stop = NO;
  NSEnumerator *keys = [_dictionary keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = _dictionary[aKey];
      int32_t unwrapped = [aValue intValue];
      if (!func(unwrapped)) {
        unwrapped = kACGPBUnrecognizedEnumeratorValue;
      }
    block([aKey unsignedIntValue], unwrapped, &stop);
    if (stop) {
      break;
    }
  }
}

- (void)addRawEntriesFromDictionary:(ACGPBUInt32EnumDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setRawValue:(int32_t)value forKey:(uint32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeEnumForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

- (void)setEnum:(int32_t)value forKey:(uint32_t)key {
  if (!_validationFunc(value)) {
    [NSException raise:NSInvalidArgumentException
                format:@"ACGPBUInt32EnumDictionary: Attempt to set an unknown enum value (%d)",
                       value];
  }

  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

@end

#pragma mark - UInt32 -> Object

@implementation ACGPBUInt32ObjectDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (instancetype)initWithObjects:(const id [])objects
                        forKeys:(const uint32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && objects && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!objects[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil object to a Dictionary"];
        }
        [_dictionary setObject:objects[i] forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt32ObjectDictionary *)dictionary {
  self = [self initWithObjects:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt32ObjectDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt32ObjectDictionary class]]) {
    return NO;
  }
  ACGPBUInt32ObjectDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndObjectsUsingBlock:
    (void (NS_NOESCAPE ^)(uint32_t key, id object, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    id aObject = internal[aKey];
    block([aKey unsignedIntValue], aObject, &stop);
    if (stop) {
      break;
    }
  }
}

- (BOOL)isInitialized {
  for (ACGPBMessage *msg in [_dictionary objectEnumerator]) {
    if (!msg.initialized) {
      return NO;
    }
  }
  return YES;
}

- (instancetype)deepCopyWithZone:(NSZone *)zone {
  ACGPBUInt32ObjectDictionary *newDict =
      [[ACGPBUInt32ObjectDictionary alloc] init];
  NSEnumerator *keys = [_dictionary keyEnumerator];
  id aKey;
  NSMutableDictionary *internalDict = newDict->_dictionary;
  while ((aKey = [keys nextObject])) {
    ACGPBMessage *msg = _dictionary[aKey];
    ACGPBMessage *copiedMsg = [msg copyWithZone:zone];
    [internalDict setObject:copiedMsg forKey:aKey];
    [copiedMsg release];
  }
  return newDict;
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    id aObject = internal[aKey];
    size_t msgSize = ComputeDictUInt32FieldSize([aKey unsignedIntValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(aObject, kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    id aObject = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint32_t unwrappedKey = [aKey unsignedIntValue];
    id unwrappedValue = aObject;
    size_t msgSize = ComputeDictUInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictObjectField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:value->valueString forKey:@(key->valueUInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndObjectsUsingBlock:^(uint32_t key, id object, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%u", key], object);
  }];
}

- (id)objectForKey:(uint32_t)key {
  id result = [_dictionary objectForKey:@(key)];
  return result;
}

- (void)addEntriesFromDictionary:(ACGPBUInt32ObjectDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setObject:(id)object forKey:(uint32_t)key {
  if (!object) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil object to a Dictionary"];
  }
  [_dictionary setObject:object forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeObjectForKey:(uint32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_IMPL_FOR_POD_KEY(Int32, int32_t)
// This block of code is generated, do not edit it directly.
// clang-format off

#pragma mark - Int32 -> UInt32

@implementation ACGPBInt32UInt32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt32s:(const uint32_t [])values
                        forKeys:(const int32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt32UInt32Dictionary *)dictionary {
  self = [self initWithUInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt32UInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt32UInt32Dictionary class]]) {
    return NO;
  }
  ACGPBInt32UInt32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt32sUsingBlock:
    (void (NS_NOESCAPE ^)(int32_t key, uint32_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey intValue], [aValue unsignedIntValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize([aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int32_t unwrappedKey = [aKey intValue];
    uint32_t unwrappedValue = [aValue unsignedIntValue];
    size_t msgSize = ComputeDictInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictUInt32Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt32) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt32sUsingBlock:^(int32_t key, uint32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], [NSString stringWithFormat:@"%u", value]);
  }];
}

- (BOOL)getUInt32:(nullable uint32_t *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedIntValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBInt32UInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt32:(uint32_t)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt32ForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int32 -> Int32

@implementation ACGPBInt32Int32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt32s:(const int32_t [])values
                       forKeys:(const int32_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt32Int32Dictionary *)dictionary {
  self = [self initWithInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt32Int32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt32Int32Dictionary class]]) {
    return NO;
  }
  ACGPBInt32Int32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt32sUsingBlock:
    (void (NS_NOESCAPE ^)(int32_t key, int32_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey intValue], [aValue intValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int32_t unwrappedKey = [aKey intValue];
    int32_t unwrappedValue = [aValue intValue];
    size_t msgSize = ComputeDictInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictInt32Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt32) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt32sUsingBlock:^(int32_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], [NSString stringWithFormat:@"%d", value]);
  }];
}

- (BOOL)getInt32:(nullable int32_t *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBInt32Int32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt32:(int32_t)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt32ForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int32 -> UInt64

@implementation ACGPBInt32UInt64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt64s:(const uint64_t [])values
                        forKeys:(const int32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt32UInt64Dictionary *)dictionary {
  self = [self initWithUInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt32UInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt32UInt64Dictionary class]]) {
    return NO;
  }
  ACGPBInt32UInt64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt64sUsingBlock:
    (void (NS_NOESCAPE ^)(int32_t key, uint64_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey intValue], [aValue unsignedLongLongValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize([aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int32_t unwrappedKey = [aKey intValue];
    uint64_t unwrappedValue = [aValue unsignedLongLongValue];
    size_t msgSize = ComputeDictInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictUInt64Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt64) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt64sUsingBlock:^(int32_t key, uint64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], [NSString stringWithFormat:@"%llu", value]);
  }];
}

- (BOOL)getUInt64:(nullable uint64_t *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedLongLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBInt32UInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt64:(uint64_t)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt64ForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int32 -> Int64

@implementation ACGPBInt32Int64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt64s:(const int64_t [])values
                       forKeys:(const int32_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt32Int64Dictionary *)dictionary {
  self = [self initWithInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt32Int64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt32Int64Dictionary class]]) {
    return NO;
  }
  ACGPBInt32Int64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt64sUsingBlock:
    (void (NS_NOESCAPE ^)(int32_t key, int64_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey intValue], [aValue longLongValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize([aValue longLongValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int32_t unwrappedKey = [aKey intValue];
    int64_t unwrappedValue = [aValue longLongValue];
    size_t msgSize = ComputeDictInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictInt64Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt64) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt64sUsingBlock:^(int32_t key, int64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], [NSString stringWithFormat:@"%lld", value]);
  }];
}

- (BOOL)getInt64:(nullable int64_t *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped longLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBInt32Int64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt64:(int64_t)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt64ForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int32 -> Bool

@implementation ACGPBInt32BoolDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (instancetype)initWithBools:(const BOOL [])values
                      forKeys:(const int32_t [])keys
                        count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt32BoolDictionary *)dictionary {
  self = [self initWithBools:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt32BoolDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt32BoolDictionary class]]) {
    return NO;
  }
  ACGPBInt32BoolDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndBoolsUsingBlock:
    (void (NS_NOESCAPE ^)(int32_t key, BOOL value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey intValue], [aValue boolValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize([aValue boolValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int32_t unwrappedKey = [aKey intValue];
    BOOL unwrappedValue = [aValue boolValue];
    size_t msgSize = ComputeDictInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictBoolField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueBool) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndBoolsUsingBlock:^(int32_t key, BOOL value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], (value ? @"true" : @"false"));
  }];
}

- (BOOL)getBool:(nullable BOOL *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped boolValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBInt32BoolDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setBool:(BOOL)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeBoolForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int32 -> Float

@implementation ACGPBInt32FloatDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (instancetype)initWithFloats:(const float [])values
                       forKeys:(const int32_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt32FloatDictionary *)dictionary {
  self = [self initWithFloats:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt32FloatDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt32FloatDictionary class]]) {
    return NO;
  }
  ACGPBInt32FloatDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndFloatsUsingBlock:
    (void (NS_NOESCAPE ^)(int32_t key, float value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey intValue], [aValue floatValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize([aValue floatValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int32_t unwrappedKey = [aKey intValue];
    float unwrappedValue = [aValue floatValue];
    size_t msgSize = ComputeDictInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictFloatField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueFloat) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndFloatsUsingBlock:^(int32_t key, float value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], [NSString stringWithFormat:@"%.*g", FLT_DIG, value]);
  }];
}

- (BOOL)getFloat:(nullable float *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped floatValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBInt32FloatDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setFloat:(float)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeFloatForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int32 -> Double

@implementation ACGPBInt32DoubleDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (instancetype)initWithDoubles:(const double [])values
                        forKeys:(const int32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt32DoubleDictionary *)dictionary {
  self = [self initWithDoubles:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt32DoubleDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt32DoubleDictionary class]]) {
    return NO;
  }
  ACGPBInt32DoubleDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndDoublesUsingBlock:
    (void (NS_NOESCAPE ^)(int32_t key, double value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey intValue], [aValue doubleValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize([aValue doubleValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int32_t unwrappedKey = [aKey intValue];
    double unwrappedValue = [aValue doubleValue];
    size_t msgSize = ComputeDictInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictDoubleField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueDouble) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndDoublesUsingBlock:^(int32_t key, double value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], [NSString stringWithFormat:@"%.*lg", DBL_DIG, value]);
  }];
}

- (BOOL)getDouble:(nullable double *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped doubleValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBInt32DoubleDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setDouble:(double)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeDoubleForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int32 -> Enum

@implementation ACGPBInt32EnumDictionary {
 @package
  NSMutableDictionary *_dictionary;
  ACGPBEnumValidationFunc _validationFunc;
}

@synthesize validationFunc = _validationFunc;

- (instancetype)init {
  return [self initWithValidationFunction:NULL rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func {
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func
                                 rawValues:(const int32_t [])rawValues
                                   forKeys:(const int32_t [])keys
                                     count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    _validationFunc = (func != NULL ? func : DictDefault_IsValidValue);
    if (count && rawValues && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(rawValues[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt32EnumDictionary *)dictionary {
  self = [self initWithValidationFunction:dictionary.validationFunc
                                rawValues:NULL
                                  forKeys:NULL
                                    count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func
                                  capacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt32EnumDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt32EnumDictionary class]]) {
    return NO;
  }
  ACGPBInt32EnumDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndRawValuesUsingBlock:
    (void (NS_NOESCAPE ^)(int32_t key, int32_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey intValue], [aValue intValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int32_t unwrappedKey = [aKey intValue];
    int32_t unwrappedValue = [aValue intValue];
    size_t msgSize = ComputeDictInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictEnumField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(ACGPBGenericValue *)key
                              keyDataType:(ACGPBDataType)keyDataType {
  size_t msgSize = ComputeDictInt32FieldSize(key->valueInt32, kMapKeyFieldNumber, keyDataType);
  msgSize += ComputeDictEnumFieldSize(value, kMapValueFieldNumber, ACGPBDataTypeEnum);
  NSMutableData *data = [NSMutableData dataWithLength:msgSize];
  ACGPBCodedOutputStream *outputStream = [[ACGPBCodedOutputStream alloc] initWithData:data];
  WriteDictInt32Field(outputStream, key->valueInt32, kMapKeyFieldNumber, keyDataType);
  WriteDictEnumField(outputStream, value, kMapValueFieldNumber, ACGPBDataTypeEnum);
  [outputStream release];
  return data;
}
- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueEnum) forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndRawValuesUsingBlock:^(int32_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], @(value));
  }];
}

- (BOOL)getEnum:(int32_t *)value forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    int32_t result = [wrapped intValue];
    if (!_validationFunc(result)) {
      result = kACGPBUnrecognizedEnumeratorValue;
    }
    *value = result;
  }
  return (wrapped != NULL);
}

- (BOOL)getRawValue:(int32_t *)rawValue forKey:(int32_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && rawValue) {
    *rawValue = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)enumerateKeysAndEnumsUsingBlock:
    (void (NS_NOESCAPE ^)(int32_t key, int32_t value, BOOL *stop))block {
  ACGPBEnumValidationFunc func = _validationFunc;
  BOOL stop = NO;
  NSEnumerator *keys = [_dictionary keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = _dictionary[aKey];
      int32_t unwrapped = [aValue intValue];
      if (!func(unwrapped)) {
        unwrapped = kACGPBUnrecognizedEnumeratorValue;
      }
    block([aKey intValue], unwrapped, &stop);
    if (stop) {
      break;
    }
  }
}

- (void)addRawEntriesFromDictionary:(ACGPBInt32EnumDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setRawValue:(int32_t)value forKey:(int32_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeEnumForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

- (void)setEnum:(int32_t)value forKey:(int32_t)key {
  if (!_validationFunc(value)) {
    [NSException raise:NSInvalidArgumentException
                format:@"ACGPBInt32EnumDictionary: Attempt to set an unknown enum value (%d)",
                       value];
  }

  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

@end

#pragma mark - Int32 -> Object

@implementation ACGPBInt32ObjectDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (instancetype)initWithObjects:(const id [])objects
                        forKeys:(const int32_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && objects && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!objects[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil object to a Dictionary"];
        }
        [_dictionary setObject:objects[i] forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt32ObjectDictionary *)dictionary {
  self = [self initWithObjects:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt32ObjectDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt32ObjectDictionary class]]) {
    return NO;
  }
  ACGPBInt32ObjectDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndObjectsUsingBlock:
    (void (NS_NOESCAPE ^)(int32_t key, id object, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    id aObject = internal[aKey];
    block([aKey intValue], aObject, &stop);
    if (stop) {
      break;
    }
  }
}

- (BOOL)isInitialized {
  for (ACGPBMessage *msg in [_dictionary objectEnumerator]) {
    if (!msg.initialized) {
      return NO;
    }
  }
  return YES;
}

- (instancetype)deepCopyWithZone:(NSZone *)zone {
  ACGPBInt32ObjectDictionary *newDict =
      [[ACGPBInt32ObjectDictionary alloc] init];
  NSEnumerator *keys = [_dictionary keyEnumerator];
  id aKey;
  NSMutableDictionary *internalDict = newDict->_dictionary;
  while ((aKey = [keys nextObject])) {
    ACGPBMessage *msg = _dictionary[aKey];
    ACGPBMessage *copiedMsg = [msg copyWithZone:zone];
    [internalDict setObject:copiedMsg forKey:aKey];
    [copiedMsg release];
  }
  return newDict;
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    id aObject = internal[aKey];
    size_t msgSize = ComputeDictInt32FieldSize([aKey intValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(aObject, kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    id aObject = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int32_t unwrappedKey = [aKey intValue];
    id unwrappedValue = aObject;
    size_t msgSize = ComputeDictInt32FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt32Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictObjectField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:value->valueString forKey:@(key->valueInt32)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndObjectsUsingBlock:^(int32_t key, id object, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%d", key], object);
  }];
}

- (id)objectForKey:(int32_t)key {
  id result = [_dictionary objectForKey:@(key)];
  return result;
}

- (void)addEntriesFromDictionary:(ACGPBInt32ObjectDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setObject:(id)object forKey:(int32_t)key {
  if (!object) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil object to a Dictionary"];
  }
  [_dictionary setObject:object forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeObjectForKey:(int32_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_IMPL_FOR_POD_KEY(UInt64, uint64_t)
// This block of code is generated, do not edit it directly.
// clang-format off

#pragma mark - UInt64 -> UInt32

@implementation ACGPBUInt64UInt32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt32s:(const uint32_t [])values
                        forKeys:(const uint64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt64UInt32Dictionary *)dictionary {
  self = [self initWithUInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt64UInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt64UInt32Dictionary class]]) {
    return NO;
  }
  ACGPBUInt64UInt32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt32sUsingBlock:
    (void (NS_NOESCAPE ^)(uint64_t key, uint32_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedLongLongValue], [aValue unsignedIntValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize([aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint64_t unwrappedKey = [aKey unsignedLongLongValue];
    uint32_t unwrappedValue = [aValue unsignedIntValue];
    size_t msgSize = ComputeDictUInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictUInt32Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt32) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt32sUsingBlock:^(uint64_t key, uint32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], [NSString stringWithFormat:@"%u", value]);
  }];
}

- (BOOL)getUInt32:(nullable uint32_t *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedIntValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBUInt64UInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt32:(uint32_t)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt32ForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt64 -> Int32

@implementation ACGPBUInt64Int32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt32s:(const int32_t [])values
                       forKeys:(const uint64_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt64Int32Dictionary *)dictionary {
  self = [self initWithInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt64Int32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt64Int32Dictionary class]]) {
    return NO;
  }
  ACGPBUInt64Int32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt32sUsingBlock:
    (void (NS_NOESCAPE ^)(uint64_t key, int32_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedLongLongValue], [aValue intValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint64_t unwrappedKey = [aKey unsignedLongLongValue];
    int32_t unwrappedValue = [aValue intValue];
    size_t msgSize = ComputeDictUInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictInt32Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt32) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt32sUsingBlock:^(uint64_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], [NSString stringWithFormat:@"%d", value]);
  }];
}

- (BOOL)getInt32:(nullable int32_t *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBUInt64Int32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt32:(int32_t)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt32ForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt64 -> UInt64

@implementation ACGPBUInt64UInt64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt64s:(const uint64_t [])values
                        forKeys:(const uint64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt64UInt64Dictionary *)dictionary {
  self = [self initWithUInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt64UInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt64UInt64Dictionary class]]) {
    return NO;
  }
  ACGPBUInt64UInt64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt64sUsingBlock:
    (void (NS_NOESCAPE ^)(uint64_t key, uint64_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedLongLongValue], [aValue unsignedLongLongValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize([aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint64_t unwrappedKey = [aKey unsignedLongLongValue];
    uint64_t unwrappedValue = [aValue unsignedLongLongValue];
    size_t msgSize = ComputeDictUInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictUInt64Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt64) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt64sUsingBlock:^(uint64_t key, uint64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], [NSString stringWithFormat:@"%llu", value]);
  }];
}

- (BOOL)getUInt64:(nullable uint64_t *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedLongLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBUInt64UInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt64:(uint64_t)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt64ForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt64 -> Int64

@implementation ACGPBUInt64Int64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt64s:(const int64_t [])values
                       forKeys:(const uint64_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt64Int64Dictionary *)dictionary {
  self = [self initWithInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt64Int64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt64Int64Dictionary class]]) {
    return NO;
  }
  ACGPBUInt64Int64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt64sUsingBlock:
    (void (NS_NOESCAPE ^)(uint64_t key, int64_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedLongLongValue], [aValue longLongValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize([aValue longLongValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint64_t unwrappedKey = [aKey unsignedLongLongValue];
    int64_t unwrappedValue = [aValue longLongValue];
    size_t msgSize = ComputeDictUInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictInt64Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt64) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt64sUsingBlock:^(uint64_t key, int64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], [NSString stringWithFormat:@"%lld", value]);
  }];
}

- (BOOL)getInt64:(nullable int64_t *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped longLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBUInt64Int64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt64:(int64_t)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt64ForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt64 -> Bool

@implementation ACGPBUInt64BoolDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (instancetype)initWithBools:(const BOOL [])values
                      forKeys:(const uint64_t [])keys
                        count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt64BoolDictionary *)dictionary {
  self = [self initWithBools:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt64BoolDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt64BoolDictionary class]]) {
    return NO;
  }
  ACGPBUInt64BoolDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndBoolsUsingBlock:
    (void (NS_NOESCAPE ^)(uint64_t key, BOOL value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedLongLongValue], [aValue boolValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize([aValue boolValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint64_t unwrappedKey = [aKey unsignedLongLongValue];
    BOOL unwrappedValue = [aValue boolValue];
    size_t msgSize = ComputeDictUInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictBoolField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueBool) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndBoolsUsingBlock:^(uint64_t key, BOOL value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], (value ? @"true" : @"false"));
  }];
}

- (BOOL)getBool:(nullable BOOL *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped boolValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBUInt64BoolDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setBool:(BOOL)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeBoolForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt64 -> Float

@implementation ACGPBUInt64FloatDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (instancetype)initWithFloats:(const float [])values
                       forKeys:(const uint64_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt64FloatDictionary *)dictionary {
  self = [self initWithFloats:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt64FloatDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt64FloatDictionary class]]) {
    return NO;
  }
  ACGPBUInt64FloatDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndFloatsUsingBlock:
    (void (NS_NOESCAPE ^)(uint64_t key, float value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedLongLongValue], [aValue floatValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize([aValue floatValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint64_t unwrappedKey = [aKey unsignedLongLongValue];
    float unwrappedValue = [aValue floatValue];
    size_t msgSize = ComputeDictUInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictFloatField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueFloat) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndFloatsUsingBlock:^(uint64_t key, float value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], [NSString stringWithFormat:@"%.*g", FLT_DIG, value]);
  }];
}

- (BOOL)getFloat:(nullable float *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped floatValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBUInt64FloatDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setFloat:(float)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeFloatForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt64 -> Double

@implementation ACGPBUInt64DoubleDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (instancetype)initWithDoubles:(const double [])values
                        forKeys:(const uint64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt64DoubleDictionary *)dictionary {
  self = [self initWithDoubles:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt64DoubleDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt64DoubleDictionary class]]) {
    return NO;
  }
  ACGPBUInt64DoubleDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndDoublesUsingBlock:
    (void (NS_NOESCAPE ^)(uint64_t key, double value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedLongLongValue], [aValue doubleValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize([aValue doubleValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint64_t unwrappedKey = [aKey unsignedLongLongValue];
    double unwrappedValue = [aValue doubleValue];
    size_t msgSize = ComputeDictUInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictDoubleField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueDouble) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndDoublesUsingBlock:^(uint64_t key, double value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], [NSString stringWithFormat:@"%.*lg", DBL_DIG, value]);
  }];
}

- (BOOL)getDouble:(nullable double *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped doubleValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBUInt64DoubleDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setDouble:(double)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeDoubleForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - UInt64 -> Enum

@implementation ACGPBUInt64EnumDictionary {
 @package
  NSMutableDictionary *_dictionary;
  ACGPBEnumValidationFunc _validationFunc;
}

@synthesize validationFunc = _validationFunc;

- (instancetype)init {
  return [self initWithValidationFunction:NULL rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func {
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func
                                 rawValues:(const int32_t [])rawValues
                                   forKeys:(const uint64_t [])keys
                                     count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    _validationFunc = (func != NULL ? func : DictDefault_IsValidValue);
    if (count && rawValues && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(rawValues[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt64EnumDictionary *)dictionary {
  self = [self initWithValidationFunction:dictionary.validationFunc
                                rawValues:NULL
                                  forKeys:NULL
                                    count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func
                                  capacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt64EnumDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt64EnumDictionary class]]) {
    return NO;
  }
  ACGPBUInt64EnumDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndRawValuesUsingBlock:
    (void (NS_NOESCAPE ^)(uint64_t key, int32_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey unsignedLongLongValue], [aValue intValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint64_t unwrappedKey = [aKey unsignedLongLongValue];
    int32_t unwrappedValue = [aValue intValue];
    size_t msgSize = ComputeDictUInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictEnumField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(ACGPBGenericValue *)key
                              keyDataType:(ACGPBDataType)keyDataType {
  size_t msgSize = ComputeDictUInt64FieldSize(key->valueUInt64, kMapKeyFieldNumber, keyDataType);
  msgSize += ComputeDictEnumFieldSize(value, kMapValueFieldNumber, ACGPBDataTypeEnum);
  NSMutableData *data = [NSMutableData dataWithLength:msgSize];
  ACGPBCodedOutputStream *outputStream = [[ACGPBCodedOutputStream alloc] initWithData:data];
  WriteDictUInt64Field(outputStream, key->valueUInt64, kMapKeyFieldNumber, keyDataType);
  WriteDictEnumField(outputStream, value, kMapValueFieldNumber, ACGPBDataTypeEnum);
  [outputStream release];
  return data;
}
- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueEnum) forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndRawValuesUsingBlock:^(uint64_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], @(value));
  }];
}

- (BOOL)getEnum:(int32_t *)value forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    int32_t result = [wrapped intValue];
    if (!_validationFunc(result)) {
      result = kACGPBUnrecognizedEnumeratorValue;
    }
    *value = result;
  }
  return (wrapped != NULL);
}

- (BOOL)getRawValue:(int32_t *)rawValue forKey:(uint64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && rawValue) {
    *rawValue = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)enumerateKeysAndEnumsUsingBlock:
    (void (NS_NOESCAPE ^)(uint64_t key, int32_t value, BOOL *stop))block {
  ACGPBEnumValidationFunc func = _validationFunc;
  BOOL stop = NO;
  NSEnumerator *keys = [_dictionary keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = _dictionary[aKey];
      int32_t unwrapped = [aValue intValue];
      if (!func(unwrapped)) {
        unwrapped = kACGPBUnrecognizedEnumeratorValue;
      }
    block([aKey unsignedLongLongValue], unwrapped, &stop);
    if (stop) {
      break;
    }
  }
}

- (void)addRawEntriesFromDictionary:(ACGPBUInt64EnumDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setRawValue:(int32_t)value forKey:(uint64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeEnumForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

- (void)setEnum:(int32_t)value forKey:(uint64_t)key {
  if (!_validationFunc(value)) {
    [NSException raise:NSInvalidArgumentException
                format:@"ACGPBUInt64EnumDictionary: Attempt to set an unknown enum value (%d)",
                       value];
  }

  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

@end

#pragma mark - UInt64 -> Object

@implementation ACGPBUInt64ObjectDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (instancetype)initWithObjects:(const id [])objects
                        forKeys:(const uint64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && objects && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!objects[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil object to a Dictionary"];
        }
        [_dictionary setObject:objects[i] forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBUInt64ObjectDictionary *)dictionary {
  self = [self initWithObjects:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBUInt64ObjectDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBUInt64ObjectDictionary class]]) {
    return NO;
  }
  ACGPBUInt64ObjectDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndObjectsUsingBlock:
    (void (NS_NOESCAPE ^)(uint64_t key, id object, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    id aObject = internal[aKey];
    block([aKey unsignedLongLongValue], aObject, &stop);
    if (stop) {
      break;
    }
  }
}

- (BOOL)isInitialized {
  for (ACGPBMessage *msg in [_dictionary objectEnumerator]) {
    if (!msg.initialized) {
      return NO;
    }
  }
  return YES;
}

- (instancetype)deepCopyWithZone:(NSZone *)zone {
  ACGPBUInt64ObjectDictionary *newDict =
      [[ACGPBUInt64ObjectDictionary alloc] init];
  NSEnumerator *keys = [_dictionary keyEnumerator];
  id aKey;
  NSMutableDictionary *internalDict = newDict->_dictionary;
  while ((aKey = [keys nextObject])) {
    ACGPBMessage *msg = _dictionary[aKey];
    ACGPBMessage *copiedMsg = [msg copyWithZone:zone];
    [internalDict setObject:copiedMsg forKey:aKey];
    [copiedMsg release];
  }
  return newDict;
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    id aObject = internal[aKey];
    size_t msgSize = ComputeDictUInt64FieldSize([aKey unsignedLongLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(aObject, kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    id aObject = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    uint64_t unwrappedKey = [aKey unsignedLongLongValue];
    id unwrappedValue = aObject;
    size_t msgSize = ComputeDictUInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictUInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictObjectField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:value->valueString forKey:@(key->valueUInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndObjectsUsingBlock:^(uint64_t key, id object, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%llu", key], object);
  }];
}

- (id)objectForKey:(uint64_t)key {
  id result = [_dictionary objectForKey:@(key)];
  return result;
}

- (void)addEntriesFromDictionary:(ACGPBUInt64ObjectDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setObject:(id)object forKey:(uint64_t)key {
  if (!object) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil object to a Dictionary"];
  }
  [_dictionary setObject:object forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeObjectForKey:(uint64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_IMPL_FOR_POD_KEY(Int64, int64_t)
// This block of code is generated, do not edit it directly.
// clang-format off

#pragma mark - Int64 -> UInt32

@implementation ACGPBInt64UInt32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt32s:(const uint32_t [])values
                        forKeys:(const int64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt64UInt32Dictionary *)dictionary {
  self = [self initWithUInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt64UInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt64UInt32Dictionary class]]) {
    return NO;
  }
  ACGPBInt64UInt32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt32sUsingBlock:
    (void (NS_NOESCAPE ^)(int64_t key, uint32_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey longLongValue], [aValue unsignedIntValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize([aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int64_t unwrappedKey = [aKey longLongValue];
    uint32_t unwrappedValue = [aValue unsignedIntValue];
    size_t msgSize = ComputeDictInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictUInt32Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt32) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt32sUsingBlock:^(int64_t key, uint32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], [NSString stringWithFormat:@"%u", value]);
  }];
}

- (BOOL)getUInt32:(nullable uint32_t *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedIntValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBInt64UInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt32:(uint32_t)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt32ForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int64 -> Int32

@implementation ACGPBInt64Int32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt32s:(const int32_t [])values
                       forKeys:(const int64_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt64Int32Dictionary *)dictionary {
  self = [self initWithInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt64Int32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt64Int32Dictionary class]]) {
    return NO;
  }
  ACGPBInt64Int32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt32sUsingBlock:
    (void (NS_NOESCAPE ^)(int64_t key, int32_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey longLongValue], [aValue intValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int64_t unwrappedKey = [aKey longLongValue];
    int32_t unwrappedValue = [aValue intValue];
    size_t msgSize = ComputeDictInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictInt32Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt32) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt32sUsingBlock:^(int64_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], [NSString stringWithFormat:@"%d", value]);
  }];
}

- (BOOL)getInt32:(nullable int32_t *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBInt64Int32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt32:(int32_t)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt32ForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int64 -> UInt64

@implementation ACGPBInt64UInt64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt64s:(const uint64_t [])values
                        forKeys:(const int64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt64UInt64Dictionary *)dictionary {
  self = [self initWithUInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt64UInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt64UInt64Dictionary class]]) {
    return NO;
  }
  ACGPBInt64UInt64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt64sUsingBlock:
    (void (NS_NOESCAPE ^)(int64_t key, uint64_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey longLongValue], [aValue unsignedLongLongValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize([aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int64_t unwrappedKey = [aKey longLongValue];
    uint64_t unwrappedValue = [aValue unsignedLongLongValue];
    size_t msgSize = ComputeDictInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictUInt64Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt64) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt64sUsingBlock:^(int64_t key, uint64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], [NSString stringWithFormat:@"%llu", value]);
  }];
}

- (BOOL)getUInt64:(nullable uint64_t *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped unsignedLongLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBInt64UInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt64:(uint64_t)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt64ForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int64 -> Int64

@implementation ACGPBInt64Int64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt64s:(const int64_t [])values
                       forKeys:(const int64_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt64Int64Dictionary *)dictionary {
  self = [self initWithInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt64Int64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt64Int64Dictionary class]]) {
    return NO;
  }
  ACGPBInt64Int64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt64sUsingBlock:
    (void (NS_NOESCAPE ^)(int64_t key, int64_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey longLongValue], [aValue longLongValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize([aValue longLongValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int64_t unwrappedKey = [aKey longLongValue];
    int64_t unwrappedValue = [aValue longLongValue];
    size_t msgSize = ComputeDictInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictInt64Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt64) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt64sUsingBlock:^(int64_t key, int64_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], [NSString stringWithFormat:@"%lld", value]);
  }];
}

- (BOOL)getInt64:(nullable int64_t *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped longLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBInt64Int64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt64:(int64_t)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt64ForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int64 -> Bool

@implementation ACGPBInt64BoolDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (instancetype)initWithBools:(const BOOL [])values
                      forKeys:(const int64_t [])keys
                        count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt64BoolDictionary *)dictionary {
  self = [self initWithBools:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt64BoolDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt64BoolDictionary class]]) {
    return NO;
  }
  ACGPBInt64BoolDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndBoolsUsingBlock:
    (void (NS_NOESCAPE ^)(int64_t key, BOOL value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey longLongValue], [aValue boolValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize([aValue boolValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int64_t unwrappedKey = [aKey longLongValue];
    BOOL unwrappedValue = [aValue boolValue];
    size_t msgSize = ComputeDictInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictBoolField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueBool) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndBoolsUsingBlock:^(int64_t key, BOOL value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], (value ? @"true" : @"false"));
  }];
}

- (BOOL)getBool:(nullable BOOL *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped boolValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBInt64BoolDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setBool:(BOOL)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeBoolForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int64 -> Float

@implementation ACGPBInt64FloatDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (instancetype)initWithFloats:(const float [])values
                       forKeys:(const int64_t [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt64FloatDictionary *)dictionary {
  self = [self initWithFloats:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt64FloatDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt64FloatDictionary class]]) {
    return NO;
  }
  ACGPBInt64FloatDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndFloatsUsingBlock:
    (void (NS_NOESCAPE ^)(int64_t key, float value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey longLongValue], [aValue floatValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize([aValue floatValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int64_t unwrappedKey = [aKey longLongValue];
    float unwrappedValue = [aValue floatValue];
    size_t msgSize = ComputeDictInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictFloatField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueFloat) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndFloatsUsingBlock:^(int64_t key, float value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], [NSString stringWithFormat:@"%.*g", FLT_DIG, value]);
  }];
}

- (BOOL)getFloat:(nullable float *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped floatValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBInt64FloatDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setFloat:(float)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeFloatForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int64 -> Double

@implementation ACGPBInt64DoubleDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (instancetype)initWithDoubles:(const double [])values
                        forKeys:(const int64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(values[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt64DoubleDictionary *)dictionary {
  self = [self initWithDoubles:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt64DoubleDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt64DoubleDictionary class]]) {
    return NO;
  }
  ACGPBInt64DoubleDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndDoublesUsingBlock:
    (void (NS_NOESCAPE ^)(int64_t key, double value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey longLongValue], [aValue doubleValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize([aValue doubleValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int64_t unwrappedKey = [aKey longLongValue];
    double unwrappedValue = [aValue doubleValue];
    size_t msgSize = ComputeDictInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictDoubleField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueDouble) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndDoublesUsingBlock:^(int64_t key, double value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], [NSString stringWithFormat:@"%.*lg", DBL_DIG, value]);
  }];
}

- (BOOL)getDouble:(nullable double *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    *value = [wrapped doubleValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBInt64DoubleDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setDouble:(double)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeDoubleForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - Int64 -> Enum

@implementation ACGPBInt64EnumDictionary {
 @package
  NSMutableDictionary *_dictionary;
  ACGPBEnumValidationFunc _validationFunc;
}

@synthesize validationFunc = _validationFunc;

- (instancetype)init {
  return [self initWithValidationFunction:NULL rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func {
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func
                                 rawValues:(const int32_t [])rawValues
                                   forKeys:(const int64_t [])keys
                                     count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    _validationFunc = (func != NULL ? func : DictDefault_IsValidValue);
    if (count && rawValues && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        [_dictionary setObject:@(rawValues[i]) forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt64EnumDictionary *)dictionary {
  self = [self initWithValidationFunction:dictionary.validationFunc
                                rawValues:NULL
                                  forKeys:NULL
                                    count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func
                                  capacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt64EnumDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt64EnumDictionary class]]) {
    return NO;
  }
  ACGPBInt64EnumDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndRawValuesUsingBlock:
    (void (NS_NOESCAPE ^)(int64_t key, int32_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block([aKey longLongValue], [aValue intValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int64_t unwrappedKey = [aKey longLongValue];
    int32_t unwrappedValue = [aValue intValue];
    size_t msgSize = ComputeDictInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictEnumField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(ACGPBGenericValue *)key
                              keyDataType:(ACGPBDataType)keyDataType {
  size_t msgSize = ComputeDictInt64FieldSize(key->valueInt64, kMapKeyFieldNumber, keyDataType);
  msgSize += ComputeDictEnumFieldSize(value, kMapValueFieldNumber, ACGPBDataTypeEnum);
  NSMutableData *data = [NSMutableData dataWithLength:msgSize];
  ACGPBCodedOutputStream *outputStream = [[ACGPBCodedOutputStream alloc] initWithData:data];
  WriteDictInt64Field(outputStream, key->valueInt64, kMapKeyFieldNumber, keyDataType);
  WriteDictEnumField(outputStream, value, kMapValueFieldNumber, ACGPBDataTypeEnum);
  [outputStream release];
  return data;
}
- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueEnum) forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndRawValuesUsingBlock:^(int64_t key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], @(value));
  }];
}

- (BOOL)getEnum:(int32_t *)value forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && value) {
    int32_t result = [wrapped intValue];
    if (!_validationFunc(result)) {
      result = kACGPBUnrecognizedEnumeratorValue;
    }
    *value = result;
  }
  return (wrapped != NULL);
}

- (BOOL)getRawValue:(int32_t *)rawValue forKey:(int64_t)key {
  NSNumber *wrapped = [_dictionary objectForKey:@(key)];
  if (wrapped && rawValue) {
    *rawValue = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)enumerateKeysAndEnumsUsingBlock:
    (void (NS_NOESCAPE ^)(int64_t key, int32_t value, BOOL *stop))block {
  ACGPBEnumValidationFunc func = _validationFunc;
  BOOL stop = NO;
  NSEnumerator *keys = [_dictionary keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = _dictionary[aKey];
      int32_t unwrapped = [aValue intValue];
      if (!func(unwrapped)) {
        unwrapped = kACGPBUnrecognizedEnumeratorValue;
      }
    block([aKey longLongValue], unwrapped, &stop);
    if (stop) {
      break;
    }
  }
}

- (void)addRawEntriesFromDictionary:(ACGPBInt64EnumDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setRawValue:(int32_t)value forKey:(int64_t)key {
  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeEnumForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

- (void)setEnum:(int32_t)value forKey:(int64_t)key {
  if (!_validationFunc(value)) {
    [NSException raise:NSInvalidArgumentException
                format:@"ACGPBInt64EnumDictionary: Attempt to set an unknown enum value (%d)",
                       value];
  }

  [_dictionary setObject:@(value) forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

@end

#pragma mark - Int64 -> Object

@implementation ACGPBInt64ObjectDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (instancetype)initWithObjects:(const id [])objects
                        forKeys:(const int64_t [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && objects && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!objects[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil object to a Dictionary"];
        }
        [_dictionary setObject:objects[i] forKey:@(keys[i])];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBInt64ObjectDictionary *)dictionary {
  self = [self initWithObjects:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBInt64ObjectDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBInt64ObjectDictionary class]]) {
    return NO;
  }
  ACGPBInt64ObjectDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndObjectsUsingBlock:
    (void (NS_NOESCAPE ^)(int64_t key, id object, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    id aObject = internal[aKey];
    block([aKey longLongValue], aObject, &stop);
    if (stop) {
      break;
    }
  }
}

- (BOOL)isInitialized {
  for (ACGPBMessage *msg in [_dictionary objectEnumerator]) {
    if (!msg.initialized) {
      return NO;
    }
  }
  return YES;
}

- (instancetype)deepCopyWithZone:(NSZone *)zone {
  ACGPBInt64ObjectDictionary *newDict =
      [[ACGPBInt64ObjectDictionary alloc] init];
  NSEnumerator *keys = [_dictionary keyEnumerator];
  id aKey;
  NSMutableDictionary *internalDict = newDict->_dictionary;
  while ((aKey = [keys nextObject])) {
    ACGPBMessage *msg = _dictionary[aKey];
    ACGPBMessage *copiedMsg = [msg copyWithZone:zone];
    [internalDict setObject:copiedMsg forKey:aKey];
    [copiedMsg release];
  }
  return newDict;
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    id aObject = internal[aKey];
    size_t msgSize = ComputeDictInt64FieldSize([aKey longLongValue], kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(aObject, kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSNumber *aKey;
  while ((aKey = [keys nextObject])) {
    id aObject = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    int64_t unwrappedKey = [aKey longLongValue];
    id unwrappedValue = aObject;
    size_t msgSize = ComputeDictInt64FieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictObjectFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictInt64Field(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictObjectField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:value->valueString forKey:@(key->valueInt64)];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndObjectsUsingBlock:^(int64_t key, id object, BOOL *stop) {
      #pragma unused(stop)
      block([NSString stringWithFormat:@"%lld", key], object);
  }];
}

- (id)objectForKey:(int64_t)key {
  id result = [_dictionary objectForKey:@(key)];
  return result;
}

- (void)addEntriesFromDictionary:(ACGPBInt64ObjectDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setObject:(id)object forKey:(int64_t)key {
  if (!object) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil object to a Dictionary"];
  }
  [_dictionary setObject:object forKey:@(key)];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeObjectForKey:(int64_t)aKey {
  [_dictionary removeObjectForKey:@(aKey)];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_POD_IMPL_FOR_KEY(String, NSString, *, OBJECT)
// This block of code is generated, do not edit it directly.
// clang-format off

#pragma mark - String -> UInt32

@implementation ACGPBStringUInt32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt32s:(const uint32_t [])values
                        forKeys:(const NSString * [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(values[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBStringUInt32Dictionary *)dictionary {
  self = [self initWithUInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBStringUInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBStringUInt32Dictionary class]]) {
    return NO;
  }
  ACGPBStringUInt32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt32sUsingBlock:
    (void (NS_NOESCAPE ^)(NSString *key, uint32_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block(aKey, [aValue unsignedIntValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize([aValue unsignedIntValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    NSString *unwrappedKey = aKey;
    uint32_t unwrappedValue = [aValue unsignedIntValue];
    size_t msgSize = ComputeDictStringFieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt32FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictUInt32Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt32) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt32sUsingBlock:^(NSString *key, uint32_t value, BOOL *stop) {
      #pragma unused(stop)
      block(key, [NSString stringWithFormat:@"%u", value]);
  }];
}

- (BOOL)getUInt32:(nullable uint32_t *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    *value = [wrapped unsignedIntValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBStringUInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt32:(uint32_t)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt32ForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - String -> Int32

@implementation ACGPBStringInt32Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt32s:(const int32_t [])values
                       forKeys:(const NSString * [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(values[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBStringInt32Dictionary *)dictionary {
  self = [self initWithInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBStringInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBStringInt32Dictionary class]]) {
    return NO;
  }
  ACGPBStringInt32Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt32sUsingBlock:
    (void (NS_NOESCAPE ^)(NSString *key, int32_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block(aKey, [aValue intValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    NSString *unwrappedKey = aKey;
    int32_t unwrappedValue = [aValue intValue];
    size_t msgSize = ComputeDictStringFieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt32FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictInt32Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt32) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt32sUsingBlock:^(NSString *key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block(key, [NSString stringWithFormat:@"%d", value]);
  }];
}

- (BOOL)getInt32:(nullable int32_t *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    *value = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBStringInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt32:(int32_t)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt32ForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - String -> UInt64

@implementation ACGPBStringUInt64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt64s:(const uint64_t [])values
                        forKeys:(const NSString * [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(values[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBStringUInt64Dictionary *)dictionary {
  self = [self initWithUInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBStringUInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBStringUInt64Dictionary class]]) {
    return NO;
  }
  ACGPBStringUInt64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndUInt64sUsingBlock:
    (void (NS_NOESCAPE ^)(NSString *key, uint64_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block(aKey, [aValue unsignedLongLongValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize([aValue unsignedLongLongValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    NSString *unwrappedKey = aKey;
    uint64_t unwrappedValue = [aValue unsignedLongLongValue];
    size_t msgSize = ComputeDictStringFieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictUInt64FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictUInt64Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueUInt64) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndUInt64sUsingBlock:^(NSString *key, uint64_t value, BOOL *stop) {
      #pragma unused(stop)
      block(key, [NSString stringWithFormat:@"%llu", value]);
  }];
}

- (BOOL)getUInt64:(nullable uint64_t *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    *value = [wrapped unsignedLongLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBStringUInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt64:(uint64_t)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt64ForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - String -> Int64

@implementation ACGPBStringInt64Dictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt64s:(const int64_t [])values
                       forKeys:(const NSString * [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(values[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBStringInt64Dictionary *)dictionary {
  self = [self initWithInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBStringInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBStringInt64Dictionary class]]) {
    return NO;
  }
  ACGPBStringInt64Dictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndInt64sUsingBlock:
    (void (NS_NOESCAPE ^)(NSString *key, int64_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block(aKey, [aValue longLongValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize([aValue longLongValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    NSString *unwrappedKey = aKey;
    int64_t unwrappedValue = [aValue longLongValue];
    size_t msgSize = ComputeDictStringFieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictInt64FieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictInt64Field(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueInt64) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndInt64sUsingBlock:^(NSString *key, int64_t value, BOOL *stop) {
      #pragma unused(stop)
      block(key, [NSString stringWithFormat:@"%lld", value]);
  }];
}

- (BOOL)getInt64:(nullable int64_t *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    *value = [wrapped longLongValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBStringInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt64:(int64_t)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt64ForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - String -> Bool

@implementation ACGPBStringBoolDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (instancetype)initWithBools:(const BOOL [])values
                      forKeys:(const NSString * [])keys
                        count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(values[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBStringBoolDictionary *)dictionary {
  self = [self initWithBools:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBStringBoolDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBStringBoolDictionary class]]) {
    return NO;
  }
  ACGPBStringBoolDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndBoolsUsingBlock:
    (void (NS_NOESCAPE ^)(NSString *key, BOOL value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block(aKey, [aValue boolValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize([aValue boolValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    NSString *unwrappedKey = aKey;
    BOOL unwrappedValue = [aValue boolValue];
    size_t msgSize = ComputeDictStringFieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictBoolFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictBoolField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueBool) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndBoolsUsingBlock:^(NSString *key, BOOL value, BOOL *stop) {
      #pragma unused(stop)
      block(key, (value ? @"true" : @"false"));
  }];
}

- (BOOL)getBool:(nullable BOOL *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    *value = [wrapped boolValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBStringBoolDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeBoolForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - String -> Float

@implementation ACGPBStringFloatDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (instancetype)initWithFloats:(const float [])values
                       forKeys:(const NSString * [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(values[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBStringFloatDictionary *)dictionary {
  self = [self initWithFloats:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBStringFloatDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBStringFloatDictionary class]]) {
    return NO;
  }
  ACGPBStringFloatDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndFloatsUsingBlock:
    (void (NS_NOESCAPE ^)(NSString *key, float value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block(aKey, [aValue floatValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize([aValue floatValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    NSString *unwrappedKey = aKey;
    float unwrappedValue = [aValue floatValue];
    size_t msgSize = ComputeDictStringFieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictFloatFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictFloatField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueFloat) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndFloatsUsingBlock:^(NSString *key, float value, BOOL *stop) {
      #pragma unused(stop)
      block(key, [NSString stringWithFormat:@"%.*g", FLT_DIG, value]);
  }];
}

- (BOOL)getFloat:(nullable float *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    *value = [wrapped floatValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBStringFloatDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setFloat:(float)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeFloatForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - String -> Double

@implementation ACGPBStringDoubleDictionary {
 @package
  NSMutableDictionary *_dictionary;
}

- (instancetype)init {
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (instancetype)initWithDoubles:(const double [])values
                        forKeys:(const NSString * [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    if (count && values && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(values[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBStringDoubleDictionary *)dictionary {
  self = [self initWithDoubles:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBStringDoubleDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBStringDoubleDictionary class]]) {
    return NO;
  }
  ACGPBStringDoubleDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndDoublesUsingBlock:
    (void (NS_NOESCAPE ^)(NSString *key, double value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block(aKey, [aValue doubleValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize([aValue doubleValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    NSString *unwrappedKey = aKey;
    double unwrappedValue = [aValue doubleValue];
    size_t msgSize = ComputeDictStringFieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictDoubleFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictDoubleField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueDouble) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndDoublesUsingBlock:^(NSString *key, double value, BOOL *stop) {
      #pragma unused(stop)
      block(key, [NSString stringWithFormat:@"%.*lg", DBL_DIG, value]);
  }];
}

- (BOOL)getDouble:(nullable double *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    *value = [wrapped doubleValue];
  }
  return (wrapped != NULL);
}

- (void)addEntriesFromDictionary:(ACGPBStringDoubleDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setDouble:(double)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeDoubleForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

@end

#pragma mark - String -> Enum

@implementation ACGPBStringEnumDictionary {
 @package
  NSMutableDictionary *_dictionary;
  ACGPBEnumValidationFunc _validationFunc;
}

@synthesize validationFunc = _validationFunc;

- (instancetype)init {
  return [self initWithValidationFunction:NULL rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func {
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func
                                 rawValues:(const int32_t [])rawValues
                                   forKeys:(const NSString * [])keys
                                     count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    _validationFunc = (func != NULL ? func : DictDefault_IsValidValue);
    if (count && rawValues && keys) {
      for (NSUInteger i = 0; i < count; ++i) {
        if (!keys[i]) {
          [NSException raise:NSInvalidArgumentException
                      format:@"Attempting to add nil key to a Dictionary"];
        }
        [_dictionary setObject:@(rawValues[i]) forKey:keys[i]];
      }
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBStringEnumDictionary *)dictionary {
  self = [self initWithValidationFunction:dictionary.validationFunc
                                rawValues:NULL
                                  forKeys:NULL
                                    count:0];
  if (self) {
    if (dictionary) {
      [_dictionary addEntriesFromDictionary:dictionary->_dictionary];
    }
  }
  return self;
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func
                                  capacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBStringEnumDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBStringEnumDictionary class]]) {
    return NO;
  }
  ACGPBStringEnumDictionary *otherDictionary = other;
  return [_dictionary isEqual:otherDictionary->_dictionary];
}

- (NSUInteger)hash {
  return _dictionary.count;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> { %@ }", [self class], self, _dictionary];
}

- (NSUInteger)count {
  return _dictionary.count;
}

- (void)enumerateKeysAndRawValuesUsingBlock:
    (void (NS_NOESCAPE ^)(NSString *key, int32_t value, BOOL *stop))block {
  BOOL stop = NO;
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    block(aKey, [aValue intValue], &stop);
    if (stop) {
      break;
    }
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  NSDictionary *internal = _dictionary;
  NSUInteger count = internal.count;
  if (count == 0) {
    return 0;
  }

  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  size_t result = 0;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    size_t msgSize = ComputeDictStringFieldSize(aKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize([aValue intValue], kMapValueFieldNumber, valueDataType);
    result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  ACGPBDataType keyDataType = field.mapKeyDataType;
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  NSDictionary *internal = _dictionary;
  NSEnumerator *keys = [internal keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = internal[aKey];
    [outputStream writeInt32NoTag:tag];
    // Write the size of the message.
    NSString *unwrappedKey = aKey;
    int32_t unwrappedValue = [aValue intValue];
    size_t msgSize = ComputeDictStringFieldSize(unwrappedKey, kMapKeyFieldNumber, keyDataType);
    msgSize += ComputeDictEnumFieldSize(unwrappedValue, kMapValueFieldNumber, valueDataType);
    [outputStream writeInt32NoTag:(int32_t)msgSize];
    // Write the fields.
    WriteDictStringField(outputStream, unwrappedKey, kMapKeyFieldNumber, keyDataType);
    WriteDictEnumField(outputStream, unwrappedValue, kMapValueFieldNumber, valueDataType);
  }
}

- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(ACGPBGenericValue *)key
                              keyDataType:(ACGPBDataType)keyDataType {
  size_t msgSize = ComputeDictStringFieldSize(key->valueString, kMapKeyFieldNumber, keyDataType);
  msgSize += ComputeDictEnumFieldSize(value, kMapValueFieldNumber, ACGPBDataTypeEnum);
  NSMutableData *data = [NSMutableData dataWithLength:msgSize];
  ACGPBCodedOutputStream *outputStream = [[ACGPBCodedOutputStream alloc] initWithData:data];
  WriteDictStringField(outputStream, key->valueString, kMapKeyFieldNumber, keyDataType);
  WriteDictEnumField(outputStream, value, kMapValueFieldNumber, ACGPBDataTypeEnum);
  [outputStream release];
  return data;
}
- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  [_dictionary setObject:@(value->valueEnum) forKey:key->valueString];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  [self enumerateKeysAndRawValuesUsingBlock:^(NSString *key, int32_t value, BOOL *stop) {
      #pragma unused(stop)
      block(key, @(value));
  }];
}

- (BOOL)getEnum:(int32_t *)value forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && value) {
    int32_t result = [wrapped intValue];
    if (!_validationFunc(result)) {
      result = kACGPBUnrecognizedEnumeratorValue;
    }
    *value = result;
  }
  return (wrapped != NULL);
}

- (BOOL)getRawValue:(int32_t *)rawValue forKey:(NSString *)key {
  NSNumber *wrapped = [_dictionary objectForKey:key];
  if (wrapped && rawValue) {
    *rawValue = [wrapped intValue];
  }
  return (wrapped != NULL);
}

- (void)enumerateKeysAndEnumsUsingBlock:
    (void (NS_NOESCAPE ^)(NSString *key, int32_t value, BOOL *stop))block {
  ACGPBEnumValidationFunc func = _validationFunc;
  BOOL stop = NO;
  NSEnumerator *keys = [_dictionary keyEnumerator];
  NSString *aKey;
  while ((aKey = [keys nextObject])) {
    NSNumber *aValue = _dictionary[aKey];
      int32_t unwrapped = [aValue intValue];
      if (!func(unwrapped)) {
        unwrapped = kACGPBUnrecognizedEnumeratorValue;
      }
    block(aKey, unwrapped, &stop);
    if (stop) {
      break;
    }
  }
}

- (void)addRawEntriesFromDictionary:(ACGPBStringEnumDictionary *)otherDictionary {
  if (otherDictionary) {
    [_dictionary addEntriesFromDictionary:otherDictionary->_dictionary];
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setRawValue:(int32_t)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeEnumForKey:(NSString *)aKey {
  [_dictionary removeObjectForKey:aKey];
}

- (void)removeAll {
  [_dictionary removeAllObjects];
}

- (void)setEnum:(int32_t)value forKey:(NSString *)key {
  if (!key) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil key to a Dictionary"];
  }
  if (!_validationFunc(value)) {
    [NSException raise:NSInvalidArgumentException
                format:@"ACGPBStringEnumDictionary: Attempt to set an unknown enum value (%d)",
                       value];
  }

  [_dictionary setObject:@(value) forKey:key];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

@end

// clang-format on
//%PDDM-EXPAND-END (5 expansions)


//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_POD_IMPL(UInt32, uint32_t)
// This block of code is generated, do not edit it directly.
// clang-format off

#pragma mark - Bool -> UInt32

@implementation ACGPBBoolUInt32Dictionary {
 @package
  uint32_t _values[2];
  BOOL _valueSet[2];
}

- (instancetype)init {
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt32s:(const uint32_t [])values
                        forKeys:(const BOOL [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = values[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBBoolUInt32Dictionary *)dictionary {
  self = [self initWithUInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt32s:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBBoolUInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBBoolUInt32Dictionary class]]) {
    return NO;
  }
  ACGPBBoolUInt32Dictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %u", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %u", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getUInt32:(uint32_t *)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      *value = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueUInt32;
  _valueSet[idx] = YES;
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", [NSString stringWithFormat:@"%u", _values[0]]);
  }
  if (_valueSet[1]) {
    block(@"true", [NSString stringWithFormat:@"%u", _values[1]]);
  }
}

- (void)enumerateKeysAndUInt32sUsingBlock:
    (void (NS_NOESCAPE ^)(BOOL key, uint32_t value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictUInt32FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictUInt32FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      WriteDictUInt32Field(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(ACGPBBoolUInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt32:(uint32_t)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt32ForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_POD_IMPL(Int32, int32_t)
// This block of code is generated, do not edit it directly.
// clang-format off

#pragma mark - Bool -> Int32

@implementation ACGPBBoolInt32Dictionary {
 @package
  int32_t _values[2];
  BOOL _valueSet[2];
}

- (instancetype)init {
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt32s:(const int32_t [])values
                       forKeys:(const BOOL [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = values[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBBoolInt32Dictionary *)dictionary {
  self = [self initWithInt32s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt32s:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBBoolInt32Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBBoolInt32Dictionary class]]) {
    return NO;
  }
  ACGPBBoolInt32Dictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %d", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %d", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getInt32:(int32_t *)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      *value = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueInt32;
  _valueSet[idx] = YES;
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", [NSString stringWithFormat:@"%d", _values[0]]);
  }
  if (_valueSet[1]) {
    block(@"true", [NSString stringWithFormat:@"%d", _values[1]]);
  }
}

- (void)enumerateKeysAndInt32sUsingBlock:
    (void (NS_NOESCAPE ^)(BOOL key, int32_t value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictInt32FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictInt32FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      WriteDictInt32Field(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(ACGPBBoolInt32Dictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt32:(int32_t)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt32ForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_POD_IMPL(UInt64, uint64_t)
// This block of code is generated, do not edit it directly.
// clang-format off

#pragma mark - Bool -> UInt64

@implementation ACGPBBoolUInt64Dictionary {
 @package
  uint64_t _values[2];
  BOOL _valueSet[2];
}

- (instancetype)init {
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithUInt64s:(const uint64_t [])values
                        forKeys:(const BOOL [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = values[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBBoolUInt64Dictionary *)dictionary {
  self = [self initWithUInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithUInt64s:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBBoolUInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBBoolUInt64Dictionary class]]) {
    return NO;
  }
  ACGPBBoolUInt64Dictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %llu", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %llu", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getUInt64:(uint64_t *)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      *value = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueUInt64;
  _valueSet[idx] = YES;
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", [NSString stringWithFormat:@"%llu", _values[0]]);
  }
  if (_valueSet[1]) {
    block(@"true", [NSString stringWithFormat:@"%llu", _values[1]]);
  }
}

- (void)enumerateKeysAndUInt64sUsingBlock:
    (void (NS_NOESCAPE ^)(BOOL key, uint64_t value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictUInt64FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictUInt64FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      WriteDictUInt64Field(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(ACGPBBoolUInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setUInt64:(uint64_t)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeUInt64ForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_POD_IMPL(Int64, int64_t)
// This block of code is generated, do not edit it directly.
// clang-format off

#pragma mark - Bool -> Int64

@implementation ACGPBBoolInt64Dictionary {
 @package
  int64_t _values[2];
  BOOL _valueSet[2];
}

- (instancetype)init {
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

- (instancetype)initWithInt64s:(const int64_t [])values
                       forKeys:(const BOOL [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = values[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBBoolInt64Dictionary *)dictionary {
  self = [self initWithInt64s:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithInt64s:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBBoolInt64Dictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBBoolInt64Dictionary class]]) {
    return NO;
  }
  ACGPBBoolInt64Dictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %lld", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %lld", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getInt64:(int64_t *)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      *value = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueInt64;
  _valueSet[idx] = YES;
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", [NSString stringWithFormat:@"%lld", _values[0]]);
  }
  if (_valueSet[1]) {
    block(@"true", [NSString stringWithFormat:@"%lld", _values[1]]);
  }
}

- (void)enumerateKeysAndInt64sUsingBlock:
    (void (NS_NOESCAPE ^)(BOOL key, int64_t value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictInt64FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictInt64FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      WriteDictInt64Field(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(ACGPBBoolInt64Dictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setInt64:(int64_t)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeInt64ForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_POD_IMPL(Bool, BOOL)
// This block of code is generated, do not edit it directly.
// clang-format off

#pragma mark - Bool -> Bool

@implementation ACGPBBoolBoolDictionary {
 @package
  BOOL _values[2];
  BOOL _valueSet[2];
}

- (instancetype)init {
  return [self initWithBools:NULL forKeys:NULL count:0];
}

- (instancetype)initWithBools:(const BOOL [])values
                      forKeys:(const BOOL [])keys
                        count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = values[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBBoolBoolDictionary *)dictionary {
  self = [self initWithBools:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithBools:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBBoolBoolDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBBoolBoolDictionary class]]) {
    return NO;
  }
  ACGPBBoolBoolDictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %d", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %d", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getBool:(BOOL *)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      *value = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueBool;
  _valueSet[idx] = YES;
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", (_values[0] ? @"true" : @"false"));
  }
  if (_valueSet[1]) {
    block(@"true", (_values[1] ? @"true" : @"false"));
  }
}

- (void)enumerateKeysAndBoolsUsingBlock:
    (void (NS_NOESCAPE ^)(BOOL key, BOOL value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictBoolFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictBoolFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      WriteDictBoolField(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(ACGPBBoolBoolDictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setBool:(BOOL)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeBoolForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_POD_IMPL(Float, float)
// This block of code is generated, do not edit it directly.
// clang-format off

#pragma mark - Bool -> Float

@implementation ACGPBBoolFloatDictionary {
 @package
  float _values[2];
  BOOL _valueSet[2];
}

- (instancetype)init {
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

- (instancetype)initWithFloats:(const float [])values
                       forKeys:(const BOOL [])keys
                         count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = values[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBBoolFloatDictionary *)dictionary {
  self = [self initWithFloats:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithFloats:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBBoolFloatDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBBoolFloatDictionary class]]) {
    return NO;
  }
  ACGPBBoolFloatDictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %f", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %f", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getFloat:(float *)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      *value = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueFloat;
  _valueSet[idx] = YES;
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", [NSString stringWithFormat:@"%.*g", FLT_DIG, _values[0]]);
  }
  if (_valueSet[1]) {
    block(@"true", [NSString stringWithFormat:@"%.*g", FLT_DIG, _values[1]]);
  }
}

- (void)enumerateKeysAndFloatsUsingBlock:
    (void (NS_NOESCAPE ^)(BOOL key, float value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictFloatFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictFloatFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      WriteDictFloatField(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(ACGPBBoolFloatDictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setFloat:(float)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeFloatForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_POD_IMPL(Double, double)
// This block of code is generated, do not edit it directly.
// clang-format off

#pragma mark - Bool -> Double

@implementation ACGPBBoolDoubleDictionary {
 @package
  double _values[2];
  BOOL _valueSet[2];
}

- (instancetype)init {
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

- (instancetype)initWithDoubles:(const double [])values
                        forKeys:(const BOOL [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = values[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBBoolDoubleDictionary *)dictionary {
  self = [self initWithDoubles:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithDoubles:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBBoolDoubleDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBBoolDoubleDictionary class]]) {
    return NO;
  }
  ACGPBBoolDoubleDictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %lf", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %lf", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getDouble:(double *)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      *value = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueDouble;
  _valueSet[idx] = YES;
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", [NSString stringWithFormat:@"%.*lg", DBL_DIG, _values[0]]);
  }
  if (_valueSet[1]) {
    block(@"true", [NSString stringWithFormat:@"%.*lg", DBL_DIG, _values[1]]);
  }
}

- (void)enumerateKeysAndDoublesUsingBlock:
    (void (NS_NOESCAPE ^)(BOOL key, double value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictDoubleFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictDoubleFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      WriteDictDoubleField(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(ACGPBBoolDoubleDictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setDouble:(double)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeDoubleForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_BOOL_KEY_TO_OBJECT_IMPL(Object, id)
// This block of code is generated, do not edit it directly.
// clang-format off

#pragma mark - Bool -> Object

@implementation ACGPBBoolObjectDictionary {
 @package
  id _values[2];
}

- (instancetype)init {
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (instancetype)initWithObjects:(const id [])objects
                        forKeys:(const BOOL [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    for (NSUInteger i = 0; i < count; ++i) {
      if (!objects[i]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Attempting to add nil object to a Dictionary"];
      }
      int idx = keys[i] ? 1 : 0;
      [_values[idx] release];
      _values[idx] = (id)[objects[i] retain];
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBBoolObjectDictionary *)dictionary {
  self = [self initWithObjects:NULL forKeys:NULL count:0];
  if (self) {
    if (dictionary) {
      _values[0] = [dictionary->_values[0] retain];
      _values[1] = [dictionary->_values[1] retain];
    }
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
  #pragma unused(numItems)
  return [self initWithObjects:NULL forKeys:NULL count:0];
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_values[0] release];
  [_values[1] release];
  [super dealloc];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBBoolObjectDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBBoolObjectDictionary class]]) {
    return NO;
  }
  ACGPBBoolObjectDictionary *otherDictionary = other;
  if (((_values[0] != nil) != (otherDictionary->_values[0] != nil)) ||
      ((_values[1] != nil) != (otherDictionary->_values[1] != nil))) {
    return NO;
  }
  if (((_values[0] != nil) && (![_values[0] isEqual:otherDictionary->_values[0]])) ||
      ((_values[1] != nil) && (![_values[1] isEqual:otherDictionary->_values[1]]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return ((_values[0] != nil) ? 1 : 0) + ((_values[1] != nil) ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if ((_values[0] != nil)) {
    [result appendFormat:@"NO: %@", _values[0]];
  }
  if ((_values[1] != nil)) {
    [result appendFormat:@"YES: %@", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return ((_values[0] != nil) ? 1 : 0) + ((_values[1] != nil) ? 1 : 0);
}

- (id)objectForKey:(BOOL)key {
  return _values[key ? 1 : 0];
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  [_values[idx] release];
  _values[idx] = [value->valueString retain];
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  if (_values[0] != nil) {
    block(@"false", _values[0]);
  }
  if ((_values[1] != nil)) {
    block(@"true", _values[1]);
  }
}

- (void)enumerateKeysAndObjectsUsingBlock:
    (void (NS_NOESCAPE ^)(BOOL key, id object, BOOL *stop))block {
  BOOL stop = NO;
  if (_values[0] != nil) {
    block(NO, _values[0], &stop);
  }
  if (!stop && (_values[1] != nil)) {
    block(YES, _values[1], &stop);
  }
}

- (BOOL)isInitialized {
  if (_values[0] && ![_values[0] isInitialized]) {
    return NO;
  }
  if (_values[1] && ![_values[1] isInitialized]) {
    return NO;
  }
  return YES;
}

- (instancetype)deepCopyWithZone:(NSZone *)zone {
  ACGPBBoolObjectDictionary *newDict =
      [[ACGPBBoolObjectDictionary alloc] init];
  for (int i = 0; i < 2; ++i) {
    if (_values[i] != nil) {
      newDict->_values[i] = [_values[i] copyWithZone:zone];
    }
  }
  return newDict;
}

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_values[i] != nil) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictObjectFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_values[i] != nil) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictObjectFieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      WriteDictObjectField(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)addEntriesFromDictionary:(ACGPBBoolObjectDictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_values[i] != nil) {
        [_values[i] release];
        _values[i] = [otherDictionary->_values[i] retain];
      }
    }
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setObject:(id)object forKey:(BOOL)key {
  if (!object) {
    [NSException raise:NSInvalidArgumentException
                format:@"Attempting to add nil object to a Dictionary"];
  }
  int idx = (key ? 1 : 0);
  [_values[idx] release];
  _values[idx] = [object retain];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeObjectForKey:(BOOL)aKey {
  int idx = (aKey ? 1 : 0);
  [_values[idx] release];
  _values[idx] = nil;
}

- (void)removeAll {
  for (int i = 0; i < 2; ++i) {
    [_values[i] release];
    _values[i] = nil;
  }
}

@end

// clang-format on
//%PDDM-EXPAND-END (8 expansions)

#pragma mark - Bool -> Enum

@implementation ACGPBBoolEnumDictionary {
 @package
  ACGPBEnumValidationFunc _validationFunc;
  int32_t _values[2];
  BOOL _valueSet[2];
}

@synthesize validationFunc = _validationFunc;

- (instancetype)init {
  return [self initWithValidationFunction:NULL rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func {
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func
                                rawValues:(const int32_t [])rawValues
                                   forKeys:(const BOOL [])keys
                                     count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _validationFunc = (func != NULL ? func : DictDefault_IsValidValue);
    for (NSUInteger i = 0; i < count; ++i) {
      int idx = keys[i] ? 1 : 0;
      _values[idx] = rawValues[i];
      _valueSet[idx] = YES;
    }
  }
  return self;
}

- (instancetype)initWithDictionary:(ACGPBBoolEnumDictionary *)dictionary {
  self = [self initWithValidationFunction:dictionary.validationFunc
                                rawValues:NULL
                                  forKeys:NULL
                                    count:0];
  if (self) {
    if (dictionary) {
      for (int i = 0; i < 2; ++i) {
        if (dictionary->_valueSet[i]) {
          _values[i] = dictionary->_values[i];
          _valueSet[i] = YES;
        }
      }
    }
  }
  return self;
}

- (instancetype)initWithValidationFunction:(ACGPBEnumValidationFunc)func
                                  capacity:(NSUInteger)numItems {
#pragma unused(numItems)
  return [self initWithValidationFunction:func rawValues:NULL forKeys:NULL count:0];
}

#if !defined(NS_BLOCK_ASSERTIONS)
- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [super dealloc];
}
#endif  // !defined(NS_BLOCK_ASSERTIONS)

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[ACGPBBoolEnumDictionary allocWithZone:zone] initWithDictionary:self];
}

- (BOOL)isEqual:(id)other {
  if (self == other) {
    return YES;
  }
  if (![other isKindOfClass:[ACGPBBoolEnumDictionary class]]) {
    return NO;
  }
  ACGPBBoolEnumDictionary *otherDictionary = other;
  if ((_valueSet[0] != otherDictionary->_valueSet[0]) ||
      (_valueSet[1] != otherDictionary->_valueSet[1])) {
    return NO;
  }
  if ((_valueSet[0] && (_values[0] != otherDictionary->_values[0])) ||
      (_valueSet[1] && (_values[1] != otherDictionary->_values[1]))) {
    return NO;
  }
  return YES;
}

- (NSUInteger)hash {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p> {", [self class], self];
  if (_valueSet[0]) {
    [result appendFormat:@"NO: %d", _values[0]];
  }
  if (_valueSet[1]) {
    [result appendFormat:@"YES: %d", _values[1]];
  }
  [result appendString:@" }"];
  return result;
}

- (NSUInteger)count {
  return (_valueSet[0] ? 1 : 0) + (_valueSet[1] ? 1 : 0);
}

- (BOOL)getEnum:(int32_t*)value forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (value) {
      int32_t result = _values[idx];
      if (!_validationFunc(result)) {
        result = kACGPBUnrecognizedEnumeratorValue;
      }
      *value = result;
    }
    return YES;
  }
  return NO;
}

- (BOOL)getRawValue:(int32_t*)rawValue forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  if (_valueSet[idx]) {
    if (rawValue) {
      *rawValue = _values[idx];
    }
    return YES;
  }
  return NO;
}

- (void)enumerateKeysAndRawValuesUsingBlock:
    (void (NS_NOESCAPE ^)(BOOL key, int32_t value, BOOL *stop))block {
  BOOL stop = NO;
  if (_valueSet[0]) {
    block(NO, _values[0], &stop);
  }
  if (!stop && _valueSet[1]) {
    block(YES, _values[1], &stop);
  }
}

- (void)enumerateKeysAndEnumsUsingBlock:
    (void (NS_NOESCAPE ^)(BOOL key, int32_t rawValue, BOOL *stop))block {
  BOOL stop = NO;
  ACGPBEnumValidationFunc func = _validationFunc;
  int32_t validatedValue;
  if (_valueSet[0]) {
    validatedValue = _values[0];
    if (!func(validatedValue)) {
      validatedValue = kACGPBUnrecognizedEnumeratorValue;
    }
    block(NO, validatedValue, &stop);
  }
  if (!stop && _valueSet[1]) {
    validatedValue = _values[1];
    if (!func(validatedValue)) {
      validatedValue = kACGPBUnrecognizedEnumeratorValue;
    }
    block(YES, validatedValue, &stop);
  }
}

//%PDDM-EXPAND SERIAL_DATA_FOR_ENTRY_POD_Enum(Bool)
// This block of code is generated, do not edit it directly.
// clang-format off

- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(ACGPBGenericValue *)key
                              keyDataType:(ACGPBDataType)keyDataType {
  size_t msgSize = ComputeDictBoolFieldSize(key->valueBool, kMapKeyFieldNumber, keyDataType);
  msgSize += ComputeDictEnumFieldSize(value, kMapValueFieldNumber, ACGPBDataTypeEnum);
  NSMutableData *data = [NSMutableData dataWithLength:msgSize];
  ACGPBCodedOutputStream *outputStream = [[ACGPBCodedOutputStream alloc] initWithData:data];
  WriteDictBoolField(outputStream, key->valueBool, kMapKeyFieldNumber, keyDataType);
  WriteDictEnumField(outputStream, value, kMapValueFieldNumber, ACGPBDataTypeEnum);
  [outputStream release];
  return data;
}

// clang-format on
//%PDDM-EXPAND-END SERIAL_DATA_FOR_ENTRY_POD_Enum(Bool)

- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  NSUInteger count = 0;
  size_t result = 0;
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      ++count;
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictInt32FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      result += ACGPBComputeRawVarint32SizeForInteger(msgSize) + msgSize;
    }
  }
  size_t tagSize = ACGPBComputeWireFormatTagSize(ACGPBFieldNumber(field), ACGPBDataTypeMessage);
  result += tagSize * count;
  return result;
}

- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field {
  ACGPBDataType valueDataType = ACGPBGetFieldDataType(field);
  uint32_t tag = ACGPBWireFormatMakeTag(ACGPBFieldNumber(field), ACGPBWireFormatLengthDelimited);
  for (int i = 0; i < 2; ++i) {
    if (_valueSet[i]) {
      // Write the tag.
      [outputStream writeInt32NoTag:tag];
      // Write the size of the message.
      size_t msgSize = ComputeDictBoolFieldSize((i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      msgSize += ComputeDictInt32FieldSize(_values[i], kMapValueFieldNumber, valueDataType);
      [outputStream writeInt32NoTag:(int32_t)msgSize];
      // Write the fields.
      WriteDictBoolField(outputStream, (i == 1), kMapKeyFieldNumber, ACGPBDataTypeBool);
      WriteDictInt32Field(outputStream, _values[i], kMapValueFieldNumber, valueDataType);
    }
  }
}

- (void)enumerateForTextFormat:(void (NS_NOESCAPE ^)(id keyObj, id valueObj))block {
  if (_valueSet[0]) {
    block(@"false", @(_values[0]));
  }
  if (_valueSet[1]) {
    block(@"true", @(_values[1]));
  }
}

- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key {
  int idx = (key->valueBool ? 1 : 0);
  _values[idx] = value->valueInt32;
  _valueSet[idx] = YES;
}

- (void)addRawEntriesFromDictionary:(ACGPBBoolEnumDictionary *)otherDictionary {
  if (otherDictionary) {
    for (int i = 0; i < 2; ++i) {
      if (otherDictionary->_valueSet[i]) {
        _valueSet[i] = YES;
        _values[i] = otherDictionary->_values[i];
      }
    }
    if (_autocreator) {
      ACGPBAutocreatedDictionaryModified(_autocreator, self);
    }
  }
}

- (void)setEnum:(int32_t)value forKey:(BOOL)key {
  if (!_validationFunc(value)) {
    [NSException raise:NSInvalidArgumentException
                format:@"ACGPBBoolEnumDictionary: Attempt to set an unknown enum value (%d)",
     value];
  }
  int idx = (key ? 1 : 0);
  _values[idx] = value;
  _valueSet[idx] = YES;
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)setRawValue:(int32_t)rawValue forKey:(BOOL)key {
  int idx = (key ? 1 : 0);
  _values[idx] = rawValue;
  _valueSet[idx] = YES;
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeEnumForKey:(BOOL)aKey {
  _valueSet[aKey ? 1 : 0] = NO;
}

- (void)removeAll {
  _valueSet[0] = NO;
  _valueSet[1] = NO;
}

@end

#pragma mark - NSDictionary Subclass

@implementation ACGPBAutocreatedDictionary {
  NSMutableDictionary *_dictionary;
}

- (void)dealloc {
  NSAssert(!_autocreator,
           @"%@: Autocreator must be cleared before release, autocreator: %@",
           [self class], _autocreator);
  [_dictionary release];
  [super dealloc];
}

#pragma mark Required NSDictionary overrides

- (instancetype)initWithObjects:(const id [])objects
                        forKeys:(const id<NSCopying> [])keys
                          count:(NSUInteger)count {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] initWithObjects:objects
                                                       forKeys:keys
                                                         count:count];
  }
  return self;
}

- (NSUInteger)count {
  return [_dictionary count];
}

- (id)objectForKey:(id)aKey {
  return [_dictionary objectForKey:aKey];
}

- (NSEnumerator *)keyEnumerator {
  if (_dictionary == nil) {
    _dictionary = [[NSMutableDictionary alloc] init];
  }
  return [_dictionary keyEnumerator];
}

#pragma mark Required NSMutableDictionary overrides

// Only need to call ACGPBAutocreatedDictionaryModified() when adding things
// since we only autocreate empty dictionaries.

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
  if (_dictionary == nil) {
    _dictionary = [[NSMutableDictionary alloc] init];
  }
  [_dictionary setObject:anObject forKey:aKey];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)removeObjectForKey:(id)aKey {
  [_dictionary removeObjectForKey:aKey];
}

#pragma mark Extra things hooked

- (id)copyWithZone:(NSZone *)zone {
  if (_dictionary == nil) {
    return [[NSMutableDictionary allocWithZone:zone] init];
  }
  return [_dictionary copyWithZone:zone];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
  if (_dictionary == nil) {
    return [[NSMutableDictionary allocWithZone:zone] init];
  }
  return [_dictionary mutableCopyWithZone:zone];
}

// Not really needed, but subscripting is likely common enough it doesn't hurt
// to ensure it goes directly to the real NSMutableDictionary.
- (id)objectForKeyedSubscript:(id)key {
  return [_dictionary objectForKeyedSubscript:key];
}

// Not really needed, but subscripting is likely common enough it doesn't hurt
// to ensure it goes directly to the real NSMutableDictionary.
- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
  if (_dictionary == nil) {
    _dictionary = [[NSMutableDictionary alloc] init];
  }
  [_dictionary setObject:obj forKeyedSubscript:key];
  if (_autocreator) {
    ACGPBAutocreatedDictionaryModified(_autocreator, self);
  }
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (NS_NOESCAPE ^)(id key,
                                                    id obj,
                                                    BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsUsingBlock:block];
}

- (void)enumerateKeysAndObjectsWithOptions:(NSEnumerationOptions)opts
                                usingBlock:(void (NS_NOESCAPE ^)(id key,
                                                     id obj,
                                                     BOOL *stop))block {
  [_dictionary enumerateKeysAndObjectsWithOptions:opts usingBlock:block];
}

@end

#pragma clang diagnostic pop
