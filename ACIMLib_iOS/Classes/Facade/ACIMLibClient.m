//
//  ACIMLibClient.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/16.
//

#import "ACIMLibClient.h"
#import "ACIMLibLoader.h"
#import "ACMessageHeader.h"
#import "ACMessageManager.h"
#import "ACMessageSenderManager.h"
#import "ACAccountManager.h"
#import "ACDialogManager.h"
#import "ACConversation.h"
#import "ACDialogMo+Adapter.h"
#import "ACMessageMo+Adapter.h"
#import "ACActionType.h"
#import "ACMessageType.h"
#import "ACMessageSerializeSupport.h"
#import "ACServerTime.h"
#import "ACDialogIdConverter.h"
#import "ACConversationListFetcher.h"
#import "NSObject+EventBus.h"
#import "ACHelper.h"
#import "ACNetErrorConverter.h"
#import "ACLogger.h"
#import "ACIMGlobal.h"
#import "ACChannelClient.h"
#import "ACConnectionListenerManager.h"
#import "ACIMConfig.h"
#import "ACRecallGroupChatMessagePacket.h"
#import "ACRecallPrivateChatMessagePacket.h"
#import "ACReportLog.h"
#import "ACIMLibInfo.h"
#import "ACMessageDownloader.h"

@interface ACIMLibClient()<ACConnectionListenerProtocol>
@property (nonatomic,strong) NSHashTable<id<ACIMClientReceiveMessageDelegate>> *receiveMessageDelegateArr;
@property (nonatomic,strong) NSHashTable<id<ACConnectionStatusChangeDelegate>> *connectionStatusChangeDelegateArr;
@end

@implementation ACIMLibClient

+ (ACIMLibClient *)shared {
    static ACIMLibClient *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ACIMLibClient alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    self.receiveMessageDelegateArr = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory];
    return self;
}


#pragma mark - SDK init

- (void)initWithAppKey:(NSString *)appKey {
    if ([ACIMGlobal shared].hasInitialized) return;
    [[ACIMGlobal shared] setHasInitialized];

    ACLog(@"imLibClient init");

    _pushProfile = [[ACPushProfile alloc] init];
    [self ac_connectGlobalEventName:kReceiveNewMessagesNotification selector:@selector(onReceiveNewMessages:hasPackage:)];
    [self ac_connectGlobalEventName:kConversationListDidSyncNoti selector:@selector(onOfflineMessageSyncCompleted)];
    [self ac_connectGlobalEventName:kRecallMessageNotification selector:@selector(messageDidRecall:)];
    [[ACConnectionListenerManager shared] addListener:self];
    [self registerMessages];
}


- (void)setServerInfo:(NSString *)imServer {
    [[ACIMLibLoader sharedLoader] setServerInfo:imServer];
}

- (void)setDeviceTokenData:(NSData *)deviceTokenData {
    if (!deviceTokenData) return;
    [self setDeviceToken:[ACHelper getAPNsTokenStringWithData:deviceTokenData]];
}

- (void)setDeviceToken:(NSString *)deviceToken {
    [[ACIMLibLoader sharedLoader] setDeviceToken:deviceToken];
}

- (void)connectWithToken:(NSString *)token
                 success:(ACConnectSuccessBlock)successBlock
                   error:(ACConnectErrorBlock)errorBlock {
    [self connectWithToken:token dbOpened:nil success:successBlock error:errorBlock];
}

- (void)connectWithToken:(NSString *)token
                dbOpened:(ACConnectDbOpenedBlock)dbOpenedBlock
                 success:(ACConnectSuccessBlock)successBlock
                   error:(ACConnectErrorBlock)errorBlock {
    [self connectWithToken:token timeLimit:-1 dbOpened:dbOpenedBlock success:successBlock error:errorBlock];
}

- (void)connectWithToken:(NSString *)token
               timeLimit:(int)timeLimit
                dbOpened:(ACConnectDbOpenedBlock)dbOpenedBlock
                 success:(ACConnectSuccessBlock)successBlock
                   error:(ACConnectErrorBlock)errorBlock {
    if (![ACIMGlobal shared].hasInitialized) {
        errorBlock(AC_CLIENT_NOT_INIT);
        return;
    }
    if ([ACIMGlobal shared].isConnectionExist) {
        errorBlock(AC_CONNECTION_EXIST);
        return;
    }
    if (!token.length) {
        errorBlock(AC_INVALID_PARAMETER);
        return;
    }
    [[ACIMGlobal shared] setHasCreatedConnection:YES];
    [[ACIMGlobal shared] setUserDataInitialized:NO];
    [ACLogger info:@"ACIMLibClient connect -> %@", token];
    
    [[ACIMLibLoader sharedLoader] connectWithToken:token timeLimit:timeLimit dbOpened:^(BOOL isOpen) {
        if (isOpen) {
            [[ACIMGlobal shared] setUserDataInitialized:YES];
            ACLog(@"imLibClient db open success");
        }
        !dbOpenedBlock ?: dbOpenedBlock(isOpen ? ACDBOpenSuccess : ACDBOpenFailed);
    } success:^(NSString * _Nonnull userId) { // 连接成功
        ACLog(@"imLibClient connect success");
        !successBlock ?: successBlock(userId);
    }  error:^(ACConnectErrorCode errorCode) {
        ACLog(@"imLibClient connect fail -> code: %ld", errorCode);
        [[ACIMGlobal shared] setHasCreatedConnection:NO];
        !errorBlock ?: errorBlock(errorCode);
    }];
}

