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

#import "ACGPBCodedInputStream_PackagePrivate.h"

#import "ACGPBDictionary_PackagePrivate.h"
#import "ACGPBMessage_PackagePrivate.h"
#import "ACGPBUnknownFieldSet_PackagePrivate.h"
#import "ACGPBUtilities_PackagePrivate.h"
#import "ACGPBWireFormat.h"

NSString *const ACGPBCodedInputStreamException =
    ACGPBNSStringifySymbol(ACGPBCodedInputStreamException);

NSString *const ACGPBCodedInputStreamUnderlyingErrorKey =
    ACGPBNSStringifySymbol(ACGPBCodedInputStreamUnderlyingErrorKey);

NSString *const ACGPBCodedInputStreamErrorDomain =
    ACGPBNSStringifySymbol(ACGPBCodedInputStreamErrorDomain);

// Matching:
// https://github.com/protocolbuffers/protobuf/blob/main/java/core/src/main/java/com/google/protobuf/CodedInputStream.java#L62
//  private static final int DEFAULT_RECURSION_LIMIT = 100;
// https://github.com/protocolbuffers/protobuf/blob/main/src/google/protobuf/io/coded_stream.cc#L86
//  int CodedInputStream::default_recursion_limit_ = 100;
static const NSUInteger kDefaultRecursionLimit = 100;

static void RaiseException(NSInteger code, NSString *reason) {
  NSDictionary *errorInfo = nil;
  if ([reason length]) {
    errorInfo = @{ ACGPBErrorReasonKey: reason };
  }
  NSError *error = [NSError errorWithDomain:ACGPBCodedInputStreamErrorDomain
                                       code:code
                                   userInfo:errorInfo];

  NSDictionary *exceptionInfo =
      @{ ACGPBCodedInputStreamUnderlyingErrorKey: error };
  [[NSException exceptionWithName:ACGPBCodedInputStreamException
                           reason:reason
                         userInfo:exceptionInfo] raise];
}

static void CheckRecursionLimit(ACGPBCodedInputStreamState *state) {
  if (state->recursionDepth >= kDefaultRecursionLimit) {
    RaiseException(ACGPBCodedInputStreamErrorRecursionDepthExceeded, nil);
  }
}

static void CheckSize(ACGPBCodedInputStreamState *state, size_t size) {
  size_t newSize = state->bufferPos + size;
  if (newSize > state->bufferSize) {
    RaiseException(ACGPBCodedInputStreamErrorInvalidSize, nil);
  }
  if (newSize > state->currentLimit) {
    // Fast forward to end of currentLimit;
    state->bufferPos = state->currentLimit;
    RaiseException(ACGPBCodedInputStreamErrorSubsectionLimitReached, nil);
  }
}

static int8_t ReadRawByte(ACGPBCodedInputStreamState *state) {
  CheckSize(state, sizeof(int8_t));
  return ((int8_t *)state->bytes)[state->bufferPos++];
}

static int32_t ReadRawLittleEndian32(ACGPBCodedInputStreamState *state) {
  CheckSize(state, sizeof(int32_t));
  // Not using OSReadLittleInt32 because it has undocumented dependency
  // on reads being aligned.
  int32_t value;
  memcpy(&value, state->bytes + state->bufferPos, sizeof(int32_t));
  value = OSSwapLittleToHostInt32(value);
  state->bufferPos += sizeof(int32_t);
  return value;
}

static int64_t ReadRawLittleEndian64(ACGPBCodedInputStreamState *state) {
  CheckSize(state, sizeof(int64_t));
  // Not using OSReadLittleInt64 because it has undocumented dependency
  // on reads being aligned.  
  int64_t value;
  memcpy(&value, state->bytes + state->bufferPos, sizeof(int64_t));
  value = OSSwapLittleToHostInt64(value);
  state->bufferPos += sizeof(int64_t);
  return value;
}

static int64_t ReadRawVarint64(ACGPBCodedInputStreamState *state) {
  int32_t shift = 0;
  int64_t result = 0;
  while (shift < 64) {
    int8_t b = ReadRawByte(state);
    result |= (int64_t)((uint64_t)(b & 0x7F) << shift);
    if ((b & 0x80) == 0) {
      return result;
    }
    shift += 7;
  }
  RaiseException(ACGPBCodedInputStreamErrorInvalidVarInt, @"Invalid VarInt64");
  return 0;
}

static int32_t ReadRawVarint32(ACGPBCodedInputStreamState *state) {
  return (int32_t)ReadRawVarint64(state);
}

