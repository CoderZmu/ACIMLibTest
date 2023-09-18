//
//  ACIMLib.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/15.
//

#import "ACSocketManager.h"
#import "ACIMLibLoader.h"
#import "ACUrlConstants.h"
#import "AcpbPrivatechat.pbobjc.h"
#import "ACRequestGetMessageBuilder.h"
#import "ACAccountManager.h"
#import "ACServerTime.h"
#import "ACDataBase.h"
#import "ACDialogManager.h"
#import "ACSecretKey.h"
#import "ACMessageManager.h"
#import "ACConnectionListenerManager.h"
#import "ACMessageSenderManager.h"
#import "ACIMConfig.h"
#import "ACLogger.h"
#import "ACSuperGroupNewMessageProcesser.h"
#import "ACSuperGroupOfflineMessageService.h"
#import "ACSocketPacketResender.h"
#import "ACOssManager.h"

typedef enum : NSUInteger {
    NewMessagePush,//新消息提醒
    SuperGroupNewMessage, //超级群新消息
    DialogChanged, //会话信息变化
    Unknonwn
} ACTcpPushMessageType;


@interface ACIMLibLoader()<ACSocketConnectionProtocol, ACSocketAuthProvider>
@property (nonatomic, strong) dispatch_queue_t operationQueue;
@property (nonatomic, copy) IMLibLoaderSuccessBlock successBlock;
@property (nonatomic, copy) IMLibLoaderErrorBlock errorBlock;
@property (nonatomic, copy) void(^dbOpenedBlock)(BOOL);
@end

@implementation ACIMLibLoader

SGSingletonM(Loader)

- (instancetype)init {
    self = [super init];
    // 初始化
    [ACRequestGetMessageBuilder builder];
    [ACDialogManager sharedDialogManger];
    [ACSecretKey instance];
    [ACMessageManager shared];
    [ACMessageSenderManager shared];
     // [ACSuperGroupOfflineMessageService shared];
    [ACSocketPacketResender shared];
    [ACOssManager shareInstance];

    _operationQueue = dispatch_queue_create("com.libloader.process", DISPATCH_QUEUE_SERIAL);
    return self;
}

- (void)setServerInfo:(NSString *)imServer {
    [[ACSocketManager shareSocketManager] setSeverInfo:imServer];
}

- (void)setDeviceToken:(NSString *)deviceToken {
    if (!deviceToken.length) return;
    [[ACSocketManager shareSocketManager] setAPNsToken:deviceToken];
}

- (void)connectWithToken:(NSString *)token
               timeLimit:(int)timeLimit
                dbOpened:(void (^)(BOOL))dbOpenedBlock
                 success:(IMLibLoaderSuccessBlock)successBlock
                   error:(IMLibLoaderErrorBlock)errorBlock {
    dispatch_async(self.operationQueue, ^{
        [ACIMConfig setSDKInitToken:token];
        self.successBlock = successBlock;
        self.errorBlock = errorBlock;
        self.dbOpenedBlock = dbOpenedBlock;
        
        [[ACSocketManager shareSocketManager] setToken:token];
        [[ACSocketManager shareSocketManager] setSocketListener:self];
        [[ACSocketManager shareSocketManager] setAuthProvider:self];
        
        [[ACSocketManager shareSocketManager] connectWithTimeLimit:timeLimit > 0 ? timeLimit : INT32_MAX];
        
        if (![self needReAuth]) {
            [self openUserDatabase];
        }
    });
}

- (void)disconnect:(BOOL)isReceivePush {

    [[ACSocketManager shareSocketManager] setSocketListener:nil];
    [[ACSocketManager shareSocketManager] setAuthProvider:nil];
    [[ACSocketManager shareSocketManager] close:!isReceivePush];
    [[ACConnectionListenerManager shared] onClosed];
}

- (ACConnectionStatus)getConnectionStatus {
    return (ACConnectionStatus)[ACSocketManager shareSocketManager].status;
}


- (BOOL)openUserDatabase {
    BOOL dbReady = [[ACDatabase DataBase] prepareForUid:[ACAccountManager shared].user.Property_SGUser_uin];
    if (dbReady) {
        [[ACConnectionListenerManager shared] userDataDidLoad];
        self.dbOpenedBlock(YES);
    } else {
        [ACLogger error:@"open db faild"];
        self.dbOpenedBlock(NO);
        [self callConectFailed: AC_DATABASE_ERROR];
        [self disconnect:YES];
    }
    return dbReady;
}


- (void)logoutAction {
    [ACAccountManager logOut];
}