- (void)disconnect:(BOOL)isReceivePush; {
    ACLog(@"imLibClient disconnect");
    [[ACIMGlobal shared] setHasCreatedConnection:NO];
    [[ACIMLibLoader sharedLoader] disconnect:isReceivePush];
}

- (void)disconnect {
    [self disconnect:YES];
}

- (void)logout {
    [self disconnect:NO];
}

#pragma mark - ACConnectionStatusChangeDelegate

- (void)setACConnectionStatusChangeDelegate:(id<ACConnectionStatusChangeDelegate>)delegate {
    [self addConnectionStatusChangeDelegate:delegate];
}

- (void)addConnectionStatusChangeDelegate:(id<ACConnectionStatusChangeDelegate>)delegate {
    @synchronized (self) {
        [self.connectionStatusChangeDelegateArr addObject:delegate];
    }
}

- (void)removeConnectionStatusChangeDelegate:(id<ACConnectionStatusChangeDelegate>)delegate {
    [self.connectionStatusChangeDelegateArr removeObject:delegate];
}


- (ACConnectionStatus)getConnectionStatus {
    return [[ACIMLibLoader sharedLoader] getConnectionStatus];
}

#pragma mark - Conversation List

- (NSArray *)getConversationList:(NSArray *)conversationTypeList {
    [ACLogger debug:@"get conversationList"];
    if (![ACIMGlobal shared].isUserDataInitialized) return nil;
    return [[ACConversationListFetcher new] getConversationList:conversationTypeList];
}

- (NSArray *)getConversationList:(NSArray *)conversationTypeList count:(int)count startTime:(long long)startTime {
    [ACLogger debug:@"get conversationList"];
    if (![ACIMGlobal shared].isUserDataInitialized) return nil;
    NSArray *result = [[ACConversationListFetcher new] getConversationList:conversationTypeList count:count startTime:startTime];
    [ACLogger debug:@"get conversationList success"];
    return result;
}

- (ACConversation *)getConversation:(ACConversationType)conversationType targetId:(long)targetId {
    [ACLogger debug:@"get conversation -> conversationType: %zd, targetId: %ld", conversationType, targetId];
    
    if (![ACIMGlobal shared].isUserDataInitialized) return nil;
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId];
    if (![NSString ac_isValidString:dialogId]) {
        return nil;
    };
    
    ACDialogMo *dialog = [[ACDialogManager sharedDialogManger] getDialogMoForDialogId:dialogId];
    return [dialog toRCConversation];
}

- (BOOL)removeConversation:(ACConversationType)conversationType targetId:(long)targetId {
    [ACLogger debug:@"remove conversation -> conversationType: %zd, targetId: %ld", conversationType, targetId];
    
    if (![ACIMGlobal shared].isUserDataInitialized) return NO;
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId];
    if (![NSString ac_isValidString:dialogId]) {
        return NO;
    };
    return [[ACDialogManager sharedDialogManger] removeDialogBy:[ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId]];
}

- (BOOL)setConversationToTop:(ACConversationType)conversationType targetId:(long)targetId isTop:(BOOL)isTop {
    return [[ACChannelClient sharedChannelManager] setConversationToTop:conversationType targetId:targetId channelId:nil isTop:isTop];
}

- (NSArray<ACConversation *> *)getTopConversationList:(NSArray *)conversationTypeList {
    [ACLogger debug:@"get topConversationList"];
    if (![ACIMGlobal shared].isUserDataInitialized) return nil;
    return [[ACConversationListFetcher new] getTopConversationList:conversationTypeList];
}

#pragma mark - 会话中的草稿操作

- (nullable NSString *)getTextMessageDraft:(ACConversationType)conversationType targetId:(long)targetId  {
    [ACLogger debug:@"getTextMessageDraft -> conversationType: %zd, targetId: %ld", conversationType, targetId];
    
    if (![ACIMGlobal shared].isUserDataInitialized) return nil;
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:nil];
    if (![NSString ac_isValidString:dialogId]) {
        return nil;
    }
    return [[ACDialogManager sharedDialogManger] getDialogDraft:dialogId];
}

- (BOOL)saveTextMessageDraft:(ACConversationType)conversationType
                    targetId:(long)targetId
                     content:(NSString *)content {
    [ACLogger debug:@"saveTextMessageDraft -> conversationType: %zd, targetId: %ld", conversationType, targetId];
    
    if (![ACIMGlobal shared].isUserDataInitialized) return NO;
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:nil];
    if (![NSString ac_isValidString:dialogId]) {
        return NO;
    }
    [[ACDialogManager sharedDialogManger] setDialog:dialogId draft:content];
    return YES;
}

- (BOOL)clearTextMessageDraft:(ACConversationType)conversationType targetId:(long)targetId {
    [ACLogger debug:@"clearTextMessageDraft -> conversationType: %zd, targetId: %ld", conversationType, targetId];
    
    if (![ACIMGlobal shared].isUserDataInitialized) return NO;
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:nil];
    if (![NSString ac_isValidString:dialogId]) {
        return NO;
    }
    [[ACDialogManager sharedDialogManger] setDialog:dialogId draft:nil];
    return YES;
}

#pragma mark - Unread Count

- (int)getTotalUnreadCount {
    [ACLogger debug:@"get totalUnreadCount"];
    if (![ACIMGlobal shared].isUserDataInitialized) return 0;
    return [[ACDialogManager sharedDialogManger] getTotalUnreadCount];
}

