//
//  ACMessageSendOperation.m
//  ACIMLib
//
//  Created by 子木 on 2022/7/6.
//

#import "AcpbGroupchat.pbobjc.h"
#import "AcpbPrivatechat.pbobjc.h"
#import "ACAccountManager.h"
#import "ACBase.h"
#import "ACDialogIdConverter.h"
#import "ACDialogManager.h"
#import "ACFileUploader.h"
#import "ACMediaMessageContent.h"
#import "ACMessageManager.h"
#import "ACMessageMo+Adapter.h"
#import "ACMessageSendOperation.h"
#import "ACMessageSerializeSupport.h"
#import "ACNetErrorConverter.h"
#import "ACSecretKey.h"
#import "ACSendGroupMessagePacket.h"
#import "ACSendMessageStore.h"
#import "ACSendPrivateMessagePacket.h"
#import "ACServerTime.h"
#import "ACSuperGroupOfflineMessageService.h"

static NSString *const MessageSendOperationInitError = @"MessageSendOperationInitError";

@interface ACMessageSendOperation ()
@property (readwrite, getter = isExecuting) BOOL executing;
@property (readwrite, getter = isFinished) BOOL finished;
@property (readwrite, getter = isCancelled) BOOL cancelled;
@property (readwrite, getter = isStarted) BOOL started;
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, strong) ACMessageMo *finalMessage;
@property (nonatomic, strong) ACMessageContent *content;
@property (nonatomic, copy) NSArray *userIdList;
@property (nonatomic, strong) ACMessagePushConfig *pushConfig;
@property (nonatomic, strong) ACSendMessageConfig *sendConfig;
@property (nonatomic, copy) ACSendMessageSuccessBlock successBlock;
@property (nonatomic, copy) ACSendMessageErrorBlock errorBlock;
@property (nonatomic, copy) ACUploadMediaProgressBlock progressBlock;
@property (nonatomic, strong) id<ACMessageSendPreprocessor> preprocessor;
@property (nonatomic, strong) id<ACOssCancellableTask> uploadTask;

@end

@implementation ACMessageSendOperation

@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize cancelled = _cancelled;


- (instancetype)initWithMessage:(ACMessage *)message
                   toUserIdList:(NSArray *)userIdList
                     sendConfig:(ACSendMessageConfig *)sendConfig
                   preprocessor:(id<ACMessageSendPreprocessor>)preprocessor
                          error:(NSError **)error {
    NSString *dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:message.conversationType targetId:message.targetId channelId:message.channelId];
    
    if (![NSString ac_isValidString:dialogId]) {
        *error = [NSError errorWithDomain:MessageSendOperationInitError code:INVALID_PARAMETER userInfo:nil];
        return nil;
    }
    if (![[ACMessageSerializeSupport shared] isSupported:[message.content.class getObjectName]]) {
        *error = [NSError errorWithDomain:MessageSendOperationInitError code:AC_MESSAGE_NOT_REGISTERED  userInfo:nil];
        return nil;
    }
    
    ACMessageMo *baseMessage = [[ACMessageManager shared] generateBaseMessage:dialogId];
    long msgId = baseMessage.Property_ACMessage_msgId;
    
    if (preprocessor) {
        ACErrorCode code = [preprocessor preprocess:message.content dialogId:dialogId msgId:msgId];
        
        if (code != AC_SUCCESS) {
            *error = [NSError errorWithDomain:MessageSendOperationInitError code:code userInfo:nil];
            return nil;
        }
    }
    
    baseMessage.Property_ACMessage_mediaAttribute = [NSString ac_jsonStringWithJsonObject:[message.content encode]];
    baseMessage.Property_ACMessage_objectName = [[message.content class] getObjectName];
    
    if ([message.content isKindOfClass:ACMediaMessageContent.class]) {
        baseMessage.Property_ACMessage_mediaFlag = YES;
    }
    
    self = [super init];
    _userIdList = [userIdList copy];
    _content = message.content;
    _pushConfig = message.messagePushConfig;
    _sendConfig = sendConfig;
    _preprocessor = preprocessor;
    _finalMessage = baseMessage;
    
    [self saveToDB:_finalMessage];
    
    if ([self isMessageNeedStore]) {
        [[ACDialogManager sharedDialogManger] addTmpLocalDialogIfNotExist:[self getDialogId]];
        [[ACDialogManager sharedDialogManger] flushDialogUpdateTimeByLatestMessageSentTime:[self getDialogId]];
    }
    
    _executing = NO;
    _finished = NO;
    _cancelled = NO;
    _lock = [NSRecursiveLock new];
    
    return self;
}

