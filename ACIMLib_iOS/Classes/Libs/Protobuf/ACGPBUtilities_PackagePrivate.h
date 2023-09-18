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

#import <Foundation/Foundation.h>

#import "ACGPBUtilities.h"

#import "ACGPBDescriptor_PackagePrivate.h"

// Macros for stringifying library symbols. These are used in the generated
// ACGPB descriptor classes wherever a library symbol name is represented as a
// string.
#define ACGPBStringify(S) #S
#define ACGPBStringifySymbol(S) ACGPBStringify(S)

#define ACGPBNSStringify(S) @#S
#define ACGPBNSStringifySymbol(S) ACGPBNSStringify(S)

// Macros for generating a Class from a class name. These are used in
// the generated ACGPB descriptor classes wherever an Objective C class
// reference is needed for a generated class.
#define ACGPBObjCClassSymbol(name) OBJC_CLASS_$_##name
#define ACGPBObjCClass(name) \
    ((__bridge Class)&(ACGPBObjCClassSymbol(name)))
#define ACGPBObjCClassDeclaration(name) \
    extern const ACGPBObjcClass_t ACGPBObjCClassSymbol(name)

// Constant to internally mark when there is no has bit.
#define ACGPBNoHasBit INT32_MAX

CF_EXTERN_C_BEGIN

// These two are used to inject a runtime check for version mismatch into the
// generated sources to make sure they are linked with a supporting runtime.
void ACGPBCheckRuntimeVersionSupport(int32_t objcRuntimeVersion);
ACGPB_INLINE void ACGPB_DEBUG_CHECK_RUNTIME_VERSIONS() {
  // NOTE: By being inline here, this captures the value from the library's
  // headers at the time the generated code was compiled.
#if defined(DEBUG) && DEBUG
  ACGPBCheckRuntimeVersionSupport(GOOGLE_PROTOBUF_OBJC_VERSION);
#endif
}

// Legacy version of the checks, remove when GOOGLE_PROTOBUF_OBJC_GEN_VERSION
// goes away (see more info in ACGPBBootstrap.h).
void ACGPBCheckRuntimeVersionInternal(int32_t version);
ACGPB_INLINE void ACGPBDebugCheckRuntimeVersion() {
#if defined(DEBUG) && DEBUG
  ACGPBCheckRuntimeVersionInternal(GOOGLE_PROTOBUF_OBJC_GEN_VERSION);
#endif
}

// Conversion functions for de/serializing floating point types.

ACGPB_INLINE int64_t ACGPBConvertDoubleToInt64(double v) {
  ACGPBInternalCompileAssert(sizeof(double) == sizeof(int64_t), double_not_64_bits);
  int64_t result;
  memcpy(&result, &v, sizeof(result));
  return result;
}

ACGPB_INLINE int32_t ACGPBConvertFloatToInt32(float v) {
  ACGPBInternalCompileAssert(sizeof(float) == sizeof(int32_t), float_not_32_bits);
  int32_t result;
  memcpy(&result, &v, sizeof(result));
  return result;
}

ACGPB_INLINE double ACGPBConvertInt64ToDouble(int64_t v) {
  ACGPBInternalCompileAssert(sizeof(double) == sizeof(int64_t), double_not_64_bits);
  double result;
  memcpy(&result, &v, sizeof(result));
  return result;
}

ACGPB_INLINE float ACGPBConvertInt32ToFloat(int32_t v) {
  ACGPBInternalCompileAssert(sizeof(float) == sizeof(int32_t), float_not_32_bits);
  float result;
  memcpy(&result, &v, sizeof(result));
  return result;
}

ACGPB_INLINE int32_t ACGPBLogicalRightShift32(int32_t value, int32_t spaces) {
  return (int32_t)((uint32_t)(value) >> spaces);
}

ACGPB_INLINE int64_t ACGPBLogicalRightShift64(int64_t value, int32_t spaces) {
  return (int64_t)((uint64_t)(value) >> spaces);
}