- (int)getUnreadCount:(ACConversationType)conversationType targetId:(long)targetId {
    return [[ACChannelClient sharedChannelManager] getUnreadCount:conversationType targetId:targetId channelId:nil];
}

- (int)getUnreadCountWithConTypes:(NSArray *)conversationTypes {
    [ACLogger debug:@"get unreadCount -> conversationTypes: %@", [conversationTypes componentsJoinedByString:@","]];
    if (![ACIMGlobal shared].isUserDataInitialized) return 0;
    if (!conversationTypes.count) return 0;
    NSSet *requestTypes = [[NSSet alloc] initWithArray:conversationTypes];
    NSSet *supportTypes = [self p_supportedConversationTypes];
    
    if ([supportTypes isSubsetOfSet:requestTypes]) {
        return [self getTotalUnreadCount];
    } else {
        return [[ACDialogManager sharedDialogManger] getUnreadCountWithDialogType:[conversationTypes[0] intValue]];
    }
}

- (BOOL)clearAllMessagesUnreadStatus:(ACConversationType)conversationType
                            targetId:(long)targetId {
    return [[ACChannelClient sharedChannelManager] clearAllMessagesUnreadStatus:conversationType targetId:targetId channelId:nil];;
}

- (BOOL)clearMessagesUnreadStatus:(ACConversationType)conversationType
                         targetId:(long)targetId
                             time:(long long)timestamp {
    return [[ACChannelClient sharedChannelManager] clearMessagesUnreadStatus:conversationType targetId:targetId channelId:nil time:timestamp];
}

#pragma mark - Conversation Notification

- (void)setConversationNotificationStatus:(ACConversationType)conversationType
                                 targetId:(long)targetId
                                isBlocked:(BOOL)isBlocked
                                  success:(void (^)(ACConversationNotificationStatus nStatus))successBlock
                                    error:(void (^)(ACErrorCode status))errorBlock {
    NSString *paramsStr = [NSString stringWithFormat:@"conversationType: %zd, targetId: %ld", conversationType, targetId];
    [ACLogger debug:@"set conversationNotificationStatus -> %@", paramsStr];
    
    void (^errorBlockTmp)( ACErrorCode) = ^(ACErrorCode code) {
        [ACLogger warn:@"set conversationNotificationStatus fail -> %@, code: %zd",paramsStr,code];
        !errorBlock ?: errorBlock(code);
    };
    
    if (![ACIMGlobal shared].isUserDataInitialized) {
        errorBlockTmp(AC_NETWORK_UNAVAILABLE);
        return;
    }
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId];
    if (![NSString ac_isValidString:dialogId]) {
        errorBlockTmp(INVALID_PARAMETER);
        return;
    };
    [[ACDialogManager sharedDialogManger] setDialog:dialogId muteFlag:isBlocked complete:^(ACErrorCode code) {
        if (code == AC_SUCCESS) {
            ACDialogMo *dialog = [[ACDialogManager sharedDialogManger] getDialogMoForDialogId:dialogId];
            successBlock(dialog.Property_ACDialogs_muteFlag ? NOTIFY : DO_NOT_DISTURB);
        } else {
            errorBlockTmp(code);
        }
    }];
}

- (void)getConversationNotificationStatus:(ACConversationType)conversationType
                                 targetId:(long)targetId
                                  success:(void (^)(ACConversationNotificationStatus nStatus))successBlock
                                    error:(void (^)(ACErrorCode status))errorBlock {
    [ACLogger debug:@"get conversationNotificationStatus -> conversationType: %zd, targetId: %ld", conversationType, targetId];
    
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId];
    if (![NSString ac_isValidString:dialogId]) {
        errorBlock(INVALID_PARAMETER);
        return;
    };
    
    [[ACDialogManager sharedDialogManger] loadDialogMoForDialogId:dialogId complete:^(ACDialogMo * _Nullable dialogMo) {
        if (!dialogMo) {
            errorBlock(ERRORCODE_UNKNOWN);
            return;
        }
        
        successBlock(dialogMo.Property_ACDialogs_muteFlag ? DO_NOT_DISTURB : NOTIFY);
    }];
}

- (NSArray<ACConversation *> *)getBlockedConversationList:(NSArray *)conversationTypeList {
    [ACLogger debug:@"get blockedConversationList -> conversationTypes: %@", [conversationTypeList componentsJoinedByString:@","]];
    
    if (![ACIMGlobal shared].isUserDataInitialized) return @[];
    return [[ACConversationListFetcher new] getBlockedConversationList:conversationTypeList];
}

#pragma mark - Message Send

- (void)registerMessageType:(Class)messageClass {
    [[ACMessageSerializeSupport shared] registerMessageContentClass:messageClass];
}

- (ACMessage *)sendMessage:(ACConversationType)conversationType
                  targetId:(long)targetId
                   content:(ACMessageContent *)content
                pushConfig:(ACMessagePushConfig *)pushConfig
                sendConfig:(ACSendMessageConfig *)sendConfig
                   success:(void (^)(long messageId))successBlock
                     error:(void (^)(ACErrorCode nErrorCode, long messageId))errorBlock {
    ACMessage *message = [[ACMessage alloc] initWithType:conversationType targetId:targetId direction:MessageDirection_SEND content:content];
    message.messagePushConfig = pushConfig;
    return [self p_sendMessage:message toUserIdList:nil sendConfig:sendConfig progress:nil success:^(ACMessage *successMessage) {
        !successBlock ?: successBlock(message.messageId);
    } error:^(ACErrorCode errorCode, ACMessage *errorMessage) {
        !errorBlock ?: errorBlock(errorCode, errorMessage.messageId);
    }];
}

