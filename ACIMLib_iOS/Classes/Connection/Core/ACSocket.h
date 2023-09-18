//
//  SGSocketServer.h
//  Sugram-debug
//
//  Created by gnutech003 on 2017/2/13.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACSocket;

@protocol ACSocketDelegate<NSObject>

@optional
- (void)socketServerDidConnect:(ACSocket *)socketServer;
- (void)socketServer:(ACSocket *)socketServer didDisConnectWithError:(NSError *)error;
- (void)socketServerResolvePacketFail:(ACSocket *)socketServer;
- (void)socketServer:(ACSocket *)socketServer onReceivedCommand:(int32_t)commandId payload:(NSData *)payload;

@end


/// socket连接，组装package
@interface ACSocket : NSObject

@property (nonatomic, assign, readonly) bool isConnected;

- (instancetype)initWithDelegate:(id<ACSocketDelegate>)aDelegate operationQueue:(dispatch_queue_t)oq;
- (void)connect:(NSString *)host port:(uint16_t)port;
- (void)send:(int32_t)commandId payload:(NSData *)payload;
- (void)close;

@end
