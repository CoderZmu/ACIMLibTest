//
//  ACSocketManager.m
//  ACConnection
//
//  Created by 子木 on 2022/6/13.
//

#import <UIKit/UIKit.h>
#import "ACSocketManager.h"
#import "ACSocketServer.h"
#import "ACLogger.h"
#import "ACSocketReconnectPolicy.h"
#import "ACReachability.h"
#import "ACRunningTimer.h"
#import "ACBase.h"


static NSDictionary *StateDescMap;

@interface ACSocketManager()<ACSocketServerDelegate>

@property (nonatomic, strong, readwrite) ACSocketServer *socketServer;

@property (nonatomic, assign, readwrite) ACSocketConnectionStatus status;

@property (nonatomic, strong) ACSocketReconnectPolicy *reconnectPolicy;

@property (nonatomic, assign) BOOL isClosedByUser;

@property (nonatomic, assign) BOOL isAppActive;

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskId;

@property (nonatomic, assign) int timeLimit;

@property (nonatomic, copy) NSString *address;

@property (nonatomic, copy) NSString *currentAddress;

@property (nonatomic, strong) ACReachability *reachability;

@property (nonatomic, strong) ACRunningTimer *connectionTimeoutTimer;

@property (nonatomic, assign) NSTimeInterval connectionDuration;

@end

@implementation ACSocketManager

#pragma mark - Life Cycle

+ (void)initialize {
    StateDescMap = @{
        @(ACSocketConnectionStatus_UNKNOWN): @"UNKNOWN",
        @(ACSocketConnectionStatus_Connected): @"CONNECTED",
        @(ACSocketConnectionStatus_NETWORK_UNAVAILABLE): @"NETWORK_UNAVAILABLE",
        @(ACSocketConnectionStatus_KICKED_OFFLINE_BY_OTHER_CLIENT): @"USER_KICKED",
        @(ACSocketConnectionStatus_Connecting): @"CONNECTING",
        
        @(ACSocketConnectionStatus_Unconnected): @"NOT_STARTED",
        @(ACSocketConnectionStatus_SignOut): @"SIGNOUT",
        @(ACSocketConnectionStatus_Suspend): @"SUSPEND",
        @(ACSocketConnectionStatus_Timeout): @"TIMEOUT",
        @(ACSocketConnectionStatus_TOKEN_INCORRECT): @"TOKEN_INCORRECT",
        @(ACSocketConnectionStatus_DISCONN_EXCEPTION): @"DISCONN_EXCEPTION",
    };
}

+ (ACSocketManager *)shareSocketManager {
    static ACSocketManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _socketServer = [ACSocketServer shareSocketServer];
        _socketServer.delegate = self;
        _status = ACSocketConnectionStatus_Unconnected;
        _isAppActive = YES;
        _isClosedByUser = YES;
        _backgroundTaskId = UIBackgroundTaskInvalid;
        [self listenAppActive];
        [self listenNetworkStatus];
    }
    return self;
}

- (void)setToken:(NSString *)token {
    _socketServer.token = token;
}

- (void)setAPNsToken:(NSString *)APNsToken {
    _socketServer.APNsToken = APNsToken;
}

- (void)setSeverInfo:(NSString *)serverInfo {
    _address = [serverInfo copy];
}

- (void)setStatus:(ACSocketConnectionStatus)status {
    if (_status == status) return;
    
    [ACLogger info:@"socketServer is changing status from %@ to %@", StateDescMap[@(_status)], StateDescMap[@(status)]];
    _status = status;
    [self.socketListener onConnectStatusChange:status];
}


#pragma mark - Public

- (void)connectWithTimeLimit:(int)timeLimit {
    ac_dispatch_async_on_main_queue(^{
        self.isClosedByUser = NO;
        if ([self isSocketServerAbnormal]) {
            self.status = ACSocketConnectionStatus_Suspend;
        }
        [self.reconnectPolicy cancel];
        self.timeLimit = timeLimit;
        [self doConnect];
    });
}

- (void)close:(BOOL)isLogout {
    ac_dispatch_async_on_main_queue(^{
        self.status = ACSocketConnectionStatus_Unconnected;
        self.isClosedByUser = YES;
        [self.socketServer close:isLogout];
        [self connectionEnd];
    });
}


#pragma mark - Private

- (void)reconnectAndResetTimes {
    // 重置重连次数
    [self.reconnectPolicy cancel];
    [self reconnect];
}