- (ACMessage *)sendMediaMessage:(ACConversationType)conversationType
                       targetId:(long)targetId
                        content:(ACMessageContent *)content
                     pushConfig:(ACMessagePushConfig *)pushConfig
                     sendConfig:(ACSendMessageConfig *)sendConfig
                       progress:(void (^)(int progress, long messageId))progressBlock
                        success:(void (^)(long messageId))successBlock
                          error:(void (^)(ACErrorCode errorCode, long messageId))errorBlock
                         cancel:(void (^)(long messageId))cancelBlock {
    ACMessage *message = [[ACMessage alloc] initWithType:conversationType targetId:targetId direction:MessageDirection_SEND content:content];
    message.messagePushConfig = pushConfig;
    return [self p_sendMessage:message toUserIdList:nil sendConfig:sendConfig progress:^(int progress, ACMessage *progressMessage) {
        !progressBlock ?: progressBlock(progress, progressMessage.messageId);
    } success:^(ACMessage *successMessage) {
        !successBlock ?: successBlock(message.messageId);
    } error:^(ACErrorCode errorCode, ACMessage *errorMessage) {
        !errorBlock ?: errorBlock(errorCode, errorMessage.messageId);
    }];
}

- (ACMessage *)sendMessage:(ACMessage *)message
              successBlock:(void (^)(ACMessage *successMessage))successBlock
                errorBlock:(void (^)(ACErrorCode nErrorCode, ACMessage *errorMessage))errorBlock {
    return [self p_sendMessage:message toUserIdList:nil sendConfig:nil progress:nil success:successBlock error:errorBlock];
}

- (ACMessage *)sendMediaMessage:(ACMessage *)message
                       progress:(void (^)(int progress, ACMessage *progressMessage))progressBlock
                   successBlock:(void (^)(ACMessage *successMessage))successBlock
                     errorBlock:(void (^)(ACErrorCode nErrorCode, ACMessage *errorMessage))errorBlock
                         cancel:(void (^)(ACMessage *cancelMessage))cancelBlock {
    return [self p_sendMessage:message toUserIdList:nil sendConfig:nil progress:progressBlock success:successBlock error:errorBlock];
}

- (BOOL)cancelSendMediaMessage:(long)messageId {
    [ACLogger debug:@"cancelSendMediaMessage: %ld", messageId];
    return [[ACMessageSenderManager shared] cancelSendMediaMessage:messageId];
}


- (ACMessage *)sendDirectionalMessage:(ACConversationType)conversationType
                             targetId:(long)targetId
                         toUserIdList:(NSArray *)userIdList
                              content:(ACMessageContent *)content
                           pushConfig:(ACMessagePushConfig *)pushConfig
                           sendConfig:(ACSendMessageConfig *)sendConfig
                              success:(void (^)(long messageId))successBlock
                                error:(void (^)(ACErrorCode nErrorCode, long messageId))errorBlock {
    ACMessage *message = [[ACMessage alloc] initWithType:conversationType targetId:targetId direction:MessageDirection_SEND content:content];
    message.messagePushConfig = pushConfig;
    return [self sendDirectionalMessage:message toUserIdList:userIdList successBlock:^(ACMessage * _Nonnull successMessage) {
        !successBlock ?: successBlock(message.messageId);
    } errorBlock:^(ACErrorCode nErrorCode, ACMessage * _Nonnull errorMessage) {
        !errorBlock ?: errorBlock(nErrorCode, errorMessage.messageId);
    }];
}

- (ACMessage *)sendDirectionalMessage:(ACMessage *)message
                         toUserIdList:(NSArray *)userIdList
                         successBlock:(void (^)(ACMessage *successMessage))successBlock
                           errorBlock:(void (^)(ACErrorCode nErrorCode, ACMessage *errorMessage))errorBlock {
    return [self p_sendMessage:message toUserIdList:userIdList sendConfig:nil progress:nil success:successBlock error:errorBlock];
}

- (ACMessage *)p_sendMessage:(ACMessage *)message
                toUserIdList:(NSArray *)userIdList
                  sendConfig:(ACSendMessageConfig *)sendConfig
                  progress:(void (^)(int progress, ACMessage *progressMessage))progressBlock
                   success:(void (^)(ACMessage *successMessage))successBlock
                     error:(void (^)(ACErrorCode errorCode, ACMessage *errorMessage))errorBlock {
    
    NSString *paramsStr = [NSString stringWithFormat:@"conversationType: %zd, targetId: %ld", message.conversationType, message.targetId];
    
    ACLog(@"send message -> %@", paramsStr);
    
    void(^errorBlockTmp)(ACErrorCode, ACMessage *)  = ^(ACErrorCode errorCode, ACMessage *errorMessage){
        [ACLogger warn:@"send message fail -> %@, code: %zd", paramsStr, errorCode];
        !errorBlock ?: errorBlock(errorCode, errorMessage);
    };
    void(^successBlockTmp)(ACMessage *) = ^(ACMessage *successMessage) {
        ACLog(@"send message success -> %@", paramsStr);
        !successBlock ?: successBlock(successMessage);
    };
    
    if (![ACIMGlobal shared].hasInitialized) {
        errorBlockTmp(CLIENT_NOT_INIT, 0);
        return nil;
    }
    if (![ACIMGlobal shared].isUserDataInitialized || ![ACIMGlobal shared].isConnectionExist) {
        errorBlockTmp(BIZ_SAVE_MESSAGE_ERROR, 0);
        return nil;
    }
    
 
    return [[ACMessageSenderManager shared] sendMessage:message toUserIdList:userIdList sendConfig:sendConfig progress:progressBlock success:successBlockTmp error:errorBlockTmp];
}