- (void)callConectFailed:(ACConnectErrorCode)errorCode {
    dispatch_async(self.operationQueue, ^{
        if (self.errorBlock) {
            IMLibLoaderErrorBlock callback = [self.errorBlock copy];
            callback(errorCode);
            self.errorBlock = nil;
        }
    });
}

#pragma mark - ACSocketConnectionProtocol

- (void)onConnected {
    [ACServerTime performTimeSynchronization]; // 同步服务器时间
    [[ACConnectionListenerManager shared] onConnected];

    dispatch_async(self.operationQueue, ^{
        if (self.successBlock) {
            IMLibLoaderSuccessBlock callback = [self.successBlock copy];
            callback([NSString stringWithFormat:@"%lld", [ACAccountManager shared].user.Property_SGUser_uin]);
            // 置空回调
            self.successBlock = nil;
        }
    });
}

- (void)onConnectStatusChange:(ACSocketConnectionStatus)status {
    [[ACConnectionListenerManager shared] onConnectStatusChanged:(ACConnectionStatus)status];
}

- (void)onConnectFailed:(ACSocketConnectFailReason)resaon {
    ACConnectErrorCode code;
    switch (resaon) {
        case ACSocketConnectFailReason_KICKED_OFFLINE_BY_OTHER_CLIENT:
            [self logoutAction];
            code = AC_DISCONN_KICK;
            break;
        case ACSocketConnectFailReason_SignOut:
            [self logoutAction];
            code = AC_CONN_OTHER_DEVICE_LOGIN;
            break;
        case ACSocketConnectFailReason_Timeout:
            code = AC_CONNECT_TIMEOUT;
            break;
        case ACSocketConnectFailReason_TOKEN_INCORRECT:
            [self logoutAction];
            code = AC_CONN_TOKEN_INCORRECT;
            break;
        case ACSocketConnectFailReason_DISCONN_EXCEPTION:
            code = AC_CONN_USER_BLOCKED;
            break;
    }
    [self callConectFailed: code];
    [[ACConnectionListenerManager shared] onClosed];
}


- (void)didReceive:(int64_t)commandId data:(nonnull NSData *)data {
    [self onReceivedMessagePush:data withType:[self toMessageType:commandId]];
}

- (void)onReceivedMessagePush:(NSData*)data withType:(ACTcpPushMessageType)type {
    if (type == NewMessagePush) { // 新消息通知
        ACPBNewMessageNotificationResp *newMsgNotiResp = [ACPBNewMessageNotificationResp parseFromData:data error:nil];
        [ACRequestGetMessageBuilder loadNewMessageWithSeqNo:newMsgNotiResp.seqno];
    } else if (type == SuperGroupNewMessage) { // 超级群新消息
        [ACSuperGroupNewMessageProcesser onReceiveNewMessageData:data];
    } else if (type == DialogChanged) { // 会话状态发生改变
        [[ACDialogManager sharedDialogManger] syncDialogStatus];
    } else {
        NSLog(@"Unknow data");
    }
}


- (void)didAuth:(nonnull ACPBAuthSignIn2TokenResp *)response {
    [ACAccountManager setLoggedWithModel:response token:[ACIMConfig getSDKInitToken]];
    [ACIMConfig setFileUploadUrl:response.fileDomain andDownLoadUrl:response.dialogFileDomain cert:response.cert];
    [ACIMConfig setLogReportUrl:response.logReportEndpoint];
    dispatch_async(self.operationQueue, ^{
        [self openUserDatabase];
    });
}

- (void)didLogout {
    [self logoutAction];
}


- (ACTcpPushMessageType)toMessageType:(int64_t)cmdid {
    if (cmdid == AC_API_NAME_NewMessagePush) {
        return NewMessagePush;
    }
    if (cmdid == AC_API_NAME_SuperGroupNewMessage) {
        return SuperGroupNewMessage;
    }
    if (cmdid == AC_API_NAME_DialogChangedPush) {
        return DialogChanged;
    }
    return Unknonwn;
    
}

#pragma mark - ACSocketAuthProvider

- (nullable ACAuthInfo *)authInfo {
    
    if (![self needReAuth]) {
        ACUserMo *user = [ACAccountManager shared].user;
        
        return [[ACAuthInfo alloc] initWithDeviceId:user.Property_SGUser_deviceID sessionId:user.Property_SGUser_sessionID uid:user.Property_SGUser_uin];;
    }
    
    return nil;
    
}

- (BOOL)needReAuth {
    if ([ACAccountManager shared].user.Property_SGUser_active && [[ACIMConfig getSDKInitToken] isEqualToString:[ACAccountManager shared].user.Property_SGUser_token]) {
        return NO;
    }
    return YES;
    
}

@end
