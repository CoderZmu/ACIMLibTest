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

#import "ACGPBExtensionInternals.h"

#import <objc/runtime.h>

#import "ACGPBCodedInputStream_PackagePrivate.h"
#import "ACGPBCodedOutputStream_PackagePrivate.h"
#import "ACGPBDescriptor_PackagePrivate.h"
#import "ACGPBMessage_PackagePrivate.h"
#import "ACGPBUtilities_PackagePrivate.h"

static id NewSingleValueFromInputStream(ACGPBExtensionDescriptor *extension,
                                        ACGPBCodedInputStream *input,
                                        ACGPBExtensionRegistry *extensionRegistry,
                                        ACGPBMessage *existingValue)
    __attribute__((ns_returns_retained));

ACGPB_INLINE size_t DataTypeSize(ACGPBDataType dataType) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
  switch (dataType) {
    case ACGPBDataTypeBool:
      return 1;
    case ACGPBDataTypeFixed32:
    case ACGPBDataTypeSFixed32:
    case ACGPBDataTypeFloat:
      return 4;
    case ACGPBDataTypeFixed64:
    case ACGPBDataTypeSFixed64:
    case ACGPBDataTypeDouble:
      return 8;
    default:
      return 0;
  }
#pragma clang diagnostic pop
}

static size_t ComputePBSerializedSizeNoTagOfObject(ACGPBDataType dataType, id object) {
#define FIELD_CASE(TYPE, ACCESSOR)                                     \
  case ACGPBDataType##TYPE:                                              \
    return ACGPBCompute##TYPE##SizeNoTag([(NSNumber *)object ACCESSOR]);
#define FIELD_CASE2(TYPE)                                              \
  case ACGPBDataType##TYPE:                                              \
    return ACGPBCompute##TYPE##SizeNoTag(object);
  switch (dataType) {
    FIELD_CASE(Bool, boolValue)
    FIELD_CASE(Float, floatValue)
    FIELD_CASE(Double, doubleValue)
    FIELD_CASE(Int32, intValue)
    FIELD_CASE(SFixed32, intValue)
    FIELD_CASE(SInt32, intValue)
    FIELD_CASE(Enum, intValue)
    FIELD_CASE(Int64, longLongValue)
    FIELD_CASE(SInt64, longLongValue)
    FIELD_CASE(SFixed64, longLongValue)
    FIELD_CASE(UInt32, unsignedIntValue)
    FIELD_CASE(Fixed32, unsignedIntValue)
    FIELD_CASE(UInt64, unsignedLongLongValue)
    FIELD_CASE(Fixed64, unsignedLongLongValue)
    FIELD_CASE2(Bytes)
    FIELD_CASE2(String)
    FIELD_CASE2(Message)
    FIELD_CASE2(Group)
  }
#undef FIELD_CASE
#undef FIELD_CASE2
}

static size_t ComputeSerializedSizeIncludingTagOfObject(
    ACGPBExtensionDescription *description, id object) {
#define FIELD_CASE(TYPE, ACCESSOR)                                   \
  case ACGPBDataType##TYPE:                                            \
    return ACGPBCompute##TYPE##Size(description->fieldNumber,          \
                                  [(NSNumber *)object ACCESSOR]);
#define FIELD_CASE2(TYPE)                                            \
  case ACGPBDataType##TYPE:                                            \
    return ACGPBCompute##TYPE##Size(description->fieldNumber, object);
  switch (description->dataType) {
    FIELD_CASE(Bool, boolValue)
    FIELD_CASE(Float, floatValue)
    FIELD_CASE(Double, doubleValue)
    FIELD_CASE(Int32, intValue)
    FIELD_CASE(SFixed32, intValue)
    FIELD_CASE(SInt32, intValue)
    FIELD_CASE(Enum, intValue)
    FIELD_CASE(Int64, longLongValue)
    FIELD_CASE(SInt64, longLongValue)
    FIELD_CASE(SFixed64, longLongValue)
    FIELD_CASE(UInt32, unsignedIntValue)
    FIELD_CASE(Fixed32, unsignedIntValue)
    FIELD_CASE(UInt64, unsignedLongLongValue)
    FIELD_CASE(Fixed64, unsignedLongLongValue)
    FIELD_CASE2(Bytes)
    FIELD_CASE2(String)
    FIELD_CASE2(Group)
    case ACGPBDataTypeMessage:
      if (ACGPBExtensionIsWireFormat(description)) {
        return ACGPBComputeMessageSetExtensionSize(description->fieldNumber,
                                                 object);
      } else {
        return ACGPBComputeMessageSize(description->fieldNumber, object);
      }
  }