- (ACMessage *)insertOutgoingMessage:(ACConversationType)conversationType
                            targetId:(long)targetId
                          sentStatus:(ACSentStatus)sentStatus
                             content:(ACMessageContent *)content
                            sentTime:(long long)sentTime {
    return [[ACChannelClient sharedChannelManager] insertOutgoingMessage:conversationType targetId:targetId channelId:nil sentStatus:sentStatus content:content sentTime:sentTime];
}

- (void)downloadMediaMessage:(long)messageId
                    progress:(void (^)(int progress))progressBlock
                     success:(void (^)(NSString *mediaPath))successBlock
                       error:(void (^)(ACErrorCode errorCode))errorBlock
                      cancel:(void (^)(void))cancelBlock {
    [ACLogger debug:@"download mediaMessage -> %ld", messageId];

    void (^errorBlockTmp)( ACErrorCode) = ^(ACErrorCode code) {
        [ACLogger warn:@"download mediaMessage fail -> %ld, code: %zd", messageId,code];
        !errorBlock ?: errorBlock(code);
    };
    
    if (![ACIMGlobal shared].hasInitialized) {
        errorBlockTmp(CLIENT_NOT_INIT);
        return;
    }
    if (![ACIMGlobal shared].isUserDataInitialized) {
        errorBlockTmp(BIZ_SAVE_MESSAGE_ERROR);
        return;
    }
    
    [ACMessageDownloader downloadMediaMessage:messageId progress:^(NSProgress * _Nonnull progress) {
        !progressBlock ?: progressBlock((int)(progress.fractionCompleted * 100));
    } success:successBlock error:^(ACErrorCode errorCode) {
        errorBlockTmp(errorCode);
    } cancel:cancelBlock];
}

- (BOOL)cancelDownloadMediaMessage:(long)messageId {
    if (![ACIMGlobal shared].hasInitialized) {
        return NO;
    }
    if (![ACIMGlobal shared].isUserDataInitialized) {
        return NO;
    }
    return [ACMessageDownloader cancelDownloadMediaMessage:messageId];
}

#pragma mark - ACIMClientReceiveMessageDelegate

- (void)setReceiveMessageDelegate:(id<ACIMClientReceiveMessageDelegate>)delegate object:(id)userData {
    [self addReceiveMessageDelegate:delegate];
}

- (void)addReceiveMessageDelegate:(id<ACIMClientReceiveMessageDelegate>)delegate {
    @synchronized (self) {
        [self.receiveMessageDelegateArr addObject:delegate];
    }
}

- (void)removeReceiveMessageDelegate:(id<ACIMClientReceiveMessageDelegate>)delegate {
    @synchronized (self) {
        [self.receiveMessageDelegateArr removeObject:delegate];
    }
}

- (void)enumerateReceiveMessageDelegates:(void(^)(id<ACIMClientReceiveMessageDelegate> delegate, BOOL *stop))enumeration {
    NSArray *arr;
    @synchronized (self) {
        arr = [self.receiveMessageDelegateArr allObjects];
    }
    BOOL stop = NO;
    for (id<ACIMClientReceiveMessageDelegate> listener in arr) {
        enumeration(listener, &stop);
        if (stop) break;
    }
}


- (void)recallMessage:(ACMessage *)message
          pushContent:(NSString *)pushContent
              success:(void (^)(long messageId))successBlock
                error:(void (^)(ACErrorCode errorcode))errorBlock {
    
    NSString *paramsStr = [NSString stringWithFormat:@"conversationType: %zd, targetId: %ld, messageUId: %ld", message.conversationType, message.targetId, message.messageUId];
    [ACLogger debug:@"recall message -> %@", paramsStr];
    
    
    void (^errorBlockTmp)( ACErrorCode) = ^(ACErrorCode code) {
        [ACLogger warn:@"recall message fail -> %@, code: %zd", paramsStr,code];
        !errorBlock ?: errorBlock(code);
    };
    
    
    if (![ACIMGlobal shared].hasInitialized) {
        errorBlockTmp(CLIENT_NOT_INIT);
        return;
    }
    if (![ACIMGlobal shared].isUserDataInitialized) {
        errorBlockTmp(BIZ_SAVE_MESSAGE_ERROR);
        return;
    }
    if (!message) {
        errorBlockTmp(AC_RECALLMESSAGE_PARAMETER_INVALID);
        return;
    }
    long rowId = message.messageId;
    ACDialogMo *dialog = [[ACDialogManager sharedDialogManger] selectDialogsForMsgId:rowId];
    if (!dialog) {
        errorBlockTmp(INVALID_PARAMETER_MESSAGEID);
        return;
    }
    
    ACSocketPacket *packet;
    if (dialog.Property_ACDialogs_groupFlag) {
        packet = [[ACRecallGroupChatMessagePacket alloc] initWithDialogId:dialog.Property_ACDialogs_dialogId messageRemoteId:message.messageUId];
        
    } else {
        packet = [[ACRecallPrivateChatMessagePacket alloc] initWithDialogId:dialog.Property_ACDialogs_dialogId messageRemoteId:message.messageUId];
        
    }
    [packet sendWithSuccessBlockEmptyParameter:^{
        [[ACMessageManager shared] changeLocalMessageAsRecallStatusWithRemoteId:message.messageUId dialogId:dialog.Property_ACDialogs_dialogId recallTime:[ACServerTime getServerMSTime] extra:nil finalMessage:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(message.messageId);
        });
    } failure:^(NSError * _Nonnull error, NSInteger errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlockTmp([ACNetErrorConverter toAcErrorCodeEnumProperty:errorCode]);
        });
    }];
}

