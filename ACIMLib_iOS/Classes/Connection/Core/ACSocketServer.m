//
//  SGSocketManager.m
//  ACConnection
//
//  Created by 子木 on 2022/6/9.
//

#import "ACSocketServer.h"
#import "ACSocket.h"
#import "AcpbNetworkMessage.pbobjc.h"
#import "NSData+ACCrypto.h"
#import "ACLogger.h"
#import "ACHandshake.h"
#import "AcpbBase.pbobjc.h"
#import "ACDeviceInfo.h"
#import "ACBase.h"
#import "ACIMLibInfo.h"
#import "NSTimer+ACSafety.h"

static NSTimeInterval const PING_INTERVAL = 15;
static NSTimeInterval const PING_TIMEOUT_INTERVAL = 20;

static NSInteger const PROTOCOL_VERSION = 1;

typedef void (^ACRequestCompleteBlock)(NSData* response, NSError *error);

@interface ACRequestTask : NSObject
@property (nonatomic,assign) int32_t commandId;
@property (nonatomic,strong) ACPBNetworkRequest *request;
@property (nonatomic,assign) NSTimeInterval timeout;
@property (nonatomic,assign) int64_t messageReq;
@property (nonatomic,copy)   ACRequestCompleteBlock block;
@end

@implementation ACRequestTask
@end


@interface ACSocketServer()<ACSocketDelegate>
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) uint16_t port;
@property (nonatomic, strong) dispatch_queue_t operationQueue;
@property (nonatomic, strong) dispatch_queue_t dispatchDataQueue;
@property (nonatomic, strong) ACSocket *socket;
@property (nonatomic, strong) NSMutableArray *dispatchingRequestArr;// 发送中请求队列
@property (nonatomic, strong) NSMutableArray *startupRequestArr; // 等待发送请求队列
@property (nonatomic, strong) dispatch_source_t scanTimer; // 扫描定时器
@property (nonatomic, strong) dispatch_source_t pingTimer; // ping定时器
@property (nonatomic, assign) NSUInteger pingFailedTimes;
@property (nonatomic, assign) BOOL shouldPing;
@property (nonatomic, strong) ACHandshake *handshakeManager;
@property (nonatomic, assign) BOOL hasHandShake; // 握手成功
@property (nonatomic, assign) BOOL isAuthed;
@property (nonatomic, copy) NSString *AESKey;
@property (nonatomic, copy) NSString *AESIV;
@property (nonatomic, strong) ACAuthInfo *authInfo;
@property (nonatomic, assign) NSInteger connectionTag;
@property (nonatomic, assign) BOOL needReUploadAPNsToken;
@end

@implementation ACSocketServer

#pragma mark - Life Cycle
+ (ACSocketServer*)shareSocketServer {
    static ACSocketServer* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _operationQueue = dispatch_queue_create("com.acsocket.process", DISPATCH_QUEUE_SERIAL);
        _dispatchDataQueue = dispatch_queue_create("com.acsocket.dispatchData", DISPATCH_QUEUE_SERIAL);
        _socket = [[ACSocket alloc] initWithDelegate:self operationQueue:_operationQueue];
        _dispatchingRequestArr = [[NSMutableArray alloc] init];
        _startupRequestArr = [[NSMutableArray alloc] init];
    }
    return self;
}


#pragma mark - Public method

- (void)connect:(NSString *)host port:(uint16_t)port {
    dispatch_async(self.operationQueue, ^{
        [self didClose];
        self.connectionTag++;
        self.host = host;
        self.port = port;
        [self.socket connect:host port:port];
        [self launchScanTimer];
    });
}

- (BOOL)isConnected {
    __block BOOL ret;
    dispatch_sync(self.operationQueue, ^{
        ret = [self.socket isConnected] && self.hasHandShake && self.isAuthed;
    });
    return ret;
}

