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

#import "ACGPBDictionary.h"

@class ACGPBCodedInputStream;
@class ACGPBCodedOutputStream;
@class ACGPBExtensionRegistry;
@class ACGPBFieldDescriptor;

@protocol ACGPBDictionaryInternalsProtocol
- (size_t)computeSerializedSizeAsField:(ACGPBFieldDescriptor *)field;
- (void)writeToCodedOutputStream:(ACGPBCodedOutputStream *)outputStream
                         asField:(ACGPBFieldDescriptor *)field;
- (void)setACGPBGenericValue:(ACGPBGenericValue *)value
     forACGPBGenericValueKey:(ACGPBGenericValue *)key;
- (void)enumerateForTextFormat:(void (^)(id keyObj, id valueObj))block;
@end

//%PDDM-DEFINE DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(KEY_NAME)
//%DICTIONARY_POD_PRIV_INTERFACES_FOR_KEY(KEY_NAME)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Object, Object)
//%PDDM-DEFINE DICTIONARY_POD_PRIV_INTERFACES_FOR_KEY(KEY_NAME)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, UInt32, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Int32, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, UInt64, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Int64, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Bool, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Float, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Double, Basic)
//%DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, Enum, Enum)

//%PDDM-DEFINE DICTIONARY_PRIVATE_INTERFACES(KEY_NAME, VALUE_NAME, HELPER)
//%@interface ACGPB##KEY_NAME##VALUE_NAME##Dictionary () <ACGPBDictionaryInternalsProtocol> {
//% @package
//%  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
//%}
//%EXTRA_DICTIONARY_PRIVATE_INTERFACES_##HELPER()@end
//%

//%PDDM-DEFINE EXTRA_DICTIONARY_PRIVATE_INTERFACES_Basic()
// Empty
//%PDDM-DEFINE EXTRA_DICTIONARY_PRIVATE_INTERFACES_Object()
//%- (BOOL)isInitialized;
//%- (instancetype)deepCopyWithZone:(NSZone *)zone
//%    __attribute__((ns_returns_retained));
//%
//%PDDM-DEFINE EXTRA_DICTIONARY_PRIVATE_INTERFACES_Enum()
//%- (NSData *)serializedDataForUnknownValue:(int32_t)value
//%                                   forKey:(ACGPBGenericValue *)key
//%                              keyDataType:(ACGPBDataType)keyDataType;
//%

//%PDDM-EXPAND DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(UInt32)
// This block of code is generated, do not edit it directly.
// clang-format off

@interface ACGPBUInt32UInt32Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBUInt32Int32Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBUInt32UInt64Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBUInt32Int64Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBUInt32BoolDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBUInt32FloatDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBUInt32DoubleDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBUInt32EnumDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(ACGPBGenericValue *)key
                              keyDataType:(ACGPBDataType)keyDataType;
@end

@interface ACGPBUInt32ObjectDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
- (BOOL)isInitialized;
- (instancetype)deepCopyWithZone:(NSZone *)zone
    __attribute__((ns_returns_retained));
@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(Int32)
// This block of code is generated, do not edit it directly.
// clang-format off

@interface ACGPBInt32UInt32Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBInt32Int32Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBInt32UInt64Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBInt32Int64Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBInt32BoolDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBInt32FloatDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBInt32DoubleDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBInt32EnumDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(ACGPBGenericValue *)key
                              keyDataType:(ACGPBDataType)keyDataType;
@end

@interface ACGPBInt32ObjectDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
- (BOOL)isInitialized;
- (instancetype)deepCopyWithZone:(NSZone *)zone
    __attribute__((ns_returns_retained));
@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(UInt64)
// This block of code is generated, do not edit it directly.
// clang-format off

@interface ACGPBUInt64UInt32Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBUInt64Int32Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBUInt64UInt64Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBUInt64Int64Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBUInt64BoolDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBUInt64FloatDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBUInt64DoubleDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBUInt64EnumDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(ACGPBGenericValue *)key
                              keyDataType:(ACGPBDataType)keyDataType;
@end

@interface ACGPBUInt64ObjectDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
- (BOOL)isInitialized;
- (instancetype)deepCopyWithZone:(NSZone *)zone
    __attribute__((ns_returns_retained));
@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(Int64)
// This block of code is generated, do not edit it directly.
// clang-format off

@interface ACGPBInt64UInt32Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBInt64Int32Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBInt64UInt64Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBInt64Int64Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBInt64BoolDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBInt64FloatDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBInt64DoubleDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBInt64EnumDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(ACGPBGenericValue *)key
                              keyDataType:(ACGPBDataType)keyDataType;
@end

@interface ACGPBInt64ObjectDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
- (BOOL)isInitialized;
- (instancetype)deepCopyWithZone:(NSZone *)zone
    __attribute__((ns_returns_retained));
@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_PRIV_INTERFACES_FOR_POD_KEY(Bool)
// This block of code is generated, do not edit it directly.
// clang-format off

@interface ACGPBBoolUInt32Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBBoolInt32Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBBoolUInt64Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBBoolInt64Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBBoolBoolDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBBoolFloatDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBBoolDoubleDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBBoolEnumDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(ACGPBGenericValue *)key
                              keyDataType:(ACGPBDataType)keyDataType;
@end

@interface ACGPBBoolObjectDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
- (BOOL)isInitialized;
- (instancetype)deepCopyWithZone:(NSZone *)zone
    __attribute__((ns_returns_retained));
@end

// clang-format on
//%PDDM-EXPAND DICTIONARY_POD_PRIV_INTERFACES_FOR_KEY(String)
// This block of code is generated, do not edit it directly.
// clang-format off

@interface ACGPBStringUInt32Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBStringInt32Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBStringUInt64Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBStringInt64Dictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBStringBoolDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBStringFloatDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBStringDoubleDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

@interface ACGPBStringEnumDictionary () <ACGPBDictionaryInternalsProtocol> {
 @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
- (NSData *)serializedDataForUnknownValue:(int32_t)value
                                   forKey:(ACGPBGenericValue *)key
                              keyDataType:(ACGPBDataType)keyDataType;
@end

// clang-format on
//%PDDM-EXPAND-END (6 expansions)

#pragma mark - NSDictionary Subclass

@interface ACGPBAutocreatedDictionary : NSMutableDictionary {
  @package
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *_autocreator;
}
@end

#pragma mark - Helpers

CF_EXTERN_C_BEGIN

// Helper to compute size when an NSDictionary is used for the map instead
// of a custom type.
size_t ACGPBDictionaryComputeSizeInternalHelper(NSDictionary *dict,
                                              ACGPBFieldDescriptor *field);

// Helper to write out when an NSDictionary is used for the map instead
// of a custom type.
void ACGPBDictionaryWriteToStreamInternalHelper(
    ACGPBCodedOutputStream *outputStream, NSDictionary *dict,
    ACGPBFieldDescriptor *field);

// Helper to check message initialization when an NSDictionary is used for
// the map instead of a custom type.
BOOL ACGPBDictionaryIsInitializedInternalHelper(NSDictionary *dict,
                                              ACGPBFieldDescriptor *field);

// Helper to read a map instead.
void ACGPBDictionaryReadEntry(id mapDictionary, ACGPBCodedInputStream *stream,
                            ACGPBExtensionRegistry *registry,
                            ACGPBFieldDescriptor *field,
                            ACGPBMessage *parentMessage);

CF_EXTERN_C_END