#undef FIELD_CASE
#undef FIELD_CASE2
}

static size_t ComputeSerializedSizeIncludingTagOfArray(
    ACGPBExtensionDescription *description, NSArray *values) {
  if (ACGPBExtensionIsPacked(description)) {
    size_t size = 0;
    size_t typeSize = DataTypeSize(description->dataType);
    if (typeSize != 0) {
      size = values.count * typeSize;
    } else {
      for (id value in values) {
        size +=
            ComputePBSerializedSizeNoTagOfObject(description->dataType, value);
      }
    }
    return size + ACGPBComputeTagSize(description->fieldNumber) +
           ACGPBComputeRawVarint32SizeForInteger(size);
  } else {
    size_t size = 0;
    for (id value in values) {
      size += ComputeSerializedSizeIncludingTagOfObject(description, value);
    }
    return size;
  }
}

static void WriteObjectIncludingTagToCodedOutputStream(
    id object, ACGPBExtensionDescription *description,
    ACGPBCodedOutputStream *output) {
#define FIELD_CASE(TYPE, ACCESSOR)                      \
  case ACGPBDataType##TYPE:                               \
    [output write##TYPE:description->fieldNumber        \
                  value:[(NSNumber *)object ACCESSOR]]; \
    return;
#define FIELD_CASE2(TYPE)                                       \
  case ACGPBDataType##TYPE:                                       \
    [output write##TYPE:description->fieldNumber value:object]; \
    return;
  switch (description->dataType) {
    FIELD_CASE(Bool, boolValue)
    FIELD_CASE(Float, floatValue)
    FIELD_CASE(Double, doubleValue)
    FIELD_CASE(Int32, intValue)
    FIELD_CASE(SFixed32, intValue)
    FIELD_CASE(SInt32, intValue)
    FIELD_CASE(Enum, intValue)
    FIELD_CASE(Int64, longLongValue)
    FIELD_CASE(SInt64, longLongValue)
    FIELD_CASE(SFixed64, longLongValue)
    FIELD_CASE(UInt32, unsignedIntValue)
    FIELD_CASE(Fixed32, unsignedIntValue)
    FIELD_CASE(UInt64, unsignedLongLongValue)
    FIELD_CASE(Fixed64, unsignedLongLongValue)
    FIELD_CASE2(Bytes)
    FIELD_CASE2(String)
    FIELD_CASE2(Group)
    case ACGPBDataTypeMessage:
      if (ACGPBExtensionIsWireFormat(description)) {
        [output writeMessageSetExtension:description->fieldNumber value:object];
      } else {
        [output writeMessage:description->fieldNumber value:object];
      }
      return;
  }
#undef FIELD_CASE
#undef FIELD_CASE2
}

static void WriteObjectNoTagToCodedOutputStream(
    id object, ACGPBExtensionDescription *description,
    ACGPBCodedOutputStream *output) {
#define FIELD_CASE(TYPE, ACCESSOR)                             \
  case ACGPBDataType##TYPE:                                      \
    [output write##TYPE##NoTag:[(NSNumber *)object ACCESSOR]]; \
    return;
#define FIELD_CASE2(TYPE)               \
  case ACGPBDataType##TYPE:               \
    [output write##TYPE##NoTag:object]; \
    return;
  switch (description->dataType) {
    FIELD_CASE(Bool, boolValue)
    FIELD_CASE(Float, floatValue)
    FIELD_CASE(Double, doubleValue)
    FIELD_CASE(Int32, intValue)
    FIELD_CASE(SFixed32, intValue)
    FIELD_CASE(SInt32, intValue)
    FIELD_CASE(Enum, intValue)
    FIELD_CASE(Int64, longLongValue)
    FIELD_CASE(SInt64, longLongValue)
    FIELD_CASE(SFixed64, longLongValue)
    FIELD_CASE(UInt32, unsignedIntValue)
    FIELD_CASE(Fixed32, unsignedIntValue)
    FIELD_CASE(UInt64, unsignedLongLongValue)
    FIELD_CASE(Fixed64, unsignedLongLongValue)
    FIELD_CASE2(Bytes)
    FIELD_CASE2(String)
    FIELD_CASE2(Message)
    case ACGPBDataTypeGroup:
      [output writeGroupNoTag:description->fieldNumber value:object];
      return;
  }
#undef FIELD_CASE
#undef FIELD_CASE2
}

static void WriteArrayIncludingTagsToCodedOutputStream(
    NSArray *values, ACGPBExtensionDescription *description,
    ACGPBCodedOutputStream *output) {
  if (ACGPBExtensionIsPacked(description)) {
    [output writeTag:description->fieldNumber
              format:ACGPBWireFormatLengthDelimited];
    size_t dataSize = 0;
    size_t typeSize = DataTypeSize(description->dataType);
    if (typeSize != 0) {
      dataSize = values.count * typeSize;
    } else {
      for (id value in values) {
        dataSize +=
            ComputePBSerializedSizeNoTagOfObject(description->dataType, value);
      }
    }
    [output writeRawVarintSizeTAs32:dataSize];
    for (id value in values) {
      WriteObjectNoTagToCodedOutputStream(value, description, output);
    }
  } else {
    for (id value in values) {
      WriteObjectIncludingTagToCodedOutputStream(value, description, output);
    }
  }
}

// Direct access is use for speed, to avoid even internally declaring things
// read/write, etc. The warning is enabled in the project to ensure code calling
// protos can turn on -Wdirect-ivar-access without issues.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

void ACGPBExtensionMergeFromInputStream(ACGPBExtensionDescriptor *extension,
                                      BOOL isPackedOnStream,
                                      ACGPBCodedInputStream *input,
                                      ACGPBExtensionRegistry *extensionRegistry,
                                      ACGPBMessage *message) {
  ACGPBExtensionDescription *description = extension->description_;
  ACGPBCodedInputStreamState *state = &input->state_;
  if (isPackedOnStream) {
    NSCAssert(ACGPBExtensionIsRepeated(description),
              @"How was it packed if it isn't repeated?");
    int32_t length = ACGPBCodedInputStreamReadInt32(state);
    size_t limit = ACGPBCodedInputStreamPushLimit(state, length);
    while (ACGPBCodedInputStreamBytesUntilLimit(state) > 0) {
      id value = NewSingleValueFromInputStream(extension,
                                               input,
                                               extensionRegistry,
                                               nil);
      [message addExtension:extension value:value];
      [value release];
    }
    ACGPBCodedInputStreamPopLimit(state, limit);
  } else {
    id existingValue = nil;
    BOOL isRepeated = ACGPBExtensionIsRepeated(description);
    if (!isRepeated && ACGPBDataTypeIsMessage(description->dataType)) {
      existingValue = [message getExistingExtension:extension];
    }
    id value = NewSingleValueFromInputStream(extension,
                                             input,
                                             extensionRegistry,
                                             existingValue);
    if (isRepeated) {
      [message addExtension:extension value:value];
    } else {
      [message setExtension:extension value:value];
    }
    [value release];
  }
}

void ACGPBWriteExtensionValueToOutputStream(ACGPBExtensionDescriptor *extension,
                                          id value,
                                          ACGPBCodedOutputStream *output) {
  ACGPBExtensionDescription *description = extension->description_;
  if (ACGPBExtensionIsRepeated(description)) {
    WriteArrayIncludingTagsToCodedOutputStream(value, description, output);
  } else {
    WriteObjectIncludingTagToCodedOutputStream(value, description, output);
  }
}

size_t ACGPBComputeExtensionSerializedSizeIncludingTag(
    ACGPBExtensionDescriptor *extension, id value) {
  ACGPBExtensionDescription *description = extension->description_;
  if (ACGPBExtensionIsRepeated(description)) {
    return ComputeSerializedSizeIncludingTagOfArray(description, value);
  } else {
    return ComputeSerializedSizeIncludingTagOfObject(description, value);
  }
}

// Note that this returns a retained value intentionally.
static id NewSingleValueFromInputStream(ACGPBExtensionDescriptor *extension,
                                        ACGPBCodedInputStream *input,
                                        ACGPBExtensionRegistry *extensionRegistry,
                                        ACGPBMessage *existingValue) {
  ACGPBExtensionDescription *description = extension->description_;
  ACGPBCodedInputStreamState *state = &input->state_;
  switch (description->dataType) {
    case ACGPBDataTypeBool:     return [[NSNumber alloc] initWithBool:ACGPBCodedInputStreamReadBool(state)];
    case ACGPBDataTypeFixed32:  return [[NSNumber alloc] initWithUnsignedInt:ACGPBCodedInputStreamReadFixed32(state)];
    case ACGPBDataTypeSFixed32: return [[NSNumber alloc] initWithInt:ACGPBCodedInputStreamReadSFixed32(state)];
    case ACGPBDataTypeFloat:    return [[NSNumber alloc] initWithFloat:ACGPBCodedInputStreamReadFloat(state)];
    case ACGPBDataTypeFixed64:  return [[NSNumber alloc] initWithUnsignedLongLong:ACGPBCodedInputStreamReadFixed64(state)];
    case ACGPBDataTypeSFixed64: return [[NSNumber alloc] initWithLongLong:ACGPBCodedInputStreamReadSFixed64(state)];
    case ACGPBDataTypeDouble:   return [[NSNumber alloc] initWithDouble:ACGPBCodedInputStreamReadDouble(state)];
    case ACGPBDataTypeInt32:    return [[NSNumber alloc] initWithInt:ACGPBCodedInputStreamReadInt32(state)];
    case ACGPBDataTypeInt64:    return [[NSNumber alloc] initWithLongLong:ACGPBCodedInputStreamReadInt64(state)];
    case ACGPBDataTypeSInt32:   return [[NSNumber alloc] initWithInt:ACGPBCodedInputStreamReadSInt32(state)];
    case ACGPBDataTypeSInt64:   return [[NSNumber alloc] initWithLongLong:ACGPBCodedInputStreamReadSInt64(state)];
    case ACGPBDataTypeUInt32:   return [[NSNumber alloc] initWithUnsignedInt:ACGPBCodedInputStreamReadUInt32(state)];
    case ACGPBDataTypeUInt64:   return [[NSNumber alloc] initWithUnsignedLongLong:ACGPBCodedInputStreamReadUInt64(state)];
    case ACGPBDataTypeBytes:    return ACGPBCodedInputStreamReadRetainedBytes(state);
    case ACGPBDataTypeString:   return ACGPBCodedInputStreamReadRetainedString(state);
    case ACGPBDataTypeEnum:     return [[NSNumber alloc] initWithInt:ACGPBCodedInputStreamReadEnum(state)];
    case ACGPBDataTypeGroup:
    case ACGPBDataTypeMessage: {
      ACGPBMessage *message;
      if (existingValue) {
        message = [existingValue retain];
      } else {
        ACGPBDescriptor *descriptor = [extension.msgClass descriptor];
        message = [[descriptor.messageClass alloc] init];
      }

      if (description->dataType == ACGPBDataTypeGroup) {
        [input readGroup:description->fieldNumber
                 message:message
            extensionRegistry:extensionRegistry];
      } else {
        // description->dataType == ACGPBDataTypeMessage
        if (ACGPBExtensionIsWireFormat(description)) {
          // For MessageSet fields the message length will have already been
          // read.
          [message mergeFromCodedInputStream:input
                           extensionRegistry:extensionRegistry];
        } else {
          [input readMessage:message extensionRegistry:extensionRegistry];
        }
      }

      return message;
    }
  }

  return nil;
}

#pragma clang diagnostic pop