#pragma mark - Message Operation

- (NSArray *)getHistoryMessages:(ACConversationType)conversationType
                       targetId:(long)targetId
                     objectName:(NSString *)objectName
                  baseMessageId:(long)baseMessageId
                      isForward:(BOOL)isForward
                          count:(int)count {
    NSString *conversationParamStr = [NSString stringWithFormat:@"conversationType: %zd, targetId: %ld", conversationType, targetId];
    [ACLogger debug:@"get historyMessages -> %@, objectName: %@, baseMessageId: %ld, isForward: %zd, count: %zd", conversationParamStr, objectName, baseMessageId, isForward, count];

    if (![ACIMGlobal shared].isUserDataInitialized) {
        [ACLogger warn:@"get historyMessages fail -> %@, code: %zd", conversationParamStr, AC_CLIENT_NOT_INIT];
        return nil;
    };
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId];
    if (![NSString ac_isValidString:dialogId]) {
        [ACLogger warn:@"get historyMessages fail -> %@, code: %zd", conversationParamStr, AC_INVALID_PARAMETER];
        return nil;
    };
    
    NSArray *messageTypes;
    if (objectName.length) {
        messageTypes = @[objectName];
    }
    

    NSArray *originalMessages = [[ACMessageManager shared] getMessagesWithDialogId:dialogId count:count msgId:baseMessageId isForward:isForward messageTypes:messageTypes];
    
    NSMutableArray<ACMessage *> *retArray = [NSMutableArray array];
    for (ACMessageMo *mo in originalMessages) {
        [retArray addObject:[mo toRCMessage]];
    }
    if (retArray.count) {
        [ACLogger debug:@"get historyMessages success -> %@, count: %zd, firstMessage: %ld, lastMessage: %ld", conversationParamStr, retArray.count, retArray[0].sentTime, retArray.lastObject.sentTime];
    } else {
        [ACLogger debug:@"get historyMessages success -> %@, count: 0", conversationParamStr];
    }
    
    return retArray;
    
}

- (NSArray *)getHistoryMessages:(ACConversationType)conversationType
                       targetId:(long)targetId
                    objectNames:(NSArray *)objectNames
                       sentTime:(long long)sentTime
                      isForward:(BOOL)isForward
                          count:(int)count {
    NSString *conversationParamStr = [NSString stringWithFormat:@"conversationType: %zd, targetId: %ld", conversationType, targetId];
    [ACLogger debug:@"get historyMessagesByTimestamp -> %@, objectNames: %@, sentTime: %ld, isForward: %zd, count: %zd", conversationParamStr, [objectNames componentsJoinedByString:@","], sentTime, isForward, count];
    
    if (![ACIMGlobal shared].isUserDataInitialized) {
        [ACLogger debug:@"get historyMessagesByTimestamp fail -> %@, code: %zd", conversationParamStr, AC_CLIENT_NOT_INIT];
        return nil;
    }
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId];
    if (![NSString ac_isValidString:dialogId]) {
        [ACLogger debug:@"get historyMessagesByTimestamp fail -> %@, code: %zd", conversationParamStr,AC_INVALID_PARAMETER];
        return nil;
    };
    

    NSArray *originalMessages = [[ACMessageManager shared] getMessagesWithDialogId:dialogId count:count recordTime:(long)sentTime isForward:isForward messageTypes:objectNames];
    
    NSMutableArray<ACMessage *> *retArray = [NSMutableArray array];
    for (ACMessageMo *mo in originalMessages) {
        [retArray addObject:[mo toRCMessage]];
    }
    if (retArray.count) {
        [ACLogger debug:@"get historyMessagesByTimestamp success -> %@, count: %zd, firstMessage: %ld, lastMessage: %ld", conversationParamStr, retArray.count, retArray[0].sentTime, retArray.lastObject.sentTime];
    } else {
        [ACLogger debug:@"get historyMessagesByTimestamp success -> %@, count: 0", conversationParamStr];
    }

    return [retArray copy];
}

- (void)clearHistoryMessages:(ACConversationType)conversationType
                    targetId:(long)targetId
                  recordTime:(long long)recordTime
                 clearRemote:(BOOL)clearRemote
                     success:(void (^)(void))successBlock
                       error:(void (^)(ACErrorCode status))errorBlock {
    [[ACChannelClient sharedChannelManager] clearHistoryMessages:conversationType targetId:targetId channelId:nil recordTime:recordTime clearRemote:clearRemote success:successBlock error:errorBlock];
}

