// Protocol Buffers - Google's data interchange format
// Copyright 2016 Google Inc.  All rights reserved.
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

#import "ACGPBCodedOutputStream.h"

NS_ASSUME_NONNULL_BEGIN

CF_EXTERN_C_BEGIN

size_t ACGPBComputeDoubleSize(int32_t fieldNumber, double value)
    __attribute__((const));
size_t ACGPBComputeFloatSize(int32_t fieldNumber, float value)
    __attribute__((const));
size_t ACGPBComputeUInt64Size(int32_t fieldNumber, uint64_t value)
    __attribute__((const));
size_t ACGPBComputeInt64Size(int32_t fieldNumber, int64_t value)
    __attribute__((const));
size_t ACGPBComputeInt32Size(int32_t fieldNumber, int32_t value)
    __attribute__((const));
size_t ACGPBComputeFixed64Size(int32_t fieldNumber, uint64_t value)
    __attribute__((const));
size_t ACGPBComputeFixed32Size(int32_t fieldNumber, uint32_t value)
    __attribute__((const));
size_t ACGPBComputeBoolSize(int32_t fieldNumber, BOOL value)
    __attribute__((const));
size_t ACGPBComputeStringSize(int32_t fieldNumber, NSString *value)
    __attribute__((const));
size_t ACGPBComputeGroupSize(int32_t fieldNumber, ACGPBMessage *value)
    __attribute__((const));
size_t ACGPBComputeUnknownGroupSize(int32_t fieldNumber,
                                  ACGPBUnknownFieldSet *value)
    __attribute__((const));
size_t ACGPBComputeMessageSize(int32_t fieldNumber, ACGPBMessage *value)
    __attribute__((const));
size_t ACGPBComputeBytesSize(int32_t fieldNumber, NSData *value)
    __attribute__((const));
size_t ACGPBComputeUInt32Size(int32_t fieldNumber, uint32_t value)
    __attribute__((const));
size_t ACGPBComputeSFixed32Size(int32_t fieldNumber, int32_t value)
    __attribute__((const));
size_t ACGPBComputeSFixed64Size(int32_t fieldNumber, int64_t value)
    __attribute__((const));
size_t ACGPBComputeSInt32Size(int32_t fieldNumber, int32_t value)
    __attribute__((const));
size_t ACGPBComputeSInt64Size(int32_t fieldNumber, int64_t value)
    __attribute__((const));
size_t ACGPBComputeTagSize(int32_t fieldNumber) __attribute__((const));
size_t ACGPBComputeWireFormatTagSize(int field_number, ACGPBDataType dataType)
    __attribute__((const));

size_t ACGPBComputeDoubleSizeNoTag(double value) __attribute__((const));
size_t ACGPBComputeFloatSizeNoTag(float value) __attribute__((const));
size_t ACGPBComputeUInt64SizeNoTag(uint64_t value) __attribute__((const));
size_t ACGPBComputeInt64SizeNoTag(int64_t value) __attribute__((const));
size_t ACGPBComputeInt32SizeNoTag(int32_t value) __attribute__((const));
size_t ACGPBComputeFixed64SizeNoTag(uint64_t value) __attribute__((const));
size_t ACGPBComputeFixed32SizeNoTag(uint32_t value) __attribute__((const));
size_t ACGPBComputeBoolSizeNoTag(BOOL value) __attribute__((const));
size_t ACGPBComputeStringSizeNoTag(NSString *value) __attribute__((const));
size_t ACGPBComputeGroupSizeNoTag(ACGPBMessage *value) __attribute__((const));
size_t ACGPBComputeUnknownGroupSizeNoTag(ACGPBUnknownFieldSet *value)
    __attribute__((const));
size_t ACGPBComputeMessageSizeNoTag(ACGPBMessage *value) __attribute__((const));
size_t ACGPBComputeBytesSizeNoTag(NSData *value) __attribute__((const));
size_t ACGPBComputeUInt32SizeNoTag(int32_t value) __attribute__((const));
size_t ACGPBComputeEnumSizeNoTag(int32_t value) __attribute__((const));
size_t ACGPBComputeSFixed32SizeNoTag(int32_t value) __attribute__((const));
size_t ACGPBComputeSFixed64SizeNoTag(int64_t value) __attribute__((const));
size_t ACGPBComputeSInt32SizeNoTag(int32_t value) __attribute__((const));
size_t ACGPBComputeSInt64SizeNoTag(int64_t value) __attribute__((const));

// Note that this will calculate the size of 64 bit values truncated to 32.
size_t ACGPBComputeSizeTSizeAsInt32NoTag(size_t value) __attribute__((const));

size_t ACGPBComputeRawVarint32Size(int32_t value) __attribute__((const));
size_t ACGPBComputeRawVarint64Size(int64_t value) __attribute__((const));

// Note that this will calculate the size of 64 bit values truncated to 32.
size_t ACGPBComputeRawVarint32SizeForInteger(NSInteger value)
    __attribute__((const));

// Compute the number of bytes that would be needed to encode a
// MessageSet extension to the stream.  For historical reasons,
// the wire format differs from normal fields.
size_t ACGPBComputeMessageSetExtensionSize(int32_t fieldNumber, ACGPBMessage *value)
    __attribute__((const));

// Compute the number of bytes that would be needed to encode an
// unparsed MessageSet extension field to the stream.  For
// historical reasons, the wire format differs from normal fields.
size_t ACGPBComputeRawMessageSetExtensionSize(int32_t fieldNumber, NSData *value)
    __attribute__((const));

size_t ACGPBComputeEnumSize(int32_t fieldNumber, int32_t value)
    __attribute__((const));

CF_EXTERN_C_END

NS_ASSUME_NONNULL_END
