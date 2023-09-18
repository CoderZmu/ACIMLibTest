//
//  ACChannelClient.m
//  ACIMLib
//
//  Created by 子木 on 2022/8/3.
//

#import "ACChannelClient.h"
#import "ACHistoryMessageService.h"
#import "NSObject+EventBus.h"
#import "ACActionType.h"
#import "ACMessageManager.h"
#import "ACDialogIdConverter.h"
#import "ACDialogManager.h"
#import "ACMessageSenderManager.h"
#import "ACMessageSerializeSupport.h"
#import "ACMessageMo+Adapter.h"
#import "ACIMGlobal.h"
#import "ACBase.h"
#import "ACLogger.h"

@interface ACChannelClient()
@property (nonatomic, weak) id<ACUltraGroupConversationDelegate> ultraGroupDelegate;
@end

@implementation ACChannelClient

+ (ACChannelClient *)sharedChannelManager {
    static ACChannelClient *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ACChannelClient alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self ac_connectGlobalEventName:kSuperGroupConversationListDidSyncNoti selector:@selector(uperGroupConversationListDidSync)];
    }
    return self;
}

- (void)setUltraGroupConversationDelegate:(id<ACUltraGroupConversationDelegate>)delegate {
    self.ultraGroupDelegate = delegate;
}

#pragma mark - 会话列表

- (BOOL)setConversationToTop:(ACConversationType)conversationType targetId:(long)targetId channelId:(NSString *)channelId isTop:(BOOL)isTop {
    [ACLogger debug:@"set conversation to top -> conversationType: %zd, targetId: %ld", conversationType, targetId];
    if (![ACIMGlobal shared].isUserDataInitialized) return NO;
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:channelId];
    if (![NSString ac_isValidString:dialogId]) return NO;
    return [[ACDialogManager sharedDialogManger] setDialog:dialogId stickyFlag:isTop];
}

#pragma mark - 发送消息

- (ACMessage *)sendMessage:(ACConversationType)conversationType
                  targetId:(long)targetId
                 channelId:(NSString *)channelId
                   content:(ACMessageContent *)content
                pushConfig:(ACMessagePushConfig *)pushConfig
                sendConfig:(ACSendMessageConfig *)sendConfig
                   success:(void (^)(long messageId))successBlock
                     error:(void (^)(ACErrorCode nErrorCode, long messageId))errorBlock {
    return  [self p_sendMessage:conversationType targetId:targetId channelId:channelId toUserIdList:nil content:content pushConfig:pushConfig sendConfig:sendConfig progress:nil success:successBlock error:errorBlock];
    
}

- (ACMessage *)sendMediaMessage:(ACConversationType)conversationType
                       targetId:(long)targetId
                      channelId:(NSString *)channelId
                        content:(ACMessageContent *)content
                     pushConfig:(ACMessagePushConfig *)pushConfig
                     sendConfig:(ACSendMessageConfig *)sendConfig
                       progress:(void (^)(int progress, long messageId))progressBlock
                        success:(void (^)(long messageId))successBlock
                          error:(void (^)(ACErrorCode errorCode, long messageId))errorBlock
                         cancel:(void (^)(long messageId))cancelBlock {
    return  [self p_sendMessage:conversationType targetId:targetId channelId:channelId toUserIdList:nil content:content pushConfig:pushConfig sendConfig:sendConfig progress:progressBlock success:successBlock error:errorBlock];
}


- (ACMessage *)sendDirectionalMessage:(ACConversationType)conversationType
                             targetId:(long)targetId
                            channelId:(NSString *)channelId
                         toUserIdList:(NSArray *)userIdList
                              content:(ACMessageContent *)content
                           pushConfig:(ACMessagePushConfig *)pushConfig
                           sendConfig:(ACSendMessageConfig *)sendConfig
                              success:(void (^)(long messageId))successBlock
                                error:(void (^)(ACErrorCode nErrorCode, long messageId))errorBlock {
    return  [self p_sendMessage:conversationType targetId:targetId channelId:channelId toUserIdList:userIdList content:content  pushConfig:pushConfig sendConfig:sendConfig progress:nil success:successBlock error:errorBlock];
}