static void SkipRawData(ACGPBCodedInputStreamState *state, size_t size) {
  CheckSize(state, size);
  state->bufferPos += size;
}

double ACGPBCodedInputStreamReadDouble(ACGPBCodedInputStreamState *state) {
  int64_t value = ReadRawLittleEndian64(state);
  return ACGPBConvertInt64ToDouble(value);
}

float ACGPBCodedInputStreamReadFloat(ACGPBCodedInputStreamState *state) {
  int32_t value = ReadRawLittleEndian32(state);
  return ACGPBConvertInt32ToFloat(value);
}

uint64_t ACGPBCodedInputStreamReadUInt64(ACGPBCodedInputStreamState *state) {
  uint64_t value = ReadRawVarint64(state);
  return value;
}

uint32_t ACGPBCodedInputStreamReadUInt32(ACGPBCodedInputStreamState *state) {
  uint32_t value = ReadRawVarint32(state);
  return value;
}

int64_t ACGPBCodedInputStreamReadInt64(ACGPBCodedInputStreamState *state) {
  int64_t value = ReadRawVarint64(state);
  return value;
}

int32_t ACGPBCodedInputStreamReadInt32(ACGPBCodedInputStreamState *state) {
  int32_t value = ReadRawVarint32(state);
  return value;
}

uint64_t ACGPBCodedInputStreamReadFixed64(ACGPBCodedInputStreamState *state) {
  uint64_t value = ReadRawLittleEndian64(state);
  return value;
}

uint32_t ACGPBCodedInputStreamReadFixed32(ACGPBCodedInputStreamState *state) {
  uint32_t value = ReadRawLittleEndian32(state);
  return value;
}

int32_t ACGPBCodedInputStreamReadEnum(ACGPBCodedInputStreamState *state) {
  int32_t value = ReadRawVarint32(state);
  return value;
}

int32_t ACGPBCodedInputStreamReadSFixed32(ACGPBCodedInputStreamState *state) {
  int32_t value = ReadRawLittleEndian32(state);
  return value;
}

int64_t ACGPBCodedInputStreamReadSFixed64(ACGPBCodedInputStreamState *state) {
  int64_t value = ReadRawLittleEndian64(state);
  return value;
}

int32_t ACGPBCodedInputStreamReadSInt32(ACGPBCodedInputStreamState *state) {
  int32_t value = ACGPBDecodeZigZag32(ReadRawVarint32(state));
  return value;
}

int64_t ACGPBCodedInputStreamReadSInt64(ACGPBCodedInputStreamState *state) {
  int64_t value = ACGPBDecodeZigZag64(ReadRawVarint64(state));
  return value;
}

BOOL ACGPBCodedInputStreamReadBool(ACGPBCodedInputStreamState *state) {
  return ReadRawVarint64(state) != 0;
}

int32_t ACGPBCodedInputStreamReadTag(ACGPBCodedInputStreamState *state) {
  if (ACGPBCodedInputStreamIsAtEnd(state)) {
    state->lastTag = 0;
    return 0;
  }

  state->lastTag = ReadRawVarint32(state);
  // Tags have to include a valid wireformat.
  if (!ACGPBWireFormatIsValidTag(state->lastTag)) {
    RaiseException(ACGPBCodedInputStreamErrorInvalidTag,
                   @"Invalid wireformat in tag.");
  }
  // Zero is not a valid field number.
  if (ACGPBWireFormatGetTagFieldNumber(state->lastTag) == 0) {
    RaiseException(ACGPBCodedInputStreamErrorInvalidTag,
                   @"A zero field number on the wire is invalid.");
  }
  return state->lastTag;
}

NSString *ACGPBCodedInputStreamReadRetainedString(
    ACGPBCodedInputStreamState *state) {
  int32_t size = ReadRawVarint32(state);
  NSString *result;
  if (size == 0) {
    result = @"";
  } else {
    CheckSize(state, size);
    result = [[NSString alloc] initWithBytes:&state->bytes[state->bufferPos]
                                      length:size
                                    encoding:NSUTF8StringEncoding];
    state->bufferPos += size;
    if (!result) {
#ifdef DEBUG
      // https://developers.google.com/protocol-buffers/docs/proto#scalar
      NSLog(@"UTF-8 failure, is some field type 'string' when it should be "
            @"'bytes'?");
#endif
      RaiseException(ACGPBCodedInputStreamErrorInvalidUTF8, nil);
    }
  }
  return result;
}

NSData *ACGPBCodedInputStreamReadRetainedBytes(ACGPBCodedInputStreamState *state) {
  int32_t size = ReadRawVarint32(state);
  if (size < 0) return nil;
  CheckSize(state, size);
  NSData *result = [[NSData alloc] initWithBytes:state->bytes + state->bufferPos
                                          length:size];
  state->bufferPos += size;
  return result;
}

