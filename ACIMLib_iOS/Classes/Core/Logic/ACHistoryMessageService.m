//
//  ACHistoryMessageService.m
//  ACIMLib
//
//  Created by 子木 on 2022/8/2.
//

#import "ACHistoryMessageService.h"
#import "ACDatabase.h"
#import "ACDialogIdConverter.h"
#import "ACDialogManager.h"
#import "ACServerMessageDataParser.h"
#import "ACMessageFilter.h"
#import "ACMessageManager.h"
#import "ACCommandMessageProcesser.h"
#import "ACAccountManager.h"
#import "ACNetErrorConverter.h"
#import "ACConnectionListenerManager.h"
#import "ACMessageMo+Adapter.h"
#import "ACIMLibLoader.h"
#import "ACSuperGroupOfflineMessageService.h"
#import "ACRequestGetMessageBuilder.h"
#import "NSObject+EventBus.h"
#import "ACActionType.h"
#import "ACBase.h"
#import "ACMessageType.h"
#import "ACMessageSerializeSupport.h"
#import "ACGetRemoteMessagesPacket.h"
#import "ACServerTime.h"


@interface ACHistoryMessageService()<ACConnectionListenerProtocol>
@property (nonatomic, strong) NSOperationQueue *loadHistoryMsgQueue;
@end

@implementation ACHistoryMessageService

+ (ACHistoryMessageService *)shared {
    static ACHistoryMessageService *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ACHistoryMessageService alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    _loadHistoryMsgQueue = [[NSOperationQueue alloc] init];
    _loadHistoryMsgQueue.maxConcurrentOperationCount = 6;
    [[ACConnectionListenerManager shared] addListener:self];
    return self;
}



- (void)getMessages:(ACConversationType)conversationType
           targetId:(long)targetId
          channelId:(NSString *)channelId
             option:(ACHistoryMessageOption *)option
           complete:(void (^)(NSArray *messages, ACErrorCode code))complete {
    if (![ACAccountManager shared].user.Property_SGUser_active) return;
    
    
    
    ACGetHistoryMessageOperation *operation = [[ACGetHistoryMessageOperation alloc] init:conversationType targetId:targetId channelId:channelId option:option completeBlock:complete];
    [self.loadHistoryMsgQueue addOperation:operation];
   
    
}

- (void)userDataDidLoad {
    [self.loadHistoryMsgQueue cancelAllOperations];
}

@end




/*: ## 获取历史消息：
 0.初始化（添加DefaultMissingMsgInvterval标志）
   * 判断是否添加了DefaultMissingMsgInvterval，是则跳到1，反即下一步
   * 判断本地是否有老消息，有则添加 DefaultMissingMsgInvterval，跳到1；否即下一步
   * 监听离线消息加载完成通知，超时即返回；加载成功且不超时，再次判断本地有没有老消息，有则跳到1，无则下一步
   * 去服务端请求最新的消息，请求失败或者无消息即返回；有则添加 DefaultMissingMsgInvterval，跳到1
 1.获取缺失的区间
 2.获取baseRecordTime -> 缺失区间边界的本地消息
 3.如果消息条数不够，获取远程消息，更新缺失区间
 4.循环1
 */

static NSLock *__lock;
@interface ACGetHistoryMessageOperation()

@property (readwrite, getter=isExecuting) BOOL executing;
@property (readwrite, getter=isFinished) BOOL finished;
@property (readwrite, getter=isCancelled) BOOL cancelled;
@property (readwrite, getter=isStarted) BOOL started;
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, strong) NSString *dialogId;
@property (nonatomic, strong) ACHistoryMessageOption *option;
@property (nonatomic, copy) ACGetHistoryMessageCompleteBlock completeBlock;
@property (nonatomic, strong) NSMutableArray<ACMessageMo *> *msgBuffer; // 消息列表（降序）
@property (nonatomic, strong) NSTimer *conversationSyncTimer;
@property (nonatomic, copy) void(^conversationSyncEvent)(BOOL success);
@end

@implementation ACGetHistoryMessageOperation

@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize cancelled = _cancelled;


+ (void)initialize {
    __lock = [[NSLock alloc] init];
}