- (void)close:(BOOL)isLogout {
    if (isLogout) {
        ac_dispatch_async_on_main_queue(^{
            [self.delegate logout]; //
        });
        
        NSInteger tag = self.connectionTag;
        [self logOut:^(BOOL result) {
            dispatch_async(self.operationQueue, ^{ 
                if (self.connectionTag == tag) {
                    [self forceClose];
                }
            });
        }];
    } else {
        dispatch_async(self.operationQueue, ^{
            [self forceClose];
        });
    }
}

- (void)forceClose {
    [self didClose];
    [self removeAllTask];
}

- (void)sendRequest:(int32_t)commandId
               data:(NSData *)data
            timeout:(NSTimeInterval)timeout
            success:(ACSocketSuccessBlock)success
            failure:(ACSocketFailureBlock)failure {
    
    
    // 构建请求体
    ACPBNetworkRequest *networkReq = [[ACPBNetworkRequest alloc] init];
    networkReq.messageSeq = [self getMessageSeq];
    networkReq.body = data;
    networkReq.token = self.token;
    networkReq.protocolVersion = PROTOCOL_VERSION;

    ACRequestTask *task = [[ACRequestTask alloc] init];
    task.messageReq = networkReq.messageSeq;
    task.commandId = commandId;
    task.request = networkReq;
    task.timeout = timeout;
    task.block = ^(NSData *response, NSError *error) {
        if (!error) {
            !success?:success(response);
        } else {
            !failure?:failure(error, error.code);
        }
    };
    
    [self sendRequest:task];
    
    
}

- (void)setAPNsToken:(NSString *)APNsToken {
    if (!APNsToken.length || [APNsToken isEqualToString:self.APNsToken]) return;
    dispatch_async(self.operationQueue, ^{
        self -> _APNsToken = [APNsToken copy];
        self.needReUploadAPNsToken = YES;
        if (self.isAuthed) {
            [self uploadAPNsToken];
        }
    });
}


#pragma mark - Private method

- (void)sendRequest:(ACRequestTask *)requestTask {
    dispatch_async(self.operationQueue, ^{
        if (self.isAuthed || [self isHandshakeCommand:requestTask.commandId] || [self isAuthCommand:requestTask.commandId]) {
            [self.dispatchingRequestArr addObject:requestTask];
            if (requestTask.commandId != ACCommand_Heartbeat) {
                [ACLogger info:@"socket send -> cmd: 0x%x, messageSeq: %lld", requestTask.commandId, requestTask.request.messageSeq];
            }
            [self.socket send:requestTask.commandId payload:[self generateRequestPayload:requestTask]];
        } else {
            [self.startupRequestArr addObject:requestTask];
        }
    });
}

- (NSData *)generateRequestPayload:(ACRequestTask *)task {
    if ([self isHandshakeCommand:task.commandId] || [self isAuthCommand:task.commandId]) {
    } else {
       ACPBNetworkRequest *req = task.request;
        req.uid = self.authInfo.uid;
        req.sessionId = self.authInfo.sessionId;
        req.deviceId = self.authInfo.deviceId;
    }
    // 生成请求载体
    NSData *requestPayload = [task.request data];
    
    return [self needAESCrypt] ? [self encryptData:requestPayload] : requestPayload;
}

- (void)launchScanTimer {
    
    if (self.scanTimer) return;
    
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.operationQueue);
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5*NSEC_PER_SEC));
    dispatch_source_set_timer(timer, start, 5*NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(timer, ^{
        [self scaning];
    });
    dispatch_resume(timer);
    self.scanTimer = timer;
}


// 扫描待发送和发送中的请求
- (void)scaning {
    [self scanTimeoutRequests];
    [self scanStartupRequests];
}