- (void)dealloc {
    [self.lock lock];
    
    if ([self isExecuting]) {
        self.cancelled = YES;
        self.finished = YES;
    }
    
    [self.lock unlock];
}

- (void)setSuccessBlock:(ACSendMessageSuccessBlock)successBlock errorBlock:(ACSendMessageErrorBlock)errorBlock progressBlock:(ACUploadMediaProgressBlock)progressBlock {
    _successBlock = successBlock;
    _errorBlock = errorBlock;
    _progressBlock = progressBlock;
}

- (BOOL)cancelSendMessage {
    if ([self.content isKindOfClass:ACMediaMessageContent.class]) {
        ACMediaMessageContent *mediaMessage = (ACMediaMessageContent *)self.content;
        if (!mediaMessage.remoteUrl.length) {
            [self cancel];
            return YES;
        }
    }
    return NO;
}

- (ACMessage *)getSentMessage {
    ACMessage *msg = [self.finalMessage toRCMessage];
    
    msg.content = self.content;
    return msg;
}

- (long)getMsgId {
    return self.finalMessage.Property_ACMessage_msgId;
}

- (NSString *)getDialogId {
    return self.finalMessage.Property_ACMessage_dialogIdStr;
}

- (void)startOperation {
    if ([self isCancelled]) {
        return;
    }
    
    if (![self.preprocessor respondsToSelector:@selector(compress:dialogId:msgId:complete:)]) {
        [self upload];
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    [self.preprocessor compress:self.content
                       dialogId:[self getDialogId]
                          msgId:[self getMsgId]
                       complete:^(ACErrorCode code) {
        __strong typeof(weakSelf) self = weakSelf;
        
        if (!self || [self isCancelled]) {
            return;
        }
        
        if (code == AC_SUCCESS) {
            [self updateFinalMessageContent];
            [self saveToDB:self.finalMessage];
            [self upload];
            return;
        }
        
        [self.lock lock];
        
        if (![self isCancelled]) {
            self.errorBlock(code, [self getSentMessage]);
        }
        
        [self finishOperation];
        [self.lock unlock];
    }];
}

- (void)upload {
    void (^ completeBlock)(ACErrorCode code) = ^(ACErrorCode code) {
        if (code != AC_SUCCESS) {
            self.finalMessage.Property_ACMessage_deliveryState = ACMessageFailure;
            [self saveToDB:self.finalMessage];
            
            [self.lock lock];
            
            if (![self isCancelled]) {
                self.errorBlock(code, [self getSentMessage]);
            }
            
            [self finishOperation];
            [self.lock unlock];
            return;
        }
        
        [self updateFinalMessageContent];
        
        // 3. 发送信息
        self.finalMessage.Property_ACMessage_deliveryState = ACMessageDelivering;
        [self saveToDB:self.finalMessage];
        [self sendMessageToServer];
    };
    
    if (![self.content isKindOfClass:ACMediaMessageContent.class]) { // 不是媒体消息，不包含需要上传的本地文件
        completeBlock(AC_SUCCESS);
        return;
    }
    
    ACMediaMessageContent *mediaContent = (ACMediaMessageContent *)self.content;
    
    if (mediaContent.remoteUrl.length) { // removeUrl有值
        completeBlock(AC_SUCCESS);
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    _uploadTask = [ACFileUploader uploadSingleFile:mediaContent.localPath
                                          progress:^(int progress) {
        __strong typeof(weakSelf) self = weakSelf;
        
        if (!self || [self isCancelled]) {
            return;
        }
        
        !self.progressBlock ? : self.progressBlock(MIN(99, progress), [self getSentMessage]);
    } complete:^(BOOL success, NSString *_Nullable path, NSString *_Nullable encryptKey) {
        __strong typeof(weakSelf) self = weakSelf;
        
        if (!self || [self isCancelled]) {
            return;
        }
        
        if (success) {
            !self.progressBlock ? : self.progressBlock(100, [self getSentMessage]);
            mediaContent.remoteUrl = path; // 修改消息的remoteUrl属性
            mediaContent.encryptKey = encryptKey;
            completeBlock(AC_SUCCESS);
        } else {
            completeBlock(AC_FILE_UPLOAD_FAILED);
        }
    }];
}

- (void)sendMessageToServer {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ACMessageMo *finalMessage = self.finalMessage;
        
        // 获取加密key
        ACDialogSecretKeyMo *key = [[ACSecretKey instance] getDialogAesKeyWithDialogID:[self getDialogId]];
        
        if (!key) {
            [self.lock lock];
            finalMessage.Property_ACMessage_deliveryState = ACMessageFailure;
            
            if (![self isCancelled]) {
                self.errorBlock(MSG_ENCRYPT_ERROR, [self getSentMessage]);
            }
            
            [self saveToDB:finalMessage];
            [self finishOperation];
            [self.lock unlock];
            return;
        }
        
        NSString *pushConfigString = [self.pushConfig encodePushConfig];
        NSData *mediaAttributeEncryptedData = [finalMessage.Property_ACMessage_mediaAttribute ac_aes128_encrypted_data:key.aesKey withIV:key.aesIv];
        
        // 添加到发送的缓存中
        [[ACSendMessageStore shared] addMessage:finalMessage.Property_ACMessage_localId];
        
        if (self.finalMessage.Property_ACMessage_groupFlag) {
            NSString *userIds; // 定向消息用户ids
            
            if (self.userIdList.count) {
                userIds = [self.userIdList componentsJoinedByString:@","];
            }
            
            BOOL isAtAll = NO;
            NSArray *atList;
            
            if (self.content.mentionedInfo) {
                switch (self.content.mentionedInfo.type) {
                    case AC_Mentioned_All:
                        isAtAll = YES;
                        break;
                        
                    case AC_Mentioned_Users:
                        atList = self.content.mentionedInfo.userIdList;
                        break;
                }
            }
            
            BOOL persistedFlag = [[self.content class] persistentFlag] & MessagePersistent_ISPERSISTED;
            ACSendGroupMessagePacket *api = [[ACSendGroupMessagePacket alloc] initWithDialogId:finalMessage.Property_ACMessage_dialogIdStr localId:finalMessage.Property_ACMessage_localId objectName:finalMessage.Property_ACMessage_objectName mediaFlag:finalMessage.Property_ACMessage_mediaFlag msgContent:mediaAttributeEncryptedData atAll:isAtAll atListArr:atList toUserIdStr:userIds persistedFlag:persistedFlag pushConfig:pushConfigString];
            
            
            __weak __typeof__(self) weakSelf = self;
            [api sendWithSuccessBlockIdParameter:^(ACPBSendGroupChatMessageResp *_Nonnull response) {
                [weakSelf onMessageSendCompleted:AC_SUCCESS
                                     msgRemoteId:response.msgId
                                        sendTime:response.seqno];
            }
                                         failure:^(NSError *_Nonnull error, NSInteger errorCode) {
                [weakSelf onMessageSendCompleted:errorCode
                                     msgRemoteId:0
                                        sendTime:0];
            }];
        } else {
            BOOL persistedFlag = [[self.content class] persistentFlag] & MessagePersistent_ISPERSISTED;
            
            ACSendPrivateMessagePacket *api = [[ACSendPrivateMessagePacket alloc] initWithDialogId:finalMessage.Property_ACMessage_dialogIdStr localId:finalMessage.Property_ACMessage_localId objectName:finalMessage.Property_ACMessage_objectName mediaFlag:finalMessage.Property_ACMessage_mediaFlag msgContent:mediaAttributeEncryptedData persistedFlag:persistedFlag pushConfig:pushConfigString];
            
            __weak __typeof__(self) weakSelf = self;
            [api sendWithSuccessBlockIdParameter:^(ACPBSendPrivateChatMessageResp *_Nonnull response) {
                [weakSelf onMessageSendCompleted:AC_SUCCESS
                                     msgRemoteId:response.msgId
                                        sendTime:response.seqno];
            }
                                         failure:^(NSError *_Nonnull error, NSInteger errorCode) {
                [weakSelf onMessageSendCompleted:errorCode
                                     msgRemoteId:0
                                        sendTime:0];
            }];
        }
    });
}

