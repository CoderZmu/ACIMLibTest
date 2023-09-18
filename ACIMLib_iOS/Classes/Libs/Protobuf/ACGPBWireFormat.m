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

#import "ACGPBWireFormat.h"

#import "ACGPBUtilities_PackagePrivate.h"

enum {
  ACGPBWireFormatTagTypeBits = 3,
  ACGPBWireFormatTagTypeMask = 7 /* = (1 << ACGPBWireFormatTagTypeBits) - 1 */,
};

uint32_t ACGPBWireFormatMakeTag(uint32_t fieldNumber, ACGPBWireFormat wireType) {
  return (fieldNumber << ACGPBWireFormatTagTypeBits) | wireType;
}

ACGPBWireFormat ACGPBWireFormatGetTagWireType(uint32_t tag) {
  return (ACGPBWireFormat)(tag & ACGPBWireFormatTagTypeMask);
}

uint32_t ACGPBWireFormatGetTagFieldNumber(uint32_t tag) {
  return ACGPBLogicalRightShift32(tag, ACGPBWireFormatTagTypeBits);
}

BOOL ACGPBWireFormatIsValidTag(uint32_t tag) {
  uint32_t formatBits = (tag & ACGPBWireFormatTagTypeMask);
  // The valid ACGPBWireFormat* values are 0-5, anything else is not a valid tag.
  BOOL result = (formatBits <= 5);
  return result;
}

ACGPBWireFormat ACGPBWireFormatForType(ACGPBDataType type, BOOL isPacked) {
  if (isPacked) {
    return ACGPBWireFormatLengthDelimited;
  }

  static const ACGPBWireFormat format[ACGPBDataType_Count] = {
      ACGPBWireFormatVarint,           // ACGPBDataTypeBool
      ACGPBWireFormatFixed32,          // ACGPBDataTypeFixed32
      ACGPBWireFormatFixed32,          // ACGPBDataTypeSFixed32
      ACGPBWireFormatFixed32,          // ACGPBDataTypeFloat
      ACGPBWireFormatFixed64,          // ACGPBDataTypeFixed64
      ACGPBWireFormatFixed64,          // ACGPBDataTypeSFixed64
      ACGPBWireFormatFixed64,          // ACGPBDataTypeDouble
      ACGPBWireFormatVarint,           // ACGPBDataTypeInt32
      ACGPBWireFormatVarint,           // ACGPBDataTypeInt64
      ACGPBWireFormatVarint,           // ACGPBDataTypeSInt32
      ACGPBWireFormatVarint,           // ACGPBDataTypeSInt64
      ACGPBWireFormatVarint,           // ACGPBDataTypeUInt32
      ACGPBWireFormatVarint,           // ACGPBDataTypeUInt64
      ACGPBWireFormatLengthDelimited,  // ACGPBDataTypeBytes
      ACGPBWireFormatLengthDelimited,  // ACGPBDataTypeString
      ACGPBWireFormatLengthDelimited,  // ACGPBDataTypeMessage
      ACGPBWireFormatStartGroup,       // ACGPBDataTypeGroup
      ACGPBWireFormatVarint            // ACGPBDataTypeEnum
  };
  return format[type];
}