-(void)scanTimeoutRequests {
    
    for (NSInteger i = self.dispatchingRequestArr.count - 1;  i >= 0; i--) {
        ACRequestTask *task = self.dispatchingRequestArr[i];
        //计算时间差
        NSDate *date1=[NSDate dateWithTimeIntervalSince1970:task.messageReq/1000];
        NSTimeInterval time2 =[date1 timeIntervalSinceNow];
        int min = abs((int)time2);
        int now= task.timeout;
        
        //判断超时
        if (min > now) {
            // 判断缓存池有没有发送的req，如果有，返回值，并且删除这个发送req。如果没有，发送超时已经返回，保存到异常队列
            ACRequestCompleteBlock block = [task.block copy];
            dispatch_async(self.dispatchDataQueue, ^{
                block(nil, [NSError errorWithDomain:@"com.acconection.error" code:0x3e9 userInfo:nil]);
            });
            [ACLogger error:@"socket send timeout -> cmd:0x%x, messageSeq:%lld, timeout:%f", task.commandId, task.messageReq, task.timeout];
            
            [self.dispatchingRequestArr removeObject:task];
        }
    }
    
}

-(void)scanStartupRequests {
    NSArray *array =[NSArray arrayWithArray:self.startupRequestArr];
    for (ACRequestTask *task in array) {
        NSDate *date1=[NSDate dateWithTimeIntervalSince1970:task.messageReq/1000];
        NSTimeInterval time2 =[date1 timeIntervalSinceNow];
        int min = abs((int)time2);
        int now=(int)task.timeout;
        
        if (min > now) {
            ACRequestCompleteBlock block = [task.block copy];
            dispatch_async(self.dispatchDataQueue, ^{
                block(nil, [NSError errorWithDomain:@"com.acconection.error" code:0x3e9 userInfo:nil]);
            });
            [self.startupRequestArr removeObject:task];
            continue;
        }
        
        if (self.isAuthed) {
            [self.startupRequestArr removeObject:task];
            [self sendRequest:task];
        }
    }
}

// 握手
- (void)handshake {
    _handshakeManager = [[ACHandshake alloc] init];
    __weak __typeof__(self) wSelf = self;
    [_handshakeManager start:^(BOOL success, NSString * _Nullable key, NSString * _Nullable iv) {
        __strong typeof(wSelf) self = wSelf;
        if (!success) {
            [wSelf didClose];
            ac_dispatch_async_on_main_queue(^{
                [self.delegate socketServerDidDisConnect:self error:[NSError errorWithDomain:@"send handshake timeout" code:-1 userInfo:nil]];
            });
            return;
        }
        if (success && [wSelf.socket isConnected])  {
            // 握手成功
            self.hasHandShake = YES;
            self.AESKey = key;
            self.AESIV = iv;
            
            if ([self.delegate needReAuth]) {
                [self auth];
            } else {
                
                __block ACAuthInfo *authInfo;
                ac_dispatch_sync_on_main_queue(^{
                    authInfo = [self.delegate authHeaderInfo];
                });
                [ACLogger info:@"no need auth: %lld", authInfo.uid];
                self.authInfo = authInfo;
                self.isAuthed = YES;
                self.shouldPing = YES;
                self.pingFailedTimes = 0;
                
                [self scaning];
                [self launchPingTimer];
                [self uploadAPNsToken];
                ac_dispatch_async_on_main_queue(^{
                    [self.delegate socketServerDidConnect:self];
                });
                
            }
        }
    } operationQueue:self.operationQueue];
}