- (void)onMessageSendCompleted:(NSInteger)errorCode msgRemoteId:(long)msgRemoteId sendTime:(long)sendTime {
    if (!self || [self isCancelled]) {
        return;
    }
    
    [self.lock lock];
    
    if (errorCode == 0) {
        self.finalMessage.Property_ACMessage_isLocal = NO;
        self.finalMessage.Property_ACMessage_remoteId = msgRemoteId;
        self.finalMessage.Property_ACMessage_msgSendTime = sendTime;
        self.finalMessage.Property_ACMessage_deliveryState = ACMessageSuccessed;
        [self saveToDB:self.finalMessage];
        [[ACDialogManager sharedDialogManger] flushDialogUpdateTimeByLatestMessageSentTime:[self getDialogId]];
        
        // 发送成功
        if (![self isCancelled]) {
            self.successBlock([self getSentMessage]);
        }
    } else {
        self.finalMessage.Property_ACMessage_deliveryState = ACMessageFailure;
        
        if (self.sendConfig && self.sendConfig.deleteWhenFailed) {
            [self deleteSentFailedMessage:self.finalMessage];
            [[ACDialogManager sharedDialogManger] flushDialogUpdateTimeByLatestMessageSentTime:[self getDialogId]];
        } else {
            [self saveToDB:self.finalMessage];
        }
        
        if (![self isCancelled]) {
            self.errorBlock([ACNetErrorConverter toAcErrorCodeEnumProperty:errorCode], [self getSentMessage]);
        }
    }
    
    if ([ACDialogIdConverter isSuperGroupType:self.finalMessage.Property_ACMessage_dialogIdStr] && [[ACSuperGroupOfflineMessageService shared] isOfflineMessagesLoaded]) {
        [[ACDialogManager sharedDialogManger] updateSgLastReceiveRecordTime:self.finalMessage.Property_ACMessage_dialogIdStr time:self.finalMessage.Property_ACMessage_msgSendTime];
    }
    
    [self finishOperation];
    [self.lock unlock];
}

