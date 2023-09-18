//
//  ACSocketManager.h
//  ACConnection
//
//  Created by 子木 on 2022/6/13.
//

#import <Foundation/Foundation.h>
#import "AcpbBase.pbobjc.h"
#import "ACSocketHeader.h"
#import "ACAuthInfo.h"

typedef void (^ACDataResultBlock)(NSData* _Nullable resultData,int64_t tag, NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN

// 网络连接状态码
typedef NS_ENUM(NSInteger, ACSocketConnectionStatus) {
    // 建立连接中出现异常的临时状态，SDK 会自动重连
    ACSocketConnectionStatus_UNKNOWN = -1,
    // 连接成功
    ACSocketConnectionStatus_Connected = 0,
    // 当网络恢复可用时，SDK 会自动重连
    ACSocketConnectionStatus_NETWORK_UNAVAILABLE = 1,
    // 当前用户在其他设备上登录，此设备被踢下线
    ACSocketConnectionStatus_KICKED_OFFLINE_BY_OTHER_CLIENT = 6,
    // 连接中
    ACSocketConnectionStatus_Connecting = 10,
    //连接失败或未连接
    ACSocketConnectionStatus_Unconnected = 11,
    // 已登出
    ACSocketConnectionStatus_SignOut = 12,
    // 连接暂时挂起（多是由于网络问题导致），SDK 会在合适时机进行自动重连
    ACSocketConnectionStatus_Suspend = 13,
    // 自动连接超时，SDK 将不会继续连接，用户需要做超时处理，再自行调用 connect 接口进行连接
    ACSocketConnectionStatus_Timeout = 14,
    // token无效
    ACSocketConnectionStatus_TOKEN_INCORRECT = 15,
    // 用户被封禁
    ACSocketConnectionStatus_DISCONN_EXCEPTION = 16
};

// 连接失败错误码
typedef NS_ENUM(NSInteger, ACSocketConnectFailReason) {
    // 当前用户在其他设备上登录，此设备被踢下线
    ACSocketConnectFailReason_KICKED_OFFLINE_BY_OTHER_CLIENT = 6,
    // 已登出
    ACSocketConnectFailReason_SignOut = 12,
    // 自动连接超时，SDK 将不会继续连接，用户需要做超时处理，再自行调用 connect 接口进行连接
    ACSocketConnectFailReason_Timeout = 14,
    // token无效
    ACSocketConnectFailReason_TOKEN_INCORRECT = 15,
    // 用户被封禁
    ACSocketConnectFailReason_DISCONN_EXCEPTION = 16
};



@protocol ACSocketConnectionProtocol, ACSocketAuthProvider;
@class ACSocketServer;

@interface ACSocketManager : NSObject

@property (nonatomic, strong, readonly) ACSocketServer *socketServer;
@property (nonatomic, weak) id<ACSocketConnectionProtocol> socketListener;
@property (nonatomic, weak) id<ACSocketAuthProvider> authProvider;
@property (nonatomic, assign, readonly) ACSocketConnectionStatus status;

+ (ACSocketManager *)shareSocketManager;

- (void)setToken:(NSString *)token;

- (void)setAPNsToken:(NSString *)APNsToken;

- (void)setSeverInfo:(NSString *)serverInfo;

- (void)connectWithTimeLimit:(int)timeLimit;

- (void)close:(BOOL)isLogout;

@end

@protocol ACSocketConnectionProtocol

@required

- (void)onConnected;

- (void)onConnectFailed:(ACSocketConnectFailReason)resaon;

- (void)onConnectStatusChange:(ACSocketConnectionStatus)status;

- (void)didAuth:(ACPBAuthSignIn2TokenResp *)response;

- (void)didLogout;

- (void)didReceive:(int64_t)commandId data:(NSData *)data;

@end

@protocol ACSocketAuthProvider <NSObject>

@required

- (nullable ACAuthInfo *)authInfo;

- (BOOL)needReAuth;

@end

NS_ASSUME_NONNULL_END