- (void)auth {
    
    [ACLogger info:@"start auth -> %@", self.token];
    
    NSString *APNsTokenTmp = [self.APNsToken copy];
    ACPBAuthSignIn2TokenReq *authReq = [[ACPBAuthSignIn2TokenReq alloc] init];
    authReq.token = self.token;
    authReq.deviceType = 2;
    authReq.imei = [ACDeviceInfo getPhoneUUID];
    authReq.brand = @"Apple";
    authReq.model = [ACDeviceInfo getPhoneModel];
    authReq.apnsToken = APNsTokenTmp;
    authReq.sdkVsersion = [ACIMLibInfo libVersion];
    
    __weak __typeof__(self) wSelf = self;
    [self sendRequest:ACCommand_Auth data:[authReq data] timeout:8 success:^(NSData * _Nonnull response) {
        __strong typeof(wSelf) self = wSelf;
        dispatch_async(self.operationQueue, ^{
            ACPBAuthSignIn2TokenResp *resp = [ACPBAuthSignIn2TokenResp parseFromData:response error:nil];
            if (!resp.errorCode) {
                if ([APNsTokenTmp isEqualToString:self.APNsToken] && APNsTokenTmp.length) {
                    self.needReUploadAPNsToken = NO;
                }
                __block ACAuthInfo *authInfo;
                ac_dispatch_sync_on_main_queue(^{
                    [self.delegate socketServer:self onAuth:resp];
                    [self.delegate socketServerDidConnect:self];
                    authInfo = [self.delegate authHeaderInfo];
                });
                self.authInfo = authInfo;
                self.isAuthed = YES;
                self.shouldPing = YES;
                [self scaning];
                [self launchPingTimer];
                [self uploadAPNsToken];
                
                [ACLogger info:@"auth success -> %lld", authInfo.uid];
            } else {
                [ACLogger error:@"auth fail -> %d", resp.errorCode];
                [self didClose];
                ac_dispatch_async_on_main_queue(^{
                    [self.delegate socketServerDidDisConnect:self error:[NSError errorWithDomain:@"send auth timeout" code:-1 userInfo:nil]];
                });
            }
        });
    } failure:^(NSError * _Nonnull error, NSInteger code) {
        __strong typeof(wSelf) self = wSelf;
        dispatch_async(self.operationQueue, ^{
            [ACLogger error:@"auth timeout"];
            [self didClose];
            ac_dispatch_async_on_main_queue(^{
                [self.delegate socketServerDidDisConnect:self error:[NSError errorWithDomain:@"send auth timeout" code:-1 userInfo:nil]];
            });
        });
    }];
}

- (void)uploadAPNsToken {
    if (!self.APNsToken.length || !self.needReUploadAPNsToken) return;
    
    NSString *APNsTokenTmp = [self.APNsToken copy];
    ACPBUpdateApnsTokenReq *mo = [[ACPBUpdateApnsTokenReq alloc] init];
    mo.apnsToken = APNsTokenTmp;
    
    [self sendRequest:ACCommand_UploadAPNsToken data:[mo data] timeout:8 success:^(NSData * _Nonnull response) {
        dispatch_async(self.operationQueue, ^{
            ACPBUpdateApnsTokenResp *resp = [ACPBUpdateApnsTokenResp parseFromData:response error:nil];
            if (!resp.errorCode && [APNsTokenTmp isEqualToString:self.APNsToken]) {
                self.needReUploadAPNsToken = NO;
            }
        });
    } failure:nil];
}

- (void)logOut:(void(^)(BOOL result))callback {
    
    if (!self.isAuthed) {
        callback(NO);
        return;
    }
    
    ACPBAuthLogOutReq *loginout = [[ACPBAuthLogOutReq alloc]init];
    loginout.deviceType = 2;
    loginout.imei = [ACDeviceInfo getPhoneUUID];
    loginout.brand = @"Apple";
    loginout.model = [ACDeviceInfo getPhoneModel];
    
    [self sendRequest:ACCommand_Logout data: [loginout data] timeout:6 success:^(NSData * _Nonnull response) {
        ACPBAuthSignIn2TokenResp *resp = [ACPBAuthSignIn2TokenResp parseFromData:response error:nil];
        if (!resp.errorCode) {
            callback(YES);
        } else {
            callback(NO);
        }
    } failure:^(NSError * _Nonnull error, NSInteger code) {
        callback(NO);
    }];
}

- (void)launchPingTimer {
    if (!self.shouldPing) return;
    [self invalidatePingTimer];
    
    self.pingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.operationQueue);
    dispatch_source_set_timer(self.pingTimer, dispatch_time(DISPATCH_TIME_NOW, PING_INTERVAL * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 0);

    dispatch_source_set_event_handler(self.pingTimer, ^{
        [self ping];
    });
    dispatch_resume(self.pingTimer);

}