- (void)getRemoteHistoryMessages:(ACConversationType)conversationType
                        targetId:(long)targetId
                      recordTime:(long long)recordTime
                           count:(int)count
                        complete:(void (^)(NSArray *messages, ACErrorCode code))complete {
    [[ACChannelClient sharedChannelManager] getRemoteHistoryMessages:conversationType targetId:targetId channelId:nil recordTime:recordTime count:count complete:complete];
}

- (NSArray *)getUnreadMentionedMessages:(ACConversationType)conversationType targetId:(long)targetId {
    return [[ACChannelClient sharedChannelManager] getUnreadMentionedMessages:conversationType targetId:targetId channelId:nil];;
}

- (ACMessage *)getMessage:(long)messageId  {
    [ACLogger debug:@"get message"];
    
    if (![ACIMGlobal shared].isUserDataInitialized) return nil;

    return [[[ACMessageManager shared] getMessageWithMsgId:messageId] toRCMessage];
}

- (ACMessage *)getMessageByUId:(long)messageUId {
    [ACLogger debug:@"get messageByUid"];
    
    if (messageUId <= 0) return nil;
    
    if (![ACIMGlobal shared].isUserDataInitialized) return nil;

    return [[[ACMessageManager shared] getMessageWithRemoteId:messageUId] toRCMessage];
}

- (ACMessage *)getFirstUnreadMessage:(ACConversationType)conversationType targetId:(long)targetId {
    [ACLogger debug:@"get firstUnreadMessage -> conversationType: %zd, targetId: %ld", conversationType, targetId];
    
    if (![ACIMGlobal shared].isUserDataInitialized) return nil;
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId];
    if (![NSString ac_isValidString:dialogId]) {
        return nil;
    };
   
    if (conversationType == ConversationType_PRIVATE || conversationType == ConversationType_GROUP) {
        return [[[ACMessageManager shared] getFirstUnreadMessageWithDilogId:dialogId] toRCMessage];
    }
    
    return nil;
}

- (BOOL)deleteMessages:(NSArray<NSNumber *> *)messageIds {
    
    if (![ACIMGlobal shared].isUserDataInitialized) return NO;
    
    if (!messageIds.count)  return NO;
    
    [ACLogger debug:@"delete messages -> %@", [messageIds componentsJoinedByString:@","]];
    
    ACDialogMo *dialog = [[ACDialogManager sharedDialogManger] selectDialogsForMsgId:[messageIds.firstObject longValue]];
    if (dialog) {
        [[ACMessageManager shared] deleteMessageWithMsgIds:messageIds dialogId:dialog.Property_ACDialogs_dialogId];
        [[ACDialogManager sharedDialogManger] flushDialogUpdateTimeByLatestMessageSentTime:dialog.Property_ACDialogs_dialogId];
    }
    
    return YES;
}

- (void)deleteMessages:(ACConversationType)conversationType
              targetId:(long)targetId
               success:(void (^)(void))successBlock
                 error:(void (^)(ACErrorCode status))errorBlock {
    [[ACChannelClient sharedChannelManager] deleteMessages:conversationType targetId:targetId channelId:nil success:successBlock error:errorBlock];
}

- (BOOL)setMessageSentStatus:(long)messageId sentStatus:(ACSentStatus)sentStatus {
    [ACLogger debug:@"set messageSentStatus"];
    
    if (![ACIMGlobal shared].hasInitialized) {
        return NO;
    }
    if (![ACIMGlobal shared].isUserDataInitialized) {
        return NO;
    }

    ACMessageMo *message = [[ACMessageManager shared] getMessageWithMsgId:messageId];
    if (!message) return NO;
    
    [message setMessageStatusWithRCSentStatus:sentStatus];
    [[ACMessageManager shared] updateMessage:message];
    return YES;
}


- (BOOL)setMessageReceivedStatus:(long)messageId receivedStatus:(ACReceivedStatus)receivedStatus {
    [ACLogger debug:@"set messageReceivedStatus"];
    
    if (![ACIMGlobal shared].hasInitialized) {
        return NO;
    }
    if (![ACIMGlobal shared].isUserDataInitialized) {
        return NO;
    }

    ACMessageMo *message = [[ACMessageManager shared] getMessageWithMsgId:messageId];
    if (!message) return NO;
    
    [message setMessageStatusWithRCReceiveStatus:receivedStatus];
    [[ACMessageManager shared] updateMessage:message];
    return YES;
}

#pragma mark - Search

- (NSArray<ACMessage *> *)searchMessages:(ACConversationType)conversationType
                                targetId:(long)targetId
                                 keyword:(NSString *)keyword
                                   count:(int)count
                               startTime:(long long)startTime {
    return [[ACChannelClient sharedChannelManager] searchMessages:conversationType targetId:targetId channelId:nil keyword:keyword count:count startTime:startTime];
}

#pragma mark - 消息扩展

- (void)updateMessageExpansion:(NSDictionary<NSString *, NSString *> *)expansionDic
                    messageId:(long)messageId
                       success:(void (^)(void))successBlock
                         error:(void (^)(ACErrorCode status))errorBlock {
    

    [ACLogger debug:@"update messageExpansion -> %ld", messageId];
    
    
    void (^errorBlockTmp)( ACErrorCode) = ^(ACErrorCode code) {
        [ACLogger warn:@"update messageExpansion fail -> %ld", messageId];
        !errorBlock ?: errorBlock(code);
    };
    
    
    if (![ACIMGlobal shared].hasInitialized) {
        errorBlockTmp(CLIENT_NOT_INIT);
        return;
    }
    if (![ACIMGlobal shared].isUserDataInitialized) {
        errorBlockTmp(BIZ_SAVE_MESSAGE_ERROR);
        return;
    }
    

    ACMessageMo *messageMo = [[ACMessageManager shared] getMessageWithMsgId:messageId];
    if (!messageMo) {
        errorBlockTmp(INVALID_PARAMETER);
        return;
    }
                              
    messageMo.Property_ACMessage_expansionStr = expansionDic.count ? [NSString ac_jsonStringWithJsonObject:expansionDic] : nil;
    [[ACMessageManager shared] updateMessage:messageMo];
}