- (void)reconnect {
    if (![self reconnectEnabled]) return;
    __weak __typeof__(self) wSelf = self;
    [self.reconnectPolicy reconnect:^{
        [wSelf doConnect];
        [wSelf resumeConnectionTimeoutTimer];
    }];
}


- (BOOL)doConnect {
    if ([self isSocketServerConnecting] || [self isSocketServerConnected]) {
        return NO;
    }
    if (!self.isAppActive) return NO;
    
    if (!self.connectionTimeoutTimer) {
        [self connectionBegin];
    }
        
    self.status = ACSocketConnectionStatus_Connecting;
    
    self.currentAddress = [self.address copy];
    NSArray *arr = [self.address componentsSeparatedByString:@":"];
    NSAssert(arr.count == 2, @"socket address is illegal");
    [self.socketServer connect:arr[0] port:[arr[1] intValue]];
    return YES;
}


- (void)doClose {
    [self.socketServer close:NO];
}

- (void)doConnectFail:(ACSocketConnectFailReason)reason {
    [self.socketListener onConnectFailed:reason];
    [self doClose];
    [self connectionEnd];
}


- (void)connectionBegin {
    [self createConnectionTimeoutTimer:self.timeLimit];
}

- (void)connectionEnd {
    [self removeConnectionTimeoutTimer];
    [self.reconnectPolicy cancel];
}


- (BOOL)reconnectEnabled {
    if (![self isConnectionAvailable]) return NO;
    if (![self.reachability isReachable]) return NO;
    if (![self isAppActive]) return NO;
    return YES;
}

- (BOOL)isConnectionAvailable {
    if (self.isClosedByUser) return NO;
    if ([self isSocketServerAbnormal]) return NO;
    return YES;
}


- (BOOL)isSocketServerConnecting {
    switch (self.status) {
        case ACSocketConnectionStatus_Connecting:
            return YES;
        default:
            return NO;
    }
}

- (BOOL)isSocketServerAbnormal {
    if (self.status == ACSocketConnectionStatus_KICKED_OFFLINE_BY_OTHER_CLIENT ||
        self.status == ACSocketConnectionStatus_SignOut ||
        self.status == ACSocketConnectionStatus_Timeout ||
        self.status == ACSocketConnectionStatus_TOKEN_INCORRECT ||
        self.status == ACSocketConnectionStatus_DISCONN_EXCEPTION) {
        return YES;
    }
    return NO;
}


- (BOOL)isSocketServerConnected {
    return self.status == ACSocketConnectionStatus_Connected;
}


#pragma mark - Connect Time

- (void)createConnectionTimeoutTimer:(NSTimeInterval)timeLimit {
    if (timeLimit <= 0) return;
    [self removeConnectionTimeoutTimer];

    __weak __typeof__(self) wSelf = self;
    self.connectionTimeoutTimer = [ACRunningTimer timerWithTimeInterval:timeLimit finishEventBlock:^{
        wSelf.status = ACSocketConnectionStatus_Timeout;
        [self doConnectFail:ACSocketConnectFailReason_Timeout];
    }];
    
    [self.connectionTimeoutTimer resume];
}

- (void)suspendConnectionTimeoutTimer {
    !self.connectionTimeoutTimer ?: [self.connectionTimeoutTimer suspend];
}

- (void)resumeConnectionTimeoutTimer {
    !self.connectionTimeoutTimer ?: [self.connectionTimeoutTimer resume];
}

- (void)removeConnectionTimeoutTimer {
    self.connectionTimeoutTimer = nil;
}


#pragma mark - App Status

- (void)listenAppActive {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillEnterForeground)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
    
}

- (void)applicationWillEnterForeground {
    [ACLogger info:@"app enter foreground"];
    self.isAppActive = YES;
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }
    [self reconnectAndResetTimes];
}

- (void)applicationDidEnterBackground {
    [ACLogger info:@"app enter background"];
    if (![self isSocketServerConnected]) {
        self.isAppActive = NO;
        [self doClose];
        if ([self isSocketServerConnecting]) {
            self.status = ACSocketConnectionStatus_Suspend;
        }

        [self suspendConnectionTimeoutTimer];
        return;
    }
    
    if (self.backgroundTaskId == UIBackgroundTaskInvalid) {
        self.backgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            ACLog(@"app become inactive")
            self.isAppActive = NO;
            [self doClose];
            [self suspendConnectionTimeoutTimer];
            if ([self isSocketServerConnected] || [self isSocketServerConnecting]) {
                self.status = ACSocketConnectionStatus_Suspend;
            }
            
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
            self.backgroundTaskId = UIBackgroundTaskInvalid;
        }];
    }
    
}