- (void)invalidatePingTimer {
    if (self.pingTimer) {
        dispatch_source_cancel(self.pingTimer);
        self.pingTimer = nil;
    }
    
}

- (void)ping {
    if (!self.shouldPing) return;
    
    ACPBHeartbeatReq *heartbeat = [[ACPBHeartbeatReq alloc] init];
    heartbeat.pingId = 0;
    heartbeat.disconnectDelay = 0;
    
    [ACLogger debug:@"send ping ->"];
    [self sendRequest:ACCommand_Heartbeat data:[heartbeat data] timeout:PING_TIMEOUT_INTERVAL  success:^(NSData * _Nonnull response) {
        [ACLogger debug:@"recv pong <-"];
        dispatch_async(self.operationQueue, ^{
            self.pingFailedTimes = 0;
            [self launchPingTimer];
        });
    } failure:^(NSError * _Nonnull error, NSInteger code) {
        dispatch_async(self.operationQueue, ^{
            self.pingFailedTimes++;
            [ACLogger error:@"ping failed -> count: %d, code: %d", self.pingFailedTimes, code];
            if (self.pingFailedTimes >= 2){
                [self didClose];
                ac_dispatch_async_on_main_queue(^{
                    [self.delegate socketServerDidDisConnect:self error:[NSError errorWithDomain:@"ping time out" code:-1 userInfo:nil]];
                });
            } else if (self.shouldPing) {
                [self ping];
            }
        });
    }];

    
}

- (void)didClose {
    [self.socket close];
    [self invalidatePingTimer];
    self.handshakeManager = nil;
    self.hasHandShake = NO;
    self.isAuthed = NO;
    self.shouldPing = NO;
    self.pingFailedTimes = 0;
    [self removeDispatchingTasks];
    [self removeHandshakPingAndAuthTask];
}

- (void)removeAllTask {
    NSMutableArray *allTasks = [NSMutableArray array];
    [allTasks addObjectsFromArray:self.dispatchingRequestArr];
    [allTasks addObjectsFromArray:self.startupRequestArr];
    
    [self.dispatchingRequestArr removeAllObjects];
    [self.startupRequestArr removeAllObjects];
    
    dispatch_async(self.dispatchDataQueue, ^{
        for (ACRequestTask *task in allTasks) {
            ACRequestCompleteBlock block = [task.block copy];
            block(nil, [NSError errorWithDomain:@"com.acconection.close" code:0x3ea userInfo:nil]);
        }
    });
}

- (void)removeHandshakPingAndAuthTask {
    
    void (^removeAction)(NSMutableArray *array) = ^(NSMutableArray *array){
        for (NSInteger i = array.count - 1;  i >= 0; i--) {
            ACRequestTask *task = array[i];
            if ([self isHandshakeCommand:task.commandId] || [self isAuthCommand:task.commandId] || task.commandId == ACCommand_Heartbeat) {
                ACRequestCompleteBlock block = [task.block copy];
                [array removeObject:task];
                dispatch_async(self.dispatchDataQueue, ^{
                    block(nil, [NSError errorWithDomain:@"com.acconection.close" code:0x3ea userInfo:nil]);
                });
            }
        }
    };
    
    removeAction(self.dispatchingRequestArr);
    removeAction(self.startupRequestArr);
}

- (void)removeDispatchingTasks {
    NSMutableArray *allTasks = [NSMutableArray array];
    [allTasks addObjectsFromArray:self.dispatchingRequestArr];
    
    [self.dispatchingRequestArr removeAllObjects];
    
    dispatch_async(self.dispatchDataQueue, ^{
        for (ACRequestTask *task in allTasks) {
            ACRequestCompleteBlock block = [task.block copy];
            block(nil, [NSError errorWithDomain:@"com.acconection.close" code:0x3ea userInfo:nil]);
        }
    });
}