- (instancetype)init:(ACConversationType)conversationType
            targetId:(long)targetId
           channelId:(NSString *)channelId
              option:(ACHistoryMessageOption *)option
       completeBlock:(ACGetHistoryMessageCompleteBlock)completeBlock  {
    self = [super init];
    
    _executing = NO;
    _finished = NO;
    _cancelled = NO;
    _lock = [NSRecursiveLock new];
    _msgBuffer = [NSMutableArray array];
    
    _dialogId = [ACDialogIdConverter getSgDialogIdWithConversationType:conversationType targetId:targetId channelId:channelId];
    _option = option;
    _completeBlock = completeBlock;

    return self;
}

- (void)startOperation {
    if ([self isCancelled]) return;
    if (![NSString ac_isValidString:_dialogId]) {
        [self loadMessageDoneWithErrorCode:INVALID_PARAMETER];
        return;
    }
   
    if (!self.option || self.option.count <= 0) {
        [self loadMessageDoneWithErrorCode:INVALID_PARAMETER_ACHISTORYMESSAGEOPTION_COUNT];
        return;
    }
    
    if (self.option.order == ACHistoryMessageOrderDesc && self.option.recordTime < 0) {
        [self loadMessageDoneWithErrorCode:AC_SUCCESS];
        return;
    }
    
    [self prepare];
}


- (void)prepare {
    
    if ([[ACDatabase DataBase] hasAddDefaultMissingMsgInvtervalForDialog:self.dialogId]) {
        [self loadStorageMessages];
        return;
    }
    
    long oldestTime = [[ACDatabase DataBase] selectOldestReceivedMessageRecordTime:self.dialogId];
    if (oldestTime > 0) {
        [self addSgDefaultMissingMsgInterval:oldestTime];
        [self loadStorageMessages];
        return;
    }
    
    if ([[ACIMLibLoader sharedLoader] getConnectionStatus] != ConnectionStatus_Connected) {
        [self loadMessageDoneWithErrorCode:AC_CHANNEL_INVALID];
        return;
    }
    
    __weak typeof(self) _self = self;
    [self listenConversationListSyncEvent:^(BOOL success) {
        __strong typeof(_self) self = _self;
        if (!self || [self isCancelled]) return;
        
        if (!success) {
            [self loadMessageDoneWithErrorCode:ERROACODE_TIMEOUT];
            return;
        }
        
        long oldestTime = [[ACDatabase DataBase] selectOldestReceivedMessageRecordTime:self.dialogId];
        if (oldestTime > 0) {
            [self addSgDefaultMissingMsgInterval:oldestTime];
            [self loadStorageMessages];
            return;
        }
        
        [self loadRemoteLatestMessages];
    }];
    
}


- (void)addSgDefaultMissingMsgInterval:(long)endTime {
    [__lock lock];
    if ([[ACDatabase DataBase] hasAddDefaultMissingMsgInvtervalForDialog:self.dialogId]) return;
    [[ACDatabase DataBase] addMissingMsgsIntervalForDialog:self.dialogId interval:[[ACMissingMsgsInterval alloc] initWithLeft:0 right:endTime]];
    [[ACDatabase DataBase] setAddedDefaultMissingMsgInvtervalForDialog:self.dialogId val:YES];
    [__lock unlock];
}


// 监听会话同步状态
- (void)listenConversationListSyncEvent:(void(^)(BOOL success))syncEvent {
    BOOL isSuperGroup = [ACDialogIdConverter isSuperGroupType:self.dialogId];
    if (isSuperGroup) {
        if ([[ACSuperGroupOfflineMessageService shared] isOfflineMessagesLoaded]) {
            syncEvent(YES);
            return;
        }
    } else {
        if ([ACRequestGetMessageBuilder isOfflineMessagesLoaded]) {
            syncEvent(YES);
            return;
        }
    }

    
    self.conversationSyncEvent = syncEvent;
    [self ac_connectGlobalEventName:isSuperGroup ? kSuperGroupConversationListDidSyncNoti : kConversationListDidSyncNoti selector:@selector(conversationListDidSync)];
    __weak typeof(self) _self = self;
    self.conversationSyncTimer = [NSTimer ac_safetyTimerWithTimeInterval:10 block:^(NSTimer * _Nonnull timer) {
        __strong typeof(_self) self = _self;
        if (!self) return;
        
        [self onConversationListSync:NO];
        
    } repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.conversationSyncTimer forMode:NSRunLoopCommonModes];
    
}

- (void)conversationListDidSync {
    [self onConversationListSync:YES];
}