NSData *ACGPBCodedInputStreamReadRetainedBytesNoCopy(
    ACGPBCodedInputStreamState *state) {
  int32_t size = ReadRawVarint32(state);
  if (size < 0) return nil;
  CheckSize(state, size);
  // Cast is safe because freeWhenDone is NO.
  NSData *result = [[NSData alloc]
      initWithBytesNoCopy:(void *)(state->bytes + state->bufferPos)
                   length:size
             freeWhenDone:NO];
  state->bufferPos += size;
  return result;
}

size_t ACGPBCodedInputStreamPushLimit(ACGPBCodedInputStreamState *state,
                                    size_t byteLimit) {
  byteLimit += state->bufferPos;
  size_t oldLimit = state->currentLimit;
  if (byteLimit > oldLimit) {
    RaiseException(ACGPBCodedInputStreamErrorInvalidSubsectionLimit, nil);
  }
  state->currentLimit = byteLimit;
  return oldLimit;
}

void ACGPBCodedInputStreamPopLimit(ACGPBCodedInputStreamState *state,
                                 size_t oldLimit) {
  state->currentLimit = oldLimit;
}

size_t ACGPBCodedInputStreamBytesUntilLimit(ACGPBCodedInputStreamState *state) {
  return state->currentLimit - state->bufferPos;
}

BOOL ACGPBCodedInputStreamIsAtEnd(ACGPBCodedInputStreamState *state) {
  return (state->bufferPos == state->bufferSize) ||
         (state->bufferPos == state->currentLimit);
}

void ACGPBCodedInputStreamCheckLastTagWas(ACGPBCodedInputStreamState *state,
                                        int32_t value) {
  if (state->lastTag != value) {
    RaiseException(ACGPBCodedInputStreamErrorInvalidTag, @"Unexpected tag read");
  }
}

@implementation ACGPBCodedInputStream

+ (instancetype)streamWithData:(NSData *)data {
  return [[[self alloc] initWithData:data] autorelease];
}

- (instancetype)initWithData:(NSData *)data {
  if ((self = [super init])) {
#ifdef DEBUG
    NSCAssert([self class] == [ACGPBCodedInputStream class],
              @"Subclassing of ACGPBCodedInputStream is not allowed.");
#endif
    buffer_ = [data retain];
    state_.bytes = (const uint8_t *)[data bytes];
    state_.bufferSize = [data length];
    state_.currentLimit = state_.bufferSize;
  }
  return self;
}

- (void)dealloc {
  [buffer_ release];
  [super dealloc];
}

// Direct access is use for speed, to avoid even internally declaring things
// read/write, etc. The warning is enabled in the project to ensure code calling
// protos can turn on -Wdirect-ivar-access without issues.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

- (int32_t)readTag {
  return ACGPBCodedInputStreamReadTag(&state_);
}

- (void)checkLastTagWas:(int32_t)value {
  ACGPBCodedInputStreamCheckLastTagWas(&state_, value);
}

- (BOOL)skipField:(int32_t)tag {
  NSAssert(ACGPBWireFormatIsValidTag(tag), @"Invalid tag");
  switch (ACGPBWireFormatGetTagWireType(tag)) {
    case ACGPBWireFormatVarint:
      ACGPBCodedInputStreamReadInt32(&state_);
      return YES;
    case ACGPBWireFormatFixed64:
      SkipRawData(&state_, sizeof(int64_t));
      return YES;
    case ACGPBWireFormatLengthDelimited:
      SkipRawData(&state_, ReadRawVarint32(&state_));
      return YES;
    case ACGPBWireFormatStartGroup:
      [self skipMessage];
      ACGPBCodedInputStreamCheckLastTagWas(
          &state_, ACGPBWireFormatMakeTag(ACGPBWireFormatGetTagFieldNumber(tag),
                                        ACGPBWireFormatEndGroup));
      return YES;
    case ACGPBWireFormatEndGroup:
      return NO;
    case ACGPBWireFormatFixed32:
      SkipRawData(&state_, sizeof(int32_t));
      return YES;
  }
}

- (void)skipMessage {
  while (YES) {
    int32_t tag = ACGPBCodedInputStreamReadTag(&state_);
    if (tag == 0 || ![self skipField:tag]) {
      return;
    }
  }
}

- (BOOL)isAtEnd {
  return ACGPBCodedInputStreamIsAtEnd(&state_);
}