#pragma mark - 日志

- (void)reportLogs {
    [ACReportLog report];
}


#pragma mark - 工具类方法

+ (NSString *)getVersion {
    return [ACIMLibInfo libVersion];
}

#pragma mark - 事件监听

- (void)onReceiveNewMessages:(NSDictionary *)latestMessageDict hasPackage:(NSNumber *)hasPackage {
    NSArray *messages = [self resolveNewMessagesData:latestMessageDict];
    [messages enumerateObjectsUsingBlock:^(ACMessage *message, NSUInteger idx, BOOL * _Nonnull stop) {
        int left = (int)(messages.count - idx - 1);
        [self enumerateReceiveMessageDelegates:^(id<ACIMClientReceiveMessageDelegate> delegate, BOOL *stop) {
            if ([delegate respondsToSelector:@selector(onReceived:left:object:offline:hasPackage:)]) {
                [delegate onReceived:message left:left object:nil offline:message.isOffLine hasPackage:hasPackage.boolValue];
            }
            if ([delegate respondsToSelector:@selector(onReceived:left:object:)]) {
                [delegate onReceived:message left:left object:nil];
            }
        }];
        
    }];
}

- (void)onOfflineMessageSyncCompleted {
    [self enumerateReceiveMessageDelegates:^(id<ACIMClientReceiveMessageDelegate> delegate, BOOL *stop) {
        if ([delegate respondsToSelector:@selector(onOfflineMessageSyncCompleted)]) {
            [delegate onOfflineMessageSyncCompleted];
        }
    }];
}

- (void)messageDidRecall:(ACMessageMo *)message {
    [self enumerateReceiveMessageDelegates:^(id<ACIMClientReceiveMessageDelegate> delegate, BOOL *stop) {
        if ([delegate respondsToSelector:@selector(messageDidRecall:)]) {
            [delegate messageDidRecall:[message toRCMessage]];
        }
    }];
}

#pragma mark - ACConnectionListenerProtocol

- (void)onConnectStatusChanged:(ACConnectionStatus)status {
    [self enumerateConnectionStatusChangeDelegates:^(id<ACConnectionStatusChangeDelegate> delegate, BOOL *stop) {
        if ([delegate respondsToSelector:@selector(onConnectionStatusChanged:)]){
            [delegate onConnectionStatusChanged:status];
        }
    }];
}

- (void)enumerateConnectionStatusChangeDelegates:(void(^)(id<ACConnectionStatusChangeDelegate> delegate, BOOL *stop))enumeration {
    NSArray *arr;
    @synchronized (self) {
        arr = [self.receiveMessageDelegateArr allObjects];
    }
    BOOL stop = NO;
    for (id<ACConnectionStatusChangeDelegate> listener in arr) {
        enumeration(listener, &stop);
        if (stop) break;
    }
}


#pragma mark - Helper

- (NSSet *)p_supportedConversationTypes {
    return [[NSSet alloc] initWithArray:@[@(ConversationType_PRIVATE), @(ConversationType_GROUP), @(ConversationType_ULTRAGROUP)]];
}

- (NSArray *)resolveNewMessagesData:(NSDictionary *)data {
    NSMutableArray *retArray = [NSMutableArray array];
    [data enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSArray<ACMessageMo *> *messageArr = obj;
        for (ACMessageMo *originalMsg in messageArr) {
            [retArray addObject:[originalMsg toRCMessage]];
        }
    }];
    
    return [retArray copy];
}

- (void)registerMessages {
    [[ACMessageSerializeSupport shared] registerMessageContentClass:ACTextMessage.class];
    [[ACMessageSerializeSupport shared] registerMessageContentClass:ACImageMessage.class];
    [[ACMessageSerializeSupport shared] registerMessageContentClass:ACSightMessage.class];
    [[ACMessageSerializeSupport shared] registerMessageContentClass:ACFileMessage.class];
    [[ACMessageSerializeSupport shared] registerMessageContentClass:ACGIFMessage.class];
    [[ACMessageSerializeSupport shared] registerMessageContentClass:ACHQVoiceMessage.class];
    [[ACMessageSerializeSupport shared] registerMessageContentClass:ACRecallNotificationMessage.class];
    
    [[ACMessageSerializeSupport shared] registerMessageContentClass:ACCommandMessage.class];
    [[ACMessageSerializeSupport shared] registerMessageContentClass:ACContactNotificationMessage.class];
    
    [[ACMessageSerializeSupport shared] registerMessageContentClass: ACIMIWCommandMessage.class];
    [[ACMessageSerializeSupport shared] registerMessageContentClass: ACIMIWStorageMessage.class];
    [[ACMessageSerializeSupport shared] registerMessageContentClass: ACIMIWNormalMessage.class];
    [[ACMessageSerializeSupport shared] registerMessageContentClass: ACIMIWStatusMessage.class];

}

@end