- (ACMessage *)p_sendMessage:(ACConversationType)conversationType
                  targetId:(long)targetId
                   channelId:(NSString *)channelId
                toUserIdList:(NSArray *)userIdList
                   content:(ACMessageContent *)content
                  pushConfig:(ACMessagePushConfig *)pushConfig
                  sendConfig:(ACSendMessageConfig *)sendConfig
                  progress:(void (^)(int progress, long messageId))progressBlock
                   success:(void (^)(long messageId))successBlock
                     error:(void (^)(ACErrorCode errorCode, long messageId))errorBlock {
    
    NSString *paramsStr = [NSString stringWithFormat:@"conversationType: %zd, targetId: %ld", conversationType, targetId];
    
    ACLog(@"send message -> %@", paramsStr);
    
    void(^errorBlockTmp)(ACErrorCode, long)  = ^(ACErrorCode errorCode, long messageId){
        [ACLogger warn:@"send message fail -> %@, code: %zd", paramsStr, errorCode];
        !errorBlock ?: errorBlock(errorCode, messageId);
    };
    void(^successBlockTmp)(long) = ^(long messageId) {
        ACLog(@"send message success -> %@", paramsStr);
        !successBlock ?: successBlock(messageId);
    };
    
    if (![ACIMGlobal shared].hasInitialized) {
        errorBlockTmp(CLIENT_NOT_INIT, 0);
        return nil;
    }
    if (![ACIMGlobal shared].isUserDataInitialized || ![ACIMGlobal shared].isConnectionExist) {
        errorBlockTmp(BIZ_SAVE_MESSAGE_ERROR, 0);
        return nil;
    }
    
    ACMessage *message = [[ACMessage alloc] initWithType:conversationType targetId:targetId direction:MessageDirection_SEND content:content];
    message.channelId = channelId;
    message.messagePushConfig = pushConfig;
    return [[ACMessageSenderManager shared] sendMessage:message toUserIdList:userIdList sendConfig:sendConfig progress:^(int progress, ACMessage * _Nonnull message) {
        !progressBlock ?: progressBlock(progress, message.messageId);
    } success:^(ACMessage * _Nonnull message) {
        successBlockTmp(message.messageId);
    } error:^(ACErrorCode nErrorCode, ACMessage * _Nonnull message) {
        errorBlockTmp(nErrorCode, message.messageId);
    }];
}


- (ACMessage *)insertOutgoingMessage:(ACConversationType)conversationType
                            targetId:(long)targetId
                           channelId:(NSString *)channelId
                          sentStatus:(ACSentStatus)sentStatus
                             content:(ACMessageContent *)content
                            sentTime:(long long)sentTime {
    [ACLogger debug:@"insert outgoing message -> conversationType: %zd, targetId: %ld", conversationType, targetId];
    
    if (![ACIMGlobal shared].isUserDataInitialized)  return nil;
    
    NSString *objectName = [[content class] getObjectName];
    if (![[ACMessageSerializeSupport shared] messageShouldPersisted:objectName]) {
        return nil;
    }
  
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:channelId];
    if (![NSString ac_isValidString:dialogId]) return nil;
    
    ACMessageMo *message = [[ACMessageManager shared] generateBaseMessage:dialogId];
    if (sentTime > 0) {
        message.Property_ACMessage_msgSendTime = sentTime;
    }
    [message setMessageStatusWithRCSentStatus:sentStatus];
    message.Property_ACMessage_objectName = objectName;
    message.Property_ACMessage_mediaAttribute = [NSString ac_jsonStringWithJsonObject:[content encode]];
    
    [[ACMessageManager shared] updateMessage:message];
    
    [[ACDialogManager sharedDialogManger] addTmpLocalDialogIfNotExist:dialogId];
    [[ACDialogManager sharedDialogManger] flushDialogUpdateTimeByLatestMessageSentTime:dialogId];
    ACMessage *retVal = [message toRCMessage];
    retVal.content = content;
    return retVal;
}

#pragma mark - 消息操作

