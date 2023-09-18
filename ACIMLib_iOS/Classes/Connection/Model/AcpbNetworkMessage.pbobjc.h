// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: acpb.network.message.proto

// This CPP symbol can be defined to use imports that match up to the framework
// imports needed when using CocoaPods.
#if !defined(ACGPB_USE_PROTOBUF_FRAMEWORK_IMPORTS)
 #define ACGPB_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

#if ACGPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
 #import <Protobuf/ACGPBProtocolBuffers.h>
#else
 #import "ACGPBProtocolBuffers.h"
#endif

#if GOOGLE_PROTOBUF_OBJC_VERSION < 30004
#error This file was generated by a newer version of protoc which is incompatible with your Protocol Buffer library sources.
#endif
#if 30004 < GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION
#error This file was generated by an older version of protoc which is incompatible with your Protocol Buffer library sources.
#endif

// @@protoc_insertion_point(imports)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

CF_EXTERN_C_BEGIN

NS_ASSUME_NONNULL_BEGIN

#pragma mark - AcpbNetworkMessageRoot

/**
 * Exposes the extension registry for this file.
 *
 * The base class provides:
 * @code
 *   + (ACGPBExtensionRegistry *)extensionRegistry;
 * @endcode
 * which is a @c ACGPBExtensionRegistry that includes all the extensions defined by
 * this file and all files that it depends on.
 **/
ACGPB_FINAL @interface AcpbNetworkMessageRoot : ACGPBRootObject
@end

#pragma mark - ACPBNetworkRequest

typedef ACGPB_ENUM(ACPBNetworkRequest_FieldNumber) {
  ACPBNetworkRequest_FieldNumber_MessageSeq = 2,
  ACPBNetworkRequest_FieldNumber_DeviceId = 3,
  ACPBNetworkRequest_FieldNumber_SessionId = 4,
  ACPBNetworkRequest_FieldNumber_Uid = 5,
  ACPBNetworkRequest_FieldNumber_ProtocolVersion = 6,
  ACPBNetworkRequest_FieldNumber_DestId = 7,
  ACPBNetworkRequest_FieldNumber_Body = 8,
  ACPBNetworkRequest_FieldNumber_Token = 9,
};

ACGPB_FINAL @interface ACPBNetworkRequest : ACGPBMessage

/** int32 cmdId = 1; */
@property(nonatomic, readwrite) int64_t messageSeq;

@property(nonatomic, readwrite) int64_t deviceId;

@property(nonatomic, readwrite) int64_t sessionId;

@property(nonatomic, readwrite) int64_t uid;

@property(nonatomic, readwrite) int32_t protocolVersion;

@property(nonatomic, readwrite, copy, null_resettable) NSString *destId;

@property(nonatomic, readwrite, copy, null_resettable) NSData *body;

@property(nonatomic, readwrite, copy, null_resettable) NSString *token;

@end

#pragma mark - ACPBNetworkResponse

typedef ACGPB_ENUM(ACPBNetworkResponse_FieldNumber) {
  ACPBNetworkResponse_FieldNumber_MessageSeq = 2,
  ACPBNetworkResponse_FieldNumber_DeviceId = 3,
  ACPBNetworkResponse_FieldNumber_Uid = 5,
  ACPBNetworkResponse_FieldNumber_ProtocolVersion = 6,
  ACPBNetworkResponse_FieldNumber_Body = 8,
  ACPBNetworkResponse_FieldNumber_Token = 9,
  ACPBNetworkResponse_FieldNumber_Code = 10,
};

ACGPB_FINAL @interface ACPBNetworkResponse : ACGPBMessage

/** int32 cmdId = 1; */
@property(nonatomic, readwrite) int64_t messageSeq;

@property(nonatomic, readwrite) int64_t deviceId;

/** 注: response header跳过sessionId */
@property(nonatomic, readwrite) int64_t uid;

@property(nonatomic, readwrite) int32_t protocolVersion;

/** int64 srcId = 7;  //是否需要发件人id? app端有需求时添加 */
@property(nonatomic, readwrite, copy, null_resettable) NSData *body;

@property(nonatomic, readwrite, copy, null_resettable) NSString *token;

@property(nonatomic, readwrite) int32_t code;

@end

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END

#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)