- (void)applicationWillTerminate {
    [ACLogger info:@"app terminate"];
    self.isAppActive = NO;
    [self doClose];
}



#pragma mark - Network Status
- (void)listenNetworkStatus {
    self.reachability = [ACReachability reachabilityForInternetConnection];
    [self.reachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onReachabilityDidChange:)
                                                 name:kACReachabilityChangedNotification
                                               object:nil];
}

- (void)onReachabilityDidChange:(NSNotification*)notification {
    if (notification.object != self.reachability) return;
    ACNetworkStatus status = [self.reachability currentReachabilityStatus];
    ACLog(@"network status changed -> %d", status);
    if (status == ACNotReachable) {
        [self suspendConnectionTimeoutTimer];
    } else {
        [self reconnectAndResetTimes];
    }
}



#pragma mark - ACSocketServerDelegate

- (void)socketServerDidConnect:(nonnull ACSocketServer *)socketServer {
    if (![self isSocketServerConnecting]) return;
    self.status = ACSocketConnectionStatus_Connected;
    self.connectionDuration = [self.connectionTimeoutTimer consumedDuration];
    [self.socketListener onConnected];
    [self connectionEnd];
}

- (void)socketServerDidDisConnect:(nonnull ACSocketServer *)socketServer error:(nonnull NSError *)error {
    
    if (![self isConnectionAvailable]) return;
    

    if ([self.reachability isReachable]) {
        self.status = ACSocketConnectionStatus_Suspend;
    }else {
        self.status = ACSocketConnectionStatus_NETWORK_UNAVAILABLE;
    }
    
    [self reconnect];
    
}


- (void)socketServer:(nonnull ACSocketServer *)socketServer onReceive:(int32_t)commandId data:(nonnull NSData *)data {
    
    
    ACSocketConnectionStatus errorStatus = ACSocketConnectionStatus_UNKNOWN;
    ACSocketConnectFailReason failedReason = ACSocketConnectFailReason_KICKED_OFFLINE_BY_OTHER_CLIENT;
    BOOL accountAbnormal = NO;
     if (commandId == 0x10008005) { //多账号登录
         errorStatus = ACSocketConnectionStatus_KICKED_OFFLINE_BY_OTHER_CLIENT;
         failedReason = ACSocketConnectFailReason_KICKED_OFFLINE_BY_OTHER_CLIENT;
         accountAbnormal = YES;
    } else if (commandId == 0x10001007 || commandId == 0x10008007) { // 退出登录
        errorStatus = ACSocketConnectionStatus_SignOut;
        failedReason = ACSocketConnectFailReason_SignOut;
        accountAbnormal = YES;
    } else if (commandId == 0x30018FFE || commandId == 0x30018FFF) { // 被冻结
        errorStatus = ACSocketConnectionStatus_DISCONN_EXCEPTION;
        failedReason = ACSocketConnectFailReason_DISCONN_EXCEPTION;
        accountAbnormal = YES;
    } else {
        [self.socketListener didReceive:commandId data:data];
    }
    
    
    if (accountAbnormal) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![self isSocketServerConnected]) return;
            self.status = errorStatus;
            [self doConnectFail:failedReason];
        });
    }
}

- (void)socketServer:(ACSocketServer *)socketServer onOccurError:(int32_t)errorCode {
    if (![self isConnectionAvailable]) return;
    
    self.status = ACSocketConnectionStatus_TOKEN_INCORRECT;
    [self doConnectFail:ACSocketConnectFailReason_TOKEN_INCORRECT];
}

- (ACAuthInfo *)authHeaderInfo {
    return [self.authProvider authInfo];
}


- (BOOL)needReAuth {
    return [self.authProvider needReAuth];
}


- (void)socketServer:(nonnull ACSocketServer *)socketServer onAuth:(nonnull ACPBAuthSignIn2TokenResp *)response {
    if (![self isSocketServerConnecting]) return;
    [self.socketListener didAuth:response];
}

- (void)logout {
    [self.socketListener didLogout];
}

#pragma mark - Getter

- (ACSocketReconnectPolicy *)reconnectPolicy {
    if (!_reconnectPolicy) {
        _reconnectPolicy = [[ACSocketReconnectPolicy alloc] init];
    }
    return _reconnectPolicy;
}

@end


