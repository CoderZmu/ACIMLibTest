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

#import "ACGPBBootstrap.h"

@class ACGPBEnumDescriptor;
@class ACGPBMessage;
@class ACGPBInt32Array;

/**
 * Verifies that a given value can be represented by an enum type.
 * */
typedef BOOL (*ACGPBEnumValidationFunc)(int32_t);

/**
 * Fetches an EnumDescriptor.
 * */
typedef ACGPBEnumDescriptor *(*ACGPBEnumDescriptorFunc)(void);

/**
 * Magic value used at runtime to indicate an enum value that wasn't know at
 * compile time.
 * */
enum {
  kACGPBUnrecognizedEnumeratorValue = (int32_t)0xFBADBEEF,
};

/**
 * A union for storing all possible Protobuf values. Note that owner is
 * responsible for memory management of object types.
 * */
typedef union {
  BOOL valueBool;
  int32_t valueInt32;
  int64_t valueInt64;
  uint32_t valueUInt32;
  uint64_t valueUInt64;
  float valueFloat;
  double valueDouble;
  ACGPB_UNSAFE_UNRETAINED NSData *valueData;
  ACGPB_UNSAFE_UNRETAINED NSString *valueString;
  ACGPB_UNSAFE_UNRETAINED ACGPBMessage *valueMessage;
  int32_t valueEnum;
} ACGPBGenericValue;

/**
 * Enum listing the possible data types that a field can contain.
 *
 * @note Do not change the order of this enum (or add things to it) without
 *       thinking about it very carefully. There are several things that depend
 *       on the order.
 * */
typedef NS_ENUM(uint8_t, ACGPBDataType) {
  /** Field contains boolean value(s). */
  ACGPBDataTypeBool = 0,
  /** Field contains unsigned 4 byte value(s). */
  ACGPBDataTypeFixed32,
  /** Field contains signed 4 byte value(s). */
  ACGPBDataTypeSFixed32,
  /** Field contains float value(s). */
  ACGPBDataTypeFloat,
  /** Field contains unsigned 8 byte value(s). */
  ACGPBDataTypeFixed64,
  /** Field contains signed 8 byte value(s). */
  ACGPBDataTypeSFixed64,
  /** Field contains double value(s). */
  ACGPBDataTypeDouble,
  /**
   * Field contains variable length value(s). Inefficient for encoding negative
   * numbers – if your field is likely to have negative values, use
   * ACGPBDataTypeSInt32 instead.
   **/
  ACGPBDataTypeInt32,
  /**
   * Field contains variable length value(s). Inefficient for encoding negative
   * numbers – if your field is likely to have negative values, use
   * ACGPBDataTypeSInt64 instead.
   **/
  ACGPBDataTypeInt64,
  /** Field contains signed variable length integer value(s). */
  ACGPBDataTypeSInt32,
  /** Field contains signed variable length integer value(s). */
  ACGPBDataTypeSInt64,
  /** Field contains unsigned variable length integer value(s). */
  ACGPBDataTypeUInt32,
  /** Field contains unsigned variable length integer value(s). */
  ACGPBDataTypeUInt64,
  /** Field contains an arbitrary sequence of bytes. */
  ACGPBDataTypeBytes,
  /** Field contains UTF-8 encoded or 7-bit ASCII text. */
  ACGPBDataTypeString,
  /** Field contains message type(s). */
  ACGPBDataTypeMessage,
  /** Field contains message type(s). */
  ACGPBDataTypeGroup,
  /** Field contains enum value(s). */
  ACGPBDataTypeEnum,
};

enum {
  /**
   * A count of the number of types in ACGPBDataType. Separated out from the
   * ACGPBDataType enum to avoid warnings regarding not handling ACGPBDataType_Count
   * in switch statements.
   **/
  ACGPBDataType_Count = ACGPBDataTypeEnum + 1
};

/** An extension range. */
typedef struct ACGPBExtensionRange {
  /** Inclusive. */
  uint32_t start;
  /** Exclusive. */
  uint32_t end;
} ACGPBExtensionRange;

/**
 A type to represent an Objective C class.
 This is actually an `objc_class` but the runtime headers will not allow us to
 reference `objc_class`, so we have defined our own.
*/
typedef struct ACGPBObjcClass_t ACGPBObjcClass_t;