- (void)saveToDB:(ACMessageMo *)message {
    if ([self isMessageNeedStore]) {
        [[ACMessageManager shared] updateMessage:message];
    }
}

- (void)deleteSentFailedMessage:(ACMessageMo *)message {
    if ([self isMessageNeedStore]) {
        [[ACMessageManager shared] deleteMessageWithMsgIds:@[@(message.Property_ACMessage_msgId)] dialogId:message.Property_ACMessage_dialogIdStr];
    }
}

- (void)updateFinalMessageContent {
    self.finalMessage.Property_ACMessage_mediaAttribute = [NSString ac_jsonStringWithJsonObject:[self.content encode]];
}

- (BOOL)isMessageNeedStore {
    BOOL isPerisistedMessage = [[ACMessageSerializeSupport shared] messageShouldPersisted:_finalMessage.Property_ACMessage_objectName];
    
    if (!isPerisistedMessage) {
        return NO;
    }
    
    if (self.sendConfig && self.sendConfig.saveWhenSent) {
        return _finalMessage.Property_ACMessage_deliveryState == ACMessageSuccessed;
    }
    
    return YES;
}

- (void)finishOperation {
    self.executing = NO;
    self.finished = YES;
}

- (void)cancelOperation {
    if (self.uploadTask) {
        [self.uploadTask ac_cancel];
    }
    
    if (self.finalMessage) {
        self.finalMessage.Property_ACMessage_deliveryState = ACMessageFailure;
        [self saveToDB:self.finalMessage];
    }
    
    !self.errorBlock ? : self.errorBlock(AC_MSG_CANCELED, [self getSentMessage]);
}

#pragma mark - Override NSOperation

- (void)start {
    BOOL shoudStart = NO;
    
    [self.lock lock];
    self.started = YES;
    
    if ([self isCancelled]) {
        [self cancelOperation];
        self.finished = YES;
    } else if ([self isReady] && ![self isFinished] && ![self isExecuting]) {
        shoudStart = YES;
        self.executing = YES;
    }
    
    [self.lock unlock];
    
    if (shoudStart) {
        [self startOperation];
    }
}

- (void)cancel {
    [self.lock lock];
    
    if (![self isCancelled]) {
        [super cancel];
        self.cancelled = YES;
        
        if ([self isExecuting]) {
            self.executing = NO;
            [self cancelOperation];
        }
        
        if (self.started) {
            self.finished = YES;
        }
    }
    
    [self.lock unlock];
}

- (void)setExecuting:(BOOL)executing {
    [self.lock lock];
    
    if (_executing != executing) {
        [self willChangeValueForKey:@"isExecuting"];
        _executing = executing;
        [self didChangeValueForKey:@"isExecuting"];
    }
    
    [self.lock unlock];
}

- (BOOL)isExecuting {
    [self.lock lock];
    BOOL executing = _executing;
    [self.lock unlock];
    return executing;
}

- (void)setFinished:(BOOL)finished {
    [self.lock lock];
    
    if (_finished != finished) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        [self didChangeValueForKey:@"isFinished"];
    }
    
    [self.lock unlock];
}

- (BOOL)isFinished {
    [self.lock lock];
    BOOL finished = _finished;
    [self.lock unlock];
    return finished;
}

- (void)setCancelled:(BOOL)cancelled {
    [self.lock lock];
    
    if (_cancelled != cancelled) {
        [self willChangeValueForKey:@"isCancelled"];
        _cancelled = cancelled;
        [self didChangeValueForKey:@"isCancelled"];
    }
    
    [self.lock unlock];
}

- (BOOL)isCancelled {
    [self.lock lock];
    BOOL cancelled = _cancelled;
    [self.lock unlock];
    return cancelled;
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isAsynchronous {
    return YES;
}

@end