- (void)getMessages:(ACConversationType)conversationType
           targetId:(long)targetId
          channelId:(NSString *)channelId
             option:(ACHistoryMessageOption *)option
           complete:(void (^)(NSArray *messages, ACErrorCode code))complete {
    NSString *conversationParamStr = [NSString stringWithFormat:@"conversationType: %zd, targetId: %ld", conversationType, targetId];
    [ACLogger debug:@"getMessages -> %@, recordTime: %ld, count: %zd", conversationParamStr, option.recordTime, option.count];
 
    void (^completeBlockTmp)(NSArray *, ACErrorCode) = ^(NSArray<ACMessage *> *messages, ACErrorCode code) {
        !complete ?: complete(messages, code);
        if (code == AC_SUCCESS) {
            if (messages.count) {
                [ACLogger debug:@"getMessages success -> %@, count: %zd, firstMessage: %ld, lastMessage: %ld", conversationParamStr, messages.count, messages[0].sentTime, messages.lastObject.sentTime];
            } else {
                [ACLogger debug:@"getMessages success -> %@, count: 0", conversationParamStr];
            }
            
        } else {
            [ACLogger warn:@"getMessages fail -> %@, code: %zd", conversationParamStr, code];
        }
    };
    
    if (![ACIMGlobal shared].hasInitialized) {
        completeBlockTmp(@[],CLIENT_NOT_INIT);
        return;
    }
    if (![ACIMGlobal shared].isUserDataInitialized) {
        completeBlockTmp(@[],DATABASE_ERROR);
        return;
    };
    
    [[ACHistoryMessageService shared] getMessages:conversationType targetId:targetId channelId:channelId option:option complete:completeBlockTmp];
   
}

- (void)clearHistoryMessages:(ACConversationType)conversationType
                    targetId:(long)targetId
                   channelId:(NSString *)channelId
                  recordTime:(long long)recordTime
                 clearRemote:(BOOL)clearRemote
                     success:(void (^)(void))successBlock
                       error:(void (^)(ACErrorCode status))errorBlock {
    NSString *paramsStr = [NSString stringWithFormat:@"conversationType: %zd, targetId: %ld", conversationType, targetId];
    [ACLogger debug:@"clear history messages -> %@, recordTime: %ld, clearRemote: %zd", paramsStr, recordTime, clearRemote];
    
    void (^errorBlockTmp)(ACErrorCode) = ^(ACErrorCode code) {
        [ACLogger warn:@"clear history messages fail -> %@, code: %zd", paramsStr, code];
        !errorBlock ?: errorBlock(code);
    };
    
    if (![ACIMGlobal shared].hasInitialized) {
        errorBlockTmp(CLIENT_NOT_INIT);
        return;
    }
    if (![ACIMGlobal shared].isUserDataInitialized) {
        errorBlockTmp(DATABASE_ERROR);
        return;
    }

    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:channelId];
    if (![NSString ac_isValidString:dialogId]) {
        errorBlockTmp(INVALID_PARAMETER);
        return;
    }
    [[ACMessageManager shared] clearMessageWithDialogId:dialogId beforeSentTime:(long)recordTime clearRemote:clearRemote complete:^(ACErrorCode code) {
        if (code == AC_SUCCESS) {
            successBlock();
        } else {
            errorBlockTmp(code);
        }
    }];
}

- (void)getRemoteHistoryMessages:(ACConversationType)conversationType
                        targetId:(long)targetId
                       channelId:(nullable NSString *)channelId
                      recordTime:(long long)recordTime
                           count:(int)count
                        complete:(void (^)(NSArray *messages, ACErrorCode code))complete {
    NSString *conversationParamStr = [NSString stringWithFormat:@"conversationType: %zd, targetId: %ld", conversationType, targetId];
    [ACLogger debug:@"get remoteHistoryMessages -> %@, recordTime: %ld, count: %d", conversationParamStr, recordTime, count];
    ACHistoryMessageOption *option = [[ACHistoryMessageOption alloc] init];
    option.order = ACHistoryMessageOrderDesc;
    option.recordTime = recordTime;
    option.count = count;
    [[ACChannelClient sharedChannelManager] getMessages:conversationType targetId:targetId channelId:channelId option:option complete:^(NSArray<ACMessage *> * _Nonnull messages, ACErrorCode code) {
        if (code == AC_SUCCESS) {
            if (messages.count) {
                [ACLogger debug:@"get remoteHistoryMessages success -> %@, count: %zd, firstMessage: %ld, lastMessage: %ld", conversationParamStr, messages.count, messages[0].sentTime, messages.lastObject.sentTime];
            } else {
                [ACLogger debug:@"get remoteHistoryMessages success -> %@, count: 0", conversationParamStr];
            }
            
        } else {
            [ACLogger warn:@"get remoteHistoryMessages fail -> %@, code: %zd", conversationParamStr, code];
        }
        !complete ?: complete(messages, code);
    }];
}