// Decode a ZigZag-encoded 32-bit value.  ZigZag encodes signed integers
// into values that can be efficiently encoded with varint.  (Otherwise,
// negative values must be sign-extended to 64 bits to be varint encoded,
// thus always taking 10 bytes on the wire.)
ACGPB_INLINE int32_t ACGPBDecodeZigZag32(uint32_t n) {
  return (int32_t)(ACGPBLogicalRightShift32((int32_t)n, 1) ^ -((int32_t)(n) & 1));
}

// Decode a ZigZag-encoded 64-bit value.  ZigZag encodes signed integers
// into values that can be efficiently encoded with varint.  (Otherwise,
// negative values must be sign-extended to 64 bits to be varint encoded,
// thus always taking 10 bytes on the wire.)
ACGPB_INLINE int64_t ACGPBDecodeZigZag64(uint64_t n) {
  return (int64_t)(ACGPBLogicalRightShift64((int64_t)n, 1) ^ -((int64_t)(n) & 1));
}

// Encode a ZigZag-encoded 32-bit value.  ZigZag encodes signed integers
// into values that can be efficiently encoded with varint.  (Otherwise,
// negative values must be sign-extended to 64 bits to be varint encoded,
// thus always taking 10 bytes on the wire.)
ACGPB_INLINE uint32_t ACGPBEncodeZigZag32(int32_t n) {
  // Note:  the right-shift must be arithmetic
  return ((uint32_t)n << 1) ^ (uint32_t)(n >> 31);
}