- (size_t)position {
  return state_.bufferPos;
}

- (size_t)pushLimit:(size_t)byteLimit {
  return ACGPBCodedInputStreamPushLimit(&state_, byteLimit);
}

- (void)popLimit:(size_t)oldLimit {
  ACGPBCodedInputStreamPopLimit(&state_, oldLimit);
}

- (double)readDouble {
  return ACGPBCodedInputStreamReadDouble(&state_);
}

- (float)readFloat {
  return ACGPBCodedInputStreamReadFloat(&state_);
}

- (uint64_t)readUInt64 {
  return ACGPBCodedInputStreamReadUInt64(&state_);
}

- (int64_t)readInt64 {
  return ACGPBCodedInputStreamReadInt64(&state_);
}

- (int32_t)readInt32 {
  return ACGPBCodedInputStreamReadInt32(&state_);
}

- (uint64_t)readFixed64 {
  return ACGPBCodedInputStreamReadFixed64(&state_);
}

- (uint32_t)readFixed32 {
  return ACGPBCodedInputStreamReadFixed32(&state_);
}

- (BOOL)readBool {
  return ACGPBCodedInputStreamReadBool(&state_);
}

- (NSString *)readString {
  return [ACGPBCodedInputStreamReadRetainedString(&state_) autorelease];
}

- (void)readGroup:(int32_t)fieldNumber
              message:(ACGPBMessage *)message
    extensionRegistry:(ACGPBExtensionRegistry *)extensionRegistry {
  CheckRecursionLimit(&state_);
  ++state_.recursionDepth;
  [message mergeFromCodedInputStream:self extensionRegistry:extensionRegistry];
  ACGPBCodedInputStreamCheckLastTagWas(
      &state_, ACGPBWireFormatMakeTag(fieldNumber, ACGPBWireFormatEndGroup));
  --state_.recursionDepth;
}

- (void)readUnknownGroup:(int32_t)fieldNumber
                 message:(ACGPBUnknownFieldSet *)message {
  CheckRecursionLimit(&state_);
  ++state_.recursionDepth;
  [message mergeFromCodedInputStream:self];
  ACGPBCodedInputStreamCheckLastTagWas(
      &state_, ACGPBWireFormatMakeTag(fieldNumber, ACGPBWireFormatEndGroup));
  --state_.recursionDepth;
}

- (void)readMessage:(ACGPBMessage *)message
    extensionRegistry:(ACGPBExtensionRegistry *)extensionRegistry {
  CheckRecursionLimit(&state_);
  int32_t length = ReadRawVarint32(&state_);
  size_t oldLimit = ACGPBCodedInputStreamPushLimit(&state_, length);
  ++state_.recursionDepth;
  [message mergeFromCodedInputStream:self extensionRegistry:extensionRegistry];
  ACGPBCodedInputStreamCheckLastTagWas(&state_, 0);
  --state_.recursionDepth;
  ACGPBCodedInputStreamPopLimit(&state_, oldLimit);
}

- (void)readMapEntry:(id)mapDictionary
    extensionRegistry:(ACGPBExtensionRegistry *)extensionRegistry
                field:(ACGPBFieldDescriptor *)field
        parentMessage:(ACGPBMessage *)parentMessage {
  CheckRecursionLimit(&state_);
  int32_t length = ReadRawVarint32(&state_);
  size_t oldLimit = ACGPBCodedInputStreamPushLimit(&state_, length);
  ++state_.recursionDepth;
  ACGPBDictionaryReadEntry(mapDictionary, self, extensionRegistry, field,
                         parentMessage);
  ACGPBCodedInputStreamCheckLastTagWas(&state_, 0);
  --state_.recursionDepth;
  ACGPBCodedInputStreamPopLimit(&state_, oldLimit);
}

- (NSData *)readBytes {
  return [ACGPBCodedInputStreamReadRetainedBytes(&state_) autorelease];
}

- (uint32_t)readUInt32 {
  return ACGPBCodedInputStreamReadUInt32(&state_);
}

- (int32_t)readEnum {
  return ACGPBCodedInputStreamReadEnum(&state_);
}

- (int32_t)readSFixed32 {
  return ACGPBCodedInputStreamReadSFixed32(&state_);
}

- (int64_t)readSFixed64 {
  return ACGPBCodedInputStreamReadSFixed64(&state_);
}

- (int32_t)readSInt32 {
  return ACGPBCodedInputStreamReadSInt32(&state_);
}

- (int64_t)readSInt64 {
  return ACGPBCodedInputStreamReadSInt64(&state_);
}

#pragma clang diagnostic pop

@end