- (NSArray *)getUnreadMentionedMessages:(ACConversationType)conversationType targetId:(long)targetId channelId:(NSString *)channelId {
    [ACLogger debug:@"get unreadMentionedMessages -> conversationType: %zd, targetId: %ld", conversationType, targetId];
    
    if (![ACIMGlobal shared].isUserDataInitialized) {
        return nil;
    }
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:channelId];
    if (![NSString ac_isValidString:dialogId]) {
        return nil;
    }
    NSArray *arr = [[ACMessageManager shared] getUnreadMentionedMessagesWithDialogId:dialogId];
    NSMutableArray *retVal = [NSMutableArray array];
    for (ACMessageMo *messageMo in arr) {
        [retVal addObject:[messageMo toRCMessage]];
    }
    return [retVal copy];
}

- (void)getFirstUnreadMessageAsynchronously:(ACConversationType)conversationType targetId:(long)targetId channelId:(nullable NSString *)channelId complete:(void (^)(ACMessage *message, ACErrorCode code))complete {
    long unreadCount = [self getUnreadCount:conversationType targetId:targetId channelId:channelId];
    if (unreadCount <= 0) {
        complete(nil, AC_SUCCESS);
        return;
    }
    
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:channelId];
    if (![NSString ac_isValidString:dialogId]) {
        complete(nil, INVALID_PARAMETER);
        return;
    };
    
    if (conversationType == ConversationType_PRIVATE || conversationType == ConversationType_GROUP) {
        complete([[[ACMessageManager shared] getFirstUnreadMessageWithDilogId:dialogId] toRCMessage],AC_SUCCESS);
    } else if (conversationType == ConversationType_ULTRAGROUP) {
        // 1. 拉取 lastReadTime 后的消息
        long lastReadTime = [[ACDialogManager sharedDialogManger] getDialogLastReadTime:dialogId];
        ACHistoryMessageOption *option = [[ACHistoryMessageOption alloc] init];
        option.count = 20;
        option.order = ACHistoryMessageOrderAsc;
        option.recordTime = lastReadTime;
        [self getMessages:conversationType targetId:targetId channelId:channelId option:option complete:^(NSArray * _Nonnull messages, ACErrorCode code) {
            if (code == AC_SUCCESS) {
                // 2. 从本地消息中读取第一条未读消息
                complete([[[ACMessageManager shared] getFirstUnreadMessageWithDilogId:dialogId] toRCMessage],AC_SUCCESS);
            } else {
                complete(nil, code);
            }
        }];
    } else {
        complete(nil, INVALID_PARAMETER);
    }
    
   
}

- (void)deleteMessages:(ACConversationType)conversationType
              targetId:(long)targetId
             channelId:(NSString *)channelId
               success:(void (^)(void))successBlock
                 error:(void (^)(ACErrorCode status))errorBlock {
    NSString *conversationParamStr = [NSString stringWithFormat:@"conversationType: %zd, targetId: %ld", conversationType, targetId];
    [ACLogger debug:@"delete messages -> %@", conversationParamStr];
    
    void(^errorBlockTmp)(ACErrorCode)  = ^(ACErrorCode errorCode){
        [ACLogger warn:@"delete messages fail -> %@, code: %zd", conversationParamStr, errorCode];
        !errorBlock ?: errorBlock(errorCode);
    };
    
    if (![ACIMGlobal shared].hasInitialized) {
        errorBlockTmp(CLIENT_NOT_INIT);
        return;
    }
    if (![ACIMGlobal shared].isUserDataInitialized) {
        errorBlockTmp(DATABASE_ERROR);
        return;
    }
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:channelId];
    if (![NSString ac_isValidString:dialogId]) {
        errorBlockTmp(INVALID_PARAMETER);
        return;
    }
    [[ACMessageManager shared] clearMessageWithDialogId:dialogId beforeSentTime:0 clearRemote:NO complete:^(ACErrorCode code) {
        if (code == AC_SUCCESS) {
            successBlock();
        } else {
            errorBlockTmp(code);
        }
    }];
}

