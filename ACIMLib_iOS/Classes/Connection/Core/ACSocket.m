//
//  SGSocketServer.m
//  Sugram-debug
//
//  Created by gnutech003 on 2017/2/13.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import "ACSocket.h"
#import "ACPacketResolver.h"
#import "ACPacketBuilder.h"
#import "ACLogger.h"
#import "ACGCDAsyncSocket.h"

@interface ACSocket ()<ACPacketResolverDelegate, ACGCDAsyncSocketDelegate>
@property (nonatomic, strong) ACPacketResolver *packageResolver;
@property (nonatomic, weak) id<ACSocketDelegate> delegate;
@property (nonatomic, strong) ACGCDAsyncSocket    *socket;
@property (nonatomic, strong) dispatch_queue_t operationQueue;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) uint16_t port;
@end

@implementation ACSocket


- (instancetype)init {
    return [self initWithDelegate:nil operationQueue:dispatch_get_main_queue()];
}

- (instancetype)initWithDelegate:(id<ACSocketDelegate>)aDelegate operationQueue:(dispatch_queue_t)oq {
    self = [super init];
    if (self) {
        _delegate = aDelegate;
        _operationQueue = oq;
        _packageResolver = [ACPacketResolver new];
        _packageResolver.delegate = self;
    }
    return self;
}


// socket连接
- (void)connect:(NSString *)host port:(uint16_t)port {
    [self close];
    
    _host = host;
    _port = port;
    NSError *error;
    _socket = [[ACGCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.operationQueue socketQueue:nil];

    [_socket connectToHost:host onPort:port withTimeout:6 error:&error];
    if (error) {
        [ACLogger error:@"socket connect error -> host: %@, port: %d, error: %@", host, port, error.description];
    }
}

// 发送数据
- (void)send:(int32_t)commandId payload:(NSData *)payload {
    NSData *d = [ACPacketBuilder buildProtocolPackageWithCommandId:commandId payload:payload];
    [_socket writeData:d withTimeout:-1 tag:0];
    [_socket readDataWithTimeout:-1 tag:0];
}


// 断开socket连接
- (void)close {
    if (self.socket) {
        [self.socket setDelegate:nil delegateQueue:NULL];
        [self.socket disconnect];
        self.socket = nil;
    }
    [self.packageResolver clear];
}


#pragma mark  - ACGCDAsyncSocketDelegate
-(void)socket:(ACGCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    [_socket readDataWithTimeout:-1 tag:0];
    [ACLogger info:@"socket connect success -> local host: %@ port: %d, remoteHost: %@ remotePort: %d",
                                _socket.localHost, _socket.localPort, _host, _port];
    if (self.delegate && [self.delegate respondsToSelector:@selector(socketServerDidConnect:)]) {
        [self.delegate socketServerDidConnect:self];
    }
}

- (void)socketDidDisconnect:(ACGCDAsyncSocket *)_sock withError:(NSError *)error {
    [ACLogger error: @"socket did disconnect-> code: %ld, msg: %@", (long)error.code, error.userInfo[NSLocalizedDescriptionKey]];
    if (self.delegate && [self.delegate respondsToSelector:@selector(socketServer:didDisConnectWithError:)]) {
        [self.delegate socketServer:self didDisConnectWithError:error];
    }
}

- (void)socket:(ACGCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    [_packageResolver receive:data];
    [_socket readDataWithTimeout:-1 tag:0];
}

#pragma mark - ACPackageResolverDelegate

- (void)packetResolver:(nonnull ACPacketResolver *)resolver didResolveAPackage:(int32_t)commandId payload:(nonnull NSData *)payload {
    if (self.delegate && [self.delegate respondsToSelector:@selector(socketServer:onReceivedCommand:payload:)]) {
        [self.delegate socketServer:self onReceivedCommand:commandId payload:payload];
    }
}

- (void)packetResolverFailed:(nonnull ACPacketResolver *)resolver {
    if (self.delegate && [self.delegate respondsToSelector:@selector(socketServerResolvePacketFail:)]) {
        [self.delegate socketServerResolvePacketFail:self];
    }
}

- (bool)isConnected {
    return _socket != nil && _socket.isConnected;
}

@end