// Encode a ZigZag-encoded 64-bit value.  ZigZag encodes signed integers
// into values that can be efficiently encoded with varint.  (Otherwise,
// negative values must be sign-extended to 64 bits to be varint encoded,
// thus always taking 10 bytes on the wire.)
ACGPB_INLINE uint64_t ACGPBEncodeZigZag64(int64_t n) {
  // Note:  the right-shift must be arithmetic
  return ((uint64_t)n << 1) ^ (uint64_t)(n >> 63);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

ACGPB_INLINE BOOL ACGPBDataTypeIsObject(ACGPBDataType type) {
  switch (type) {
    case ACGPBDataTypeBytes:
    case ACGPBDataTypeString:
    case ACGPBDataTypeMessage:
    case ACGPBDataTypeGroup:
      return YES;
    default:
      return NO;
  }
}

ACGPB_INLINE BOOL ACGPBDataTypeIsMessage(ACGPBDataType type) {
  switch (type) {
    case ACGPBDataTypeMessage:
    case ACGPBDataTypeGroup:
      return YES;
    default:
      return NO;
  }
}

ACGPB_INLINE BOOL ACGPBFieldDataTypeIsMessage(ACGPBFieldDescriptor *field) {
  return ACGPBDataTypeIsMessage(field->description_->dataType);
}

ACGPB_INLINE BOOL ACGPBFieldDataTypeIsObject(ACGPBFieldDescriptor *field) {
  return ACGPBDataTypeIsObject(field->description_->dataType);
}

ACGPB_INLINE BOOL ACGPBExtensionIsMessage(ACGPBExtensionDescriptor *ext) {
  return ACGPBDataTypeIsMessage(ext->description_->dataType);
}

// The field is an array/map or it has an object value.
ACGPB_INLINE BOOL ACGPBFieldStoresObject(ACGPBFieldDescriptor *field) {
  ACGPBMessageFieldDescription *desc = field->description_;
  if ((desc->flags & (ACGPBFieldRepeated | ACGPBFieldMapKeyMask)) != 0) {
    return YES;
  }
  return ACGPBDataTypeIsObject(desc->dataType);
}

BOOL ACGPBGetHasIvar(ACGPBMessage *self, int32_t index, uint32_t fieldNumber);
void ACGPBSetHasIvar(ACGPBMessage *self, int32_t idx, uint32_t fieldNumber,
                   BOOL value);
uint32_t ACGPBGetHasOneof(ACGPBMessage *self, int32_t index);

ACGPB_INLINE BOOL
ACGPBGetHasIvarField(ACGPBMessage *self, ACGPBFieldDescriptor *field) {
  ACGPBMessageFieldDescription *fieldDesc = field->description_;
  return ACGPBGetHasIvar(self, fieldDesc->hasIndex, fieldDesc->number);
}

#pragma clang diagnostic pop

//%PDDM-DEFINE ACGPB_IVAR_SET_DECL(NAME, TYPE)
//%void ACGPBSet##NAME##IvarWithFieldPrivate(ACGPBMessage *self,
//%            NAME$S                    ACGPBFieldDescriptor *field,
//%            NAME$S                    TYPE value);
//%PDDM-EXPAND ACGPB_IVAR_SET_DECL(Bool, BOOL)
// This block of code is generated, do not edit it directly.
// clang-format off

void ACGPBSetBoolIvarWithFieldPrivate(ACGPBMessage *self,
                                    ACGPBFieldDescriptor *field,
                                    BOOL value);
// clang-format on
//%PDDM-EXPAND ACGPB_IVAR_SET_DECL(Int32, int32_t)
// This block of code is generated, do not edit it directly.
// clang-format off

void ACGPBSetInt32IvarWithFieldPrivate(ACGPBMessage *self,
                                     ACGPBFieldDescriptor *field,
                                     int32_t value);
// clang-format on
//%PDDM-EXPAND ACGPB_IVAR_SET_DECL(UInt32, uint32_t)
// This block of code is generated, do not edit it directly.
// clang-format off

void ACGPBSetUInt32IvarWithFieldPrivate(ACGPBMessage *self,
                                      ACGPBFieldDescriptor *field,
                                      uint32_t value);
// clang-format on
//%PDDM-EXPAND ACGPB_IVAR_SET_DECL(Int64, int64_t)
// This block of code is generated, do not edit it directly.
// clang-format off

void ACGPBSetInt64IvarWithFieldPrivate(ACGPBMessage *self,
                                     ACGPBFieldDescriptor *field,
                                     int64_t value);
// clang-format on
//%PDDM-EXPAND ACGPB_IVAR_SET_DECL(UInt64, uint64_t)
// This block of code is generated, do not edit it directly.
// clang-format off

void ACGPBSetUInt64IvarWithFieldPrivate(ACGPBMessage *self,
                                      ACGPBFieldDescriptor *field,
                                      uint64_t value);
// clang-format on
//%PDDM-EXPAND ACGPB_IVAR_SET_DECL(Float, float)
// This block of code is generated, do not edit it directly.
// clang-format off

void ACGPBSetFloatIvarWithFieldPrivate(ACGPBMessage *self,
                                     ACGPBFieldDescriptor *field,
                                     float value);
// clang-format on
//%PDDM-EXPAND ACGPB_IVAR_SET_DECL(Double, double)
// This block of code is generated, do not edit it directly.
// clang-format off

void ACGPBSetDoubleIvarWithFieldPrivate(ACGPBMessage *self,
                                      ACGPBFieldDescriptor *field,
                                      double value);
// clang-format on
//%PDDM-EXPAND-END (7 expansions)

void ACGPBSetEnumIvarWithFieldPrivate(ACGPBMessage *self,
                                    ACGPBFieldDescriptor *field,
                                    int32_t value);

id ACGPBGetObjectIvarWithField(ACGPBMessage *self, ACGPBFieldDescriptor *field);

void ACGPBSetObjectIvarWithFieldPrivate(ACGPBMessage *self,
                                      ACGPBFieldDescriptor *field, id value);
void ACGPBSetRetainedObjectIvarWithFieldPrivate(ACGPBMessage *self,
                                              ACGPBFieldDescriptor *field,
                                              id __attribute__((ns_consumed))
                                              value);

// ACGPBGetObjectIvarWithField will automatically create the field (message) if
// it doesn't exist. ACGPBGetObjectIvarWithFieldNoAutocreate will return nil.
id ACGPBGetObjectIvarWithFieldNoAutocreate(ACGPBMessage *self,
                                         ACGPBFieldDescriptor *field);

// Clears and releases the autocreated message ivar, if it's autocreated. If
// it's not set as autocreated, this method does nothing.
void ACGPBClearAutocreatedMessageIvarWithField(ACGPBMessage *self,
                                             ACGPBFieldDescriptor *field);

// Returns an Objective C encoding for |selector|. |instanceSel| should be
// YES if it's an instance selector (as opposed to a class selector).
// |selector| must be a selector from MessageSignatureProtocol.
const char *ACGPBMessageEncodingForSelector(SEL selector, BOOL instanceSel);

// Helper for text format name encoding.
// decodeData is the data describing the special decodes.
// key and inputString are the input that needs decoding.
NSString *ACGPBDecodeTextFormatName(const uint8_t *decodeData, int32_t key,
                                  NSString *inputString);


// Shims from the older generated code into the runtime.
void ACGPBSetInt32IvarWithFieldInternal(ACGPBMessage *self,
                                      ACGPBFieldDescriptor *field,
                                      int32_t value,
                                      ACGPBFileSyntax syntax);
void ACGPBMaybeClearOneof(ACGPBMessage *self, ACGPBOneofDescriptor *oneof,
                        int32_t oneofHasIndex, uint32_t fieldNumberNotToClear);

// A series of selectors that are used solely to get @encoding values
// for them by the dynamic protobuf runtime code. See
// ACGPBMessageEncodingForSelector for details. ACGPBRootObject conforms to
// the protocol so that it is encoded in the Objective C runtime.
@protocol ACGPBMessageSignatureProtocol
@optional

#define ACGPB_MESSAGE_SIGNATURE_ENTRY(TYPE, NAME) \
  -(TYPE)get##NAME;                             \
  -(void)set##NAME : (TYPE)value;               \
  -(TYPE)get##NAME##AtIndex : (NSUInteger)index;

ACGPB_MESSAGE_SIGNATURE_ENTRY(BOOL, Bool)
ACGPB_MESSAGE_SIGNATURE_ENTRY(uint32_t, Fixed32)
ACGPB_MESSAGE_SIGNATURE_ENTRY(int32_t, SFixed32)
ACGPB_MESSAGE_SIGNATURE_ENTRY(float, Float)
ACGPB_MESSAGE_SIGNATURE_ENTRY(uint64_t, Fixed64)
ACGPB_MESSAGE_SIGNATURE_ENTRY(int64_t, SFixed64)
ACGPB_MESSAGE_SIGNATURE_ENTRY(double, Double)
ACGPB_MESSAGE_SIGNATURE_ENTRY(int32_t, Int32)
ACGPB_MESSAGE_SIGNATURE_ENTRY(int64_t, Int64)
ACGPB_MESSAGE_SIGNATURE_ENTRY(int32_t, SInt32)
ACGPB_MESSAGE_SIGNATURE_ENTRY(int64_t, SInt64)
ACGPB_MESSAGE_SIGNATURE_ENTRY(uint32_t, UInt32)
ACGPB_MESSAGE_SIGNATURE_ENTRY(uint64_t, UInt64)
ACGPB_MESSAGE_SIGNATURE_ENTRY(NSData *, Bytes)
ACGPB_MESSAGE_SIGNATURE_ENTRY(NSString *, String)
ACGPB_MESSAGE_SIGNATURE_ENTRY(ACGPBMessage *, Message)
ACGPB_MESSAGE_SIGNATURE_ENTRY(ACGPBMessage *, Group)
ACGPB_MESSAGE_SIGNATURE_ENTRY(int32_t, Enum)

#undef ACGPB_MESSAGE_SIGNATURE_ENTRY

- (id)getArray;
- (NSUInteger)getArrayCount;
- (void)setArray:(NSArray *)array;
+ (id)getClassValue;
@end

BOOL ACGPBClassHasSel(Class aClass, SEL sel);

CF_EXTERN_C_END
