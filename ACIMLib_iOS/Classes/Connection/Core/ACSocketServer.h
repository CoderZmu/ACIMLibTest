//
//  SGSocketManager.h
//  ACConnection
//
//  Created by 子木 on 2022/6/9.
//

#import <Foundation/Foundation.h>
#import "ACSocketHeader.h"
#import "ACAuthInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class ACPBNetworkRequest,ACPBAuthSignIn2TokenResp;
@protocol ACSocketServerDelegate;

/// socket服务建立（握手，心跳，数据传输加解密）
@interface ACSocketServer : NSObject

@property (nonatomic, weak) id<ACSocketServerDelegate> delegate;

@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *APNsToken;

+ (ACSocketServer*)shareSocketServer;

- (void)connect:(NSString *)host port:(uint16_t)port;

- (BOOL)isConnected;

- (void)close:(BOOL)isLogout;

- (void)sendRequest:(int32_t)commandId
                 data:(NSData *)data
              timeout:(NSTimeInterval)timeout
              success:(ACSocketSuccessBlock)success
              failure:(nullable ACSocketFailureBlock)failure;

@end

@protocol ACSocketServerDelegate<NSObject>

@required
- (void)socketServerDidConnect:(ACSocketServer *)socketServer;
- (void)socketServerDidDisConnect:(ACSocketServer *)socketServer error:(NSError *)error;
- (void)socketServer:(ACSocketServer *)socketServer onOccurError:(int32_t)errorCode;
- (void)socketServer:(ACSocketServer *)socketServer onReceive:(int32_t)commandId data:(NSData *)data;
- (void)socketServer:(ACSocketServer *)socketServer onAuth:(ACPBAuthSignIn2TokenResp *)response;
- (void)logout;
- (BOOL)needReAuth;
- (ACAuthInfo *)authHeaderInfo;
@end

NS_ASSUME_NONNULL_END