#pragma mark - ACSocketServerDelegate
- (void)socketServerDidConnect:(ACSocket *)socketServer {
    [self handshake];
}

- (void)socketServer:(ACSocket *)socketServer didDisConnectWithError:(NSError *)error {
    [self didClose];
    ac_dispatch_async_on_main_queue(^{
        [self.delegate socketServerDidDisConnect:self error:error];
    });
}


- (void)socketServerResolvePacketFail:(ACSocket *)socketServer {
    [ACLogger error:@"socket packet decode error"];
    [self didClose];
    ac_dispatch_async_on_main_queue(^{
        [self.delegate socketServerDidDisConnect:self error:[NSError errorWithDomain:@"Decode socket message error" code:-1 userInfo:nil]];
    });
    
}

- (void)socketServer:(ACSocket *)socketServer onReceivedCommand:(int32_t)commandId payload:(NSData *)payload {
    if ([self needAESCrypt]) {
        payload = [self decryptData:payload];
    }
    
    ACPBNetworkResponse *networkResponse = [ACPBNetworkResponse parseFromData:payload error:nil];

    if (networkResponse.code) {
        [ACLogger error:@"socket recv business error -> code: %d", networkResponse.code];
        [self didClose];
        ac_dispatch_async_on_main_queue(^{
            [self.delegate socketServer:self onOccurError:networkResponse.code];
        });
        return;
    }
    
    NSData *body = networkResponse.body;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageReq = %lld", networkResponse.messageSeq];
    NSArray *filterDispatchingArray = [self.dispatchingRequestArr filteredArrayUsingPredicate:predicate];
    ACRequestTask *task = filterDispatchingArray.firstObject;
    
    if (task) {
        if (task.commandId != ACCommand_Heartbeat) {
            ACLog(@"socket recv ack -> messageSeq: %lld", networkResponse.messageSeq);
        }
        ACRequestCompleteBlock completeBlock = [task.block copy];
        dispatch_async(self.dispatchDataQueue, ^{
            completeBlock(body,nil);
        });
        [self.dispatchingRequestArr removeObject:task];
        
    } else {
        ACLog(@"socket recv -> cmd: 0x%x", commandId);
        // 分发从服务器主动推送的消息
        dispatch_async(self.dispatchDataQueue, ^{
            [self.delegate socketServer:self onReceive:commandId data:body];
        });
        
    }
    
    
    
}


#pragma mark - Utils
- (NSData *)encryptData:(NSData *)bodyOrginalData {
    
    NSData *d = [bodyOrginalData dataEncryptedUsingAlgorithm:kCCAlgorithmAES128 key:_AESKey initializationVector:_AESIV options:kCCOptionPKCS7Padding error:nil];
    return d;
}

// 解密
- (NSData *)decryptData:(NSData *)bodyEncrytedData {
    
    return [bodyEncrytedData decryptedDataUsingAlgorithm:kCCAlgorithmAES128 key:_AESKey initializationVector:_AESIV options:kCCOptionPKCS7Padding error:nil];
    
}


- (BOOL)needAESCrypt {
    return self.hasHandShake;
}

- (BOOL)isHandshakeCommand:(int32_t)commandId {
    if (commandId == ACCommand_HandShake || commandId == ACCommand_Comfirm_HandShake) {
        return YES;
    }
    return NO;
}

- (BOOL)isAuthCommand:(int32_t)commandId {
    return commandId == ACCommand_Auth;
}

static UInt64 UniqueTimeStamp = 1;
- (UInt64)getMessageSeq {
    @synchronized (self) {
        UniqueTimeStamp++;
        int64_t time = [[NSDate date] timeIntervalSince1970] * 1000;
        if (UniqueTimeStamp < time) {
            UniqueTimeStamp = time;
        }
    }
 
    return UniqueTimeStamp;
    
}

@end