#pragma mark - 未读消息数

- (int)getUnreadCount:(ACConversationType)conversationType targetId:(long)targetId channelId:(NSString *)channelId {
    [ACLogger debug:@"get unreadCount -> conversationType: %zd, targetId: %ld", conversationType, targetId];
    
    if (![ACIMGlobal shared].isUserDataInitialized) return 0;
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:channelId];
    if (![NSString ac_isValidString:dialogId]) {
        return 0;
    }
    return (int)[[ACDialogManager sharedDialogManger] getDialogUnreadCount:dialogId];
}

- (BOOL)clearAllMessagesUnreadStatus:(ACConversationType)conversationType
                            targetId:(long)targetId channelId:(nullable NSString *)channelId {
    [ACLogger debug:@"clear allMessagesUnreadStatus -> conversationType: %zd, targetId: %ld", conversationType, targetId];
    
    if (![ACIMGlobal shared].isUserDataInitialized) return NO;
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:channelId];
    if (![NSString ac_isValidString:dialogId]) {
        return NO;
    }
    [[ACDialogManager sharedDialogManger] clearAllMessagesUnreadStatusWithDialog:dialogId clearRemote:YES];
    return YES;
}

- (BOOL)clearMessagesUnreadStatus:(ACConversationType)conversationType
                         targetId:(long)targetId
                        channelId:(nullable NSString *)channelId
                             time:(long long)timestamp {
    [ACLogger debug:@"clear messagesUnreadStatus -> conversationType: %zd, targetId: %ld, time: %ld", conversationType, targetId, timestamp];
    
    if (![ACIMGlobal shared].isUserDataInitialized) return NO;
    if (conversationType != ConversationType_PRIVATE && conversationType != ConversationType_GROUP) return NO;
    
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:channelId];
    if (![NSString ac_isValidString:dialogId]) {
        return NO;
    };
    
    [[ACDialogManager sharedDialogManger] clearMessagesUnreadStatusWithDialog:dialogId tillTime:(long)timestamp clearRemote:YES];
    return YES;
}


#pragma mark - 会话的消息提醒

- (void)setConversationChannelNotificationLevel:(ACConversationType)conversationType
                                       targetId:(long)targetId
                                      channelId:(NSString *)channelId
                                          level:(ACPushNotificationLevel)level
                                        success:(void (^)(void))successBlock
                                          error:(void (^)(ACErrorCode status))errorBlock {
    NSString *paramsStr = [NSString stringWithFormat:@"conversationType: %zd, targetId: %ld", conversationType, targetId];
    
    ACLog(@"set conversationChannelNotificationLevel -> %@", paramsStr);
    
    void(^errorBlockTmp)(ACErrorCode)  = ^(ACErrorCode errorCode){
        [ACLogger warn:@"set conversationChannelNotificationLevel fail -> code: %zd, %@", errorCode, paramsStr];
        !errorBlock ?: errorBlock(errorCode);
    };
    
    if (![ACIMGlobal shared].hasInitialized) {
        errorBlockTmp(CLIENT_NOT_INIT);
        return;
    }
    if (![ACIMGlobal shared].isUserDataInitialized) {
        errorBlockTmp(AC_NETWORK_UNAVAILABLE);
        return;
    }
    if (![@[@-1, @1, @2, @4, @5] containsObject:@(level)]) {
        errorBlockTmp(INVALID_PARAMETER);
        return;
    }
    
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:channelId];
    if (![NSString ac_isValidString:dialogId]) {
        errorBlockTmp(INVALID_PARAMETER);
        return;
    }
    if (![ACDialogIdConverter isGroupType:dialogId]) {
        errorBlockTmp(INVALID_PARAMETER_CONVERSATIONTYPENOTSUPPORT);
        return;
    }
    [[ACDialogManager sharedDialogManger] setGroupDialogs:@[dialogId] pushNotificationLevel:(int)level complete:^(ACErrorCode code) {
        if (code == AC_SUCCESS) {
            !successBlock ?: successBlock();
        } else {
            errorBlockTmp(code);
        }
    }];
}