- (void)onConversationListSync:(BOOL)success {
    [self ac_removeAllGlobalEvent];
    [self invalidateTimer];
    
    void(^block)(BOOL);
    [__lock lock];
    if (self.conversationSyncEvent) {
        block = [self.conversationSyncEvent copy];
        self.conversationSyncEvent = nil;
    }
    [__lock unlock];
    
    !block ?: block(success);
}

- (void)invalidateTimer {
    if (self.conversationSyncTimer) {
        [self.conversationSyncTimer invalidate];
        self.conversationSyncTimer = nil;
    }
}



- (void)loadStorageMessages {
    
    if ([self isCancelled]) return;
    
    int needCount = [self getRestCount];
    
    ACMissingMsgsInterval *inInterval = [[ACDatabase DataBase] selectMissingMsgsIntervalForDialog:self.dialogId recordTime: [self getCurRecordTime]];
    
    if (inInterval) {
        // recordTime 在缺失区间内
        if (self.option.order == ACHistoryMessageOrderDesc) { // new => old
            [self loadRemoteMessagesWithInterval:[[ACMissingMsgsInterval alloc] initWithLeft:inInterval.left right: [self getCurRecordTime]]];
        } else { // old => new
            [self loadRemoteMessagesWithInterval:[[ACMissingMsgsInterval alloc] initWithLeft: [self getCurRecordTime] right:inInterval.right]];
        }
    } else {
        
        
        ACMissingMsgsInterval *missingInterval;
        NSArray<ACMessageMo *> *localMessages;
        if (self.option.order == ACHistoryMessageOrderDesc) {
            // new => old
            missingInterval = [[ACDatabase DataBase] selectFloorMissingMsgsIntervalForDialog:self.dialogId recordTime: [self getCurRecordTime]];
            localMessages = [[ACDatabase DataBase] selectPreviousMessageWithDialogId:self.dialogId count:needCount baseRecordTime: [self getCurRecordTime] minTime:missingInterval.right];
            
            
        } else {
            // old => new
            missingInterval = [[ACDatabase DataBase] selectCeilMissingMsgsIntervalForDialog:self.dialogId recordTime: [self getCurRecordTime]];
            localMessages = [[[[ACDatabase DataBase] selectNextMessageWithDialogId:self.dialogId count:needCount baseRecordTime: [self getCurRecordTime] maxTime:missingInterval.left] reverseObjectEnumerator] allObjects];

        }
        
        [self addMessages:localMessages];
        
        if ([self isLoadCompleted] || !missingInterval) {
            [self loadMessageDoneWithErrorCode:AC_SUCCESS];
            return;
        }

        [self loadRemoteMessagesWithInterval:missingInterval];
       
    }
    

}

- (void)loadRemoteLatestMessages {
    if ([[ACIMLibLoader sharedLoader] getConnectionStatus] != ConnectionStatus_Connected) {
        [self loadMessageDoneWithErrorCode:AC_CHANNEL_INVALID];
        return;
    }

    __weak typeof(self) wSelf = self;
    [[[ACGetRemoteMessagesPacket alloc] initWithDialogId:self.dialogId isSuperGroup:[ACDialogIdConverter isSuperGroupType:self.dialogId] oldOffset:0 newOffset:0 rows:[self getPageSize] isFromNewToOld:YES] sendWithSuccessBlockIdParameter:^(ACPBGetHistoryMessageResp * _Nonnull response) {
        [wSelf parse:response completed:^(NSArray<ACMessageMo *> *orignalMsgArr) {
            __strong typeof(wSelf) self = wSelf;
            if (!self || [self isCancelled]) return;
            
            if (orignalMsgArr.count) {
                long latestRecordTime = orignalMsgArr.lastObject.Property_ACMessage_msgSendTime;
                [self addSgDefaultMissingMsgInterval:latestRecordTime+1];
                [self filterAndSaveRemoteMessages:orignalMsgArr reqInterval:[[ACMissingMsgsInterval alloc]initWithLeft:0 right:latestRecordTime] isEnd:response.isEnd];
                [self loadStorageMessages];
            } else {
                // 没有消息
                if (response.isEnd) {
                    long fakeLatestRecordTime = 1577808000000; // 2020-1-1
                    [self addSgDefaultMissingMsgInterval:fakeLatestRecordTime];
                    [[ACDatabase DataBase] deleteMissingMsgsIntervalForDialog:self.dialogId pulledMsgInterval:[[ACMissingMsgsInterval alloc] initWithLeft:0 right:fakeLatestRecordTime]];
                }
                [self loadMessageDoneWithErrorCode:AC_SUCCESS];
            }

        }];

        } failure:^(NSError * _Nonnull error, NSInteger errorCode) {
            [self loadMessageDoneWithErrorCode:errorCode];
        }];
}



- (void)loadRemoteMessagesWithInterval:(ACMissingMsgsInterval *)interval {
    if ([[ACIMLibLoader sharedLoader] getConnectionStatus] != ConnectionStatus_Connected) {
        [self loadMessageDoneWithErrorCode:AC_CHANNEL_INVALID];
        return;
    }
    
    __weak typeof(self) wSelf = self;
    [[[ACGetRemoteMessagesPacket alloc] initWithDialogId:self.dialogId isSuperGroup:[ACDialogIdConverter isSuperGroupType:self.dialogId] oldOffset:interval.left newOffset:interval.right rows:[self getPageSize] isFromNewToOld:self.option.order == ACHistoryMessageOrderDesc] sendWithSuccessBlockIdParameter:^(ACPBGetHistoryMessageResp * _Nonnull response) {
       
        [wSelf parse:response completed:^(NSArray<ACMessageMo *> *orignalMsgArr) {
            __strong typeof(wSelf) self = wSelf;
            if (!self || [self isCancelled]) return;
            
           NSArray *messageArr = [wSelf filterAndSaveRemoteMessages:orignalMsgArr reqInterval:interval isEnd:response.isEnd];
            // 添加到消息接收列表
            NSInteger c = MIN([self getRestCount], messageArr.count);
            NSArray *tmp = messageArr;
            if (self.option.order == ACHistoryMessageOrderDesc) {
                tmp = [tmp subarrayWithRange:NSMakeRange(0, c)];
            } else {
                tmp = [tmp subarrayWithRange:NSMakeRange(messageArr.count - c, c)];
            }
            [self addMessages:tmp];
            
            if ([self isLoadCompleted]) {
                [self loadMessageDoneWithErrorCode:AC_SUCCESS];
                return;
            }
            
            if (self.option.order == ACHistoryMessageOrderDesc && interval.left <= 0 && response.isEnd) {
                // 历史消息加载完毕
                [self loadMessageDoneWithErrorCode:AC_SUCCESS];
                return;
            }
     
            [self loadStorageMessages];

        }];
        
        } failure:^(NSError * _Nonnull error, NSInteger errorCode) {
            if (!wSelf || [wSelf isCancelled]) return;
            [wSelf loadMessageDoneWithErrorCode:[ACNetErrorConverter toAcErrorCodeEnumProperty:errorCode]];
        }];
}

- (void)parse:(ACPBGetHistoryMessageResp *)response completed:(void(^)(NSArray<ACMessageMo *> *orignalMsgArr))completedBlock{
    // 升序
    [response.msg.dialogMessageArray sortUsingComparator:^NSComparisonResult(ACPBDialogMessage *obj1, ACPBDialogMessage *obj2) {
        if (obj1.seqno < obj2.seqno) return NSOrderedAscending;
        return NSOrderedDescending;
    }];
    
    __weak typeof(self) sSelf = self;
    [[ACServerMessageDataParser new] parse:@{self.dialogId: response.msg} callback:^(BOOL done, NSDictionary<NSString *,NSArray<ACMessageMo *> *> * _Nonnull msgMaps) {
        __strong typeof(sSelf) self = sSelf;
        if (!self) return;
        NSArray<ACMessageMo *> *orignalMsgArr = msgMaps[self.dialogId];
        completedBlock(orignalMsgArr);
    }];
}