- (void)setConversationListNotificationLevel:(ACConversationType)conversationType
                                       targetIdList:(NSArray *)targetIdList
                                          level:(ACPushNotificationLevel)level
                                        success:(void (^)(void))successBlock
                                       error:(void (^)(ACErrorCode status))errorBlock {

    NSString *paramsStr = [NSString stringWithFormat:@"conversationType: %zd, targetIdList: %@", conversationType, [targetIdList componentsJoinedByString:@","]];
    
    ACLog(@"set conversationListNotificationLevel -> %@", paramsStr);
    
    void(^errorBlockTmp)(ACErrorCode)  = ^(ACErrorCode errorCode){
        [ACLogger warn:@"set conversationListNotificationLevel fail -> %@, code: %zd", paramsStr, errorCode];
        !errorBlock ?: errorBlock(errorCode);
    };
    
    if (![ACIMGlobal shared].hasInitialized) {
        errorBlockTmp(CLIENT_NOT_INIT);
        return;
    }
    if (![ACIMGlobal shared].isUserDataInitialized) {
        errorBlockTmp(AC_NETWORK_UNAVAILABLE);
        return;
    }
    if (!targetIdList.count) {
        !successBlock ?: successBlock();
        return;
    }
    
    if (![@[@-1, @0, @1, @2, @4, @5] containsObject:@(level)]) {
        errorBlockTmp(INVALID_PARAMETER);
        return;
    }
    
    NSMutableArray<NSString *> *dialogIdList = [NSMutableArray array];
    for (id targetIdObj in targetIdList) {
        long targetId = 0;
        if ([targetIdObj isKindOfClass:NSNumber.class]) {
            targetId = [targetIdObj longValue];
        } else if ([targetIdObj isKindOfClass:NSString.class]) {
            targetId = [targetIdObj longLongValue];
        }
        NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:nil];
        if ([NSString ac_isValidString:dialogId] && [ACDialogIdConverter isGroupType:dialogId]) {
            [dialogIdList addObject:dialogId];
        } else {
            break;
        }
    }
    if (dialogIdList.count < targetIdList.count) {
        errorBlockTmp(INVALID_PARAMETER);
        return;
    }
    

    [[ACDialogManager sharedDialogManger] setGroupDialogs:dialogIdList.copy pushNotificationLevel:(int)level complete:^(ACErrorCode code) {
        if (code == AC_SUCCESS) {
            [ACLogger info:@"set conversationListNotificationLevel success"];
            !successBlock ?: successBlock();
        } else {
            errorBlockTmp(code);
        }
    }];
}

- (void)getConversationChannelNotificationLevel:(ACConversationType)conversationType
                                       targetId:(long)targetId
                                      channelId:(NSString *)channelId
                                        success:(void (^)(ACPushNotificationLevel level))successBlock
                                          error:(void (^)(ACErrorCode status))errorBlock {
    [ACLogger debug:@"get ConversationChannelNotificationLevel -> conversationType: %zd, targetId: %ld", conversationType, targetId];
    
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
        
        successBlock(dialogMo.Property_ACDialogs_notificationLevel);
    }];
   
}

#pragma mark - 搜索

- (NSArray<ACMessage *> *)searchMessages:(ACConversationType)conversationType
                                targetId:(long)targetId
                               channelId:(NSString *)channelId
                                 keyword:(NSString *)keyword
                                   count:(int)count
                               startTime:(long long)startTime {
    [ACLogger debug:@"search messages -> conversationType: %zd, targetId: %ld", conversationType, targetId];
    
    if (![ACIMGlobal shared].isUserDataInitialized) {
        return @[];
    }

    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:channelId];
    if (![NSString ac_isValidString:dialogId]) {
        return @[];
    }
    NSArray *originalMessages = [[ACMessageManager shared] searchMessagesWithDialogId:dialogId keyword:keyword count:count recordTime:startTime];
    
    NSMutableArray *retArray = [NSMutableArray array];
    for (ACMessageMo *mo in originalMessages) {
        [retArray addObject:[mo toRCMessage]];
    }
    
    return retArray;
}

- (void)uperGroupConversationListDidSync {
    if ([self.ultraGroupDelegate respondsToSelector:@selector(ultraGroupConversationListDidSync)]) {
        [self.ultraGroupDelegate ultraGroupConversationListDidSync];
    }
}

@end