- (NSArray<ACMessageMo *> *)filterAndSaveRemoteMessages:(NSArray<ACMessageMo *> *)orignalMsgArr reqInterval:(ACMissingMsgsInterval *)reqInterval isEnd:(BOOL)isEnd {
        
    NSArray *messageArray = [NSArray array];
    if (orignalMsgArr.count) {
        ACMessageFilter *filter = [ACMessageFilter new];
        NSArray *contentArr = [filter filter:[[ACCommandMessageProcesser new] processHistoryMessages:orignalMsgArr setAllRead:![ACDialogIdConverter isSuperGroupType:self.dialogId] readOffset:[[ACDialogManager sharedDialogManger] getDialogLastReadTime:self.dialogId]]];
        contentArr = [[contentArr reverseObjectEnumerator] allObjects]; // 降序

        contentArr = [[ACMessageManager shared] storeAndFilterMessageList:contentArr isOldMessage:YES];
        if ([self isExistPersistedMessage:contentArr]) {
            [[ACDialogManager sharedDialogManger] addRemoteDialogsInfoIfNotExist:@[self.dialogId]];
            [[ACDialogManager sharedDialogManger] flushDialogUpdateTimeByLatestMessageSentTime:self.dialogId];
        }

        messageArray = contentArr;
    }

    
    // 更新会话最新接收到的消息发送时间
    if (orignalMsgArr.count) {
        [[ACDialogManager sharedDialogManger] updateSgLastReceiveRecordTime:self.dialogId time:orignalMsgArr.lastObject.Property_ACMessage_msgSendTime];
    }
    
    // 更新未拉取完的离线消息游标区间
    if (isEnd) {
        [[ACDatabase DataBase] deleteMissingMsgsIntervalForDialog:self.dialogId pulledMsgInterval:reqInterval];
    } else if (orignalMsgArr.count) {
        BOOL isFromNewToOld = self.option.order == ACHistoryMessageOrderDesc;
        long left, right; // 设置区间[left,right]的消息段已拉取完成
        if (isFromNewToOld) {
            left = orignalMsgArr.firstObject.Property_ACMessage_msgSendTime;
            right = reqInterval.right;
        } else {
            left = reqInterval.left;
            right = orignalMsgArr.lastObject.Property_ACMessage_msgSendTime;
        }
        [[ACDatabase DataBase] deleteMissingMsgsIntervalForDialog:self.dialogId pulledMsgInterval:[[ACMissingMsgsInterval alloc] initWithLeft:left right:right]];
    }
    
  
    return messageArray;

}


- (BOOL)isExistPersistedMessage:(NSArray *)messageArr {
    for (ACMessageMo *message in messageArr) {
        if ([[ACMessageSerializeSupport shared] messageShouldPersisted:message.Property_ACMessage_objectName]) {
            return YES;
        }
    }
    return NO;
}



- (void)addMessages:(NSArray *)messages {
    if (self.option.order == ACHistoryMessageOrderDesc) {
        [self.msgBuffer addObjectsFromArray:messages];
    } else {
        NSMutableArray *tmp = messages.mutableCopy;
        [tmp addObjectsFromArray:self.msgBuffer];
        self.msgBuffer = tmp;
    }
}

- (BOOL)isLoadCompleted {
    return [self getRestCount] <= 0;
}

- (int)getRestCount {
    return (int)(self.option.count - self.msgBuffer.count);
}

- (int)getPageSize {
    return (int)MIN(50, MAX(self.option.count, 20));
}

- (long)getCurRecordTime {
    if (!self.msgBuffer.count) return self.option.recordTime;
    
    if (self.option.order == ACHistoryMessageOrderDesc) {
        return self.msgBuffer.lastObject.Property_ACMessage_msgSendTime;;
    }
    return self.msgBuffer.firstObject.Property_ACMessage_msgSendTime;;
}

- (NSArray<ACMessage *> *)toRcMessages:(NSArray<ACMessageMo *> *)orginalArr {
    NSMutableArray *retVal = [NSMutableArray array];
    for (ACMessageMo *mo in orginalArr) {
        [retVal addObject:[mo toRCMessage]];
    }
    return [retVal copy];
}

- (void)loadMessageDoneWithErrorCode:(ACErrorCode)errorCode {
    [self.lock lock];
    if (![self isCancelled]) {
        ac_dispatch_sync_on_main_queue(^{
            NSArray *contentArr;
            if (self.option.order == ACHistoryMessageOrderAsc) {
                contentArr = [[self.msgBuffer reverseObjectEnumerator] allObjects];
            } else {
                contentArr = self.msgBuffer;
            }
            
            self.completeBlock([self toRcMessages:contentArr], errorCode);
        });
    }
    [self finishOperation];
    [self.lock unlock];
}


- (void)finishOperation {
    self.executing = NO;
    self.finished = YES;
}


- (void)cancelOperation {
    self.completeBlock(@[], AC_CHANNEL_INVALID);
    [self invalidateTimer];
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
