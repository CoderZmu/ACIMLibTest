//
//  ACSuperGroupOfflineMessageService.m
//  ACIMLib
//
//  Created by 子木 on 2022/8/2.
//

#import "ACSuperGroupOfflineMessageService.h"
#import "ACDialogManager.h"
#import "ACDialogIdConverter.h"
#import "ACServerMessageDataParser.h"
#import "ACMessageFilter.h"
#import "ACCommandMessageProcesser.h"
#import "ACMessageManager.h"
#import "ACIMLibLoader.h"
#import "ACAccountManager.h"
#import "ACConnectionListenerProtocol.h"
#import "ACEventBus.h"
#import "ACActionType.h"
#import "ACDatabase.h"
#import "ACConnectionListenerManager.h"
#import "ACGetSuperGroupOfflineMessagesPacket.h"

@interface ACSuperGroupOfflineMessageService()<ACConnectionListenerProtocol>
@property (nonatomic, strong) NSOperationQueue *loadOfflineMsgQueue;
@property (nonatomic, assign) BOOL isRequestOfflineMsgDone;
@property (nonatomic, strong) dispatch_block_t delayRetryBlock;
@property (nonatomic, strong) dispatch_queue_t synQueue;
@end

@implementation ACSuperGroupOfflineMessageService


+ (ACSuperGroupOfflineMessageService *)shared {
    static ACSuperGroupOfflineMessageService *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ACSuperGroupOfflineMessageService alloc] init];
    });
    return instance;
}


- (instancetype)init {
    self = [super init];
    _loadOfflineMsgQueue = [[NSOperationQueue alloc] init];
    _loadOfflineMsgQueue.maxConcurrentOperationCount = 1;
    _isRequestOfflineMsgDone = NO;
    _synQueue = dispatch_queue_create("com.getSgOfflineMessages.syn", DISPATCH_QUEUE_SERIAL);
    [[ACConnectionListenerManager shared] addListener:self];
    return self;
}

- (BOOL)isOfflineMessagesLoaded {
    return [[ACIMLibLoader sharedLoader] getConnectionStatus] == ConnectionStatus_Connected && self.isRequestOfflineMsgDone;
}

- (void)doRequestOfflineMessages {
    if ([[ACIMLibLoader sharedLoader] getConnectionStatus] != ConnectionStatus_Connected) return;
    if (![ACAccountManager shared].user.Property_SGUser_active) return;

    
    if (self.loadOfflineMsgQueue.operationCount > 0) return;
    
    [self cancelDelayTask];
    
    ACGetSuperGroupOfflineMessageOperation *operation = [[ACGetSuperGroupOfflineMessageOperation alloc] init];
    [operation setSuccessBlock:^{
        dispatch_async(self.synQueue, ^{
            self.isRequestOfflineMsgDone = YES;
            [self cancelDelayTask];
            [[ACEventBus globalEventBus] emit:kSuperGroupConversationListDidSyncNoti];
        });
        
    } errorBlock:^{
        dispatch_async(self.synQueue, ^{
            if ([[ACIMLibLoader sharedLoader] getConnectionStatus] == ConnectionStatus_Connected && self.delayRetryBlock == nil) { // 重试
                self.delayRetryBlock = dispatch_block_create(0, ^{
                    [self doRequestOfflineMessages];
                });
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), self.synQueue, self.delayRetryBlock);
            }
        });
 
    }];
    [self.loadOfflineMsgQueue addOperation:operation];
}

- (void)cancelDelayTask {
    if (self.delayRetryBlock) {
        dispatch_block_cancel(self.delayRetryBlock);
        self.delayRetryBlock = nil;
    }
}


- (void)onConnected {
    dispatch_async(_synQueue, ^{
        self.isRequestOfflineMsgDone = NO;
        [self doRequestOfflineMessages];
    });
}

- (void)onClosed {
    dispatch_async(_synQueue, ^{
        self.isRequestOfflineMsgDone = NO;
        [self.loadOfflineMsgQueue cancelAllOperations];
        [self cancelDelayTask];
    });
}

@end


@interface ACGetSuperGroupOfflineMessageOperation()

@property (readwrite, getter=isExecuting) BOOL executing;
@property (readwrite, getter=isFinished) BOOL finished;
@property (readwrite, getter=isCancelled) BOOL cancelled;
@property (readwrite, getter=isStarted) BOOL started;
@property (nonatomic, strong) NSRecursiveLock *lock;

@property (nonatomic, strong) NSDictionary *msgOffsetsBeforeReq;
@property (nonatomic, copy) ACGetSuperGroupOfflineMessageSuccessBlock successBlock;
@property (nonatomic, copy) ACGetSuperGroupOfflineMessageErrorBlock errorBlock;


@end

@implementation ACGetSuperGroupOfflineMessageOperation

@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize cancelled = _cancelled;

- (instancetype)init {
    self = [super init];
    
    _executing = NO;
    _finished = NO;
    _cancelled = NO;
    _lock = [NSRecursiveLock new];
    
    return self;
}

- (void)setSuccessBlock:(ACGetSuperGroupOfflineMessageSuccessBlock)successBlock errorBlock:(ACGetSuperGroupOfflineMessageErrorBlock)errorBlock {
    self.successBlock = successBlock;
    self.errorBlock = errorBlock;
}


- (void)startOperation {
    if ([self isCancelled]) return;
    
    __weak typeof(self) _self = self;
    NSArray *superGroupDialogIds = [self getSuperGroupDialogIds];
    NSDictionary *messageOffsets = [[ACDialogManager sharedDialogManger] getLastReceiveRecordTimeMap:superGroupDialogIds];
    NSDictionary *readOffsets = [self getReadOffsetsForDialogIds:superGroupDialogIds];
    long maxOffset = [[ACDialogManager sharedDialogManger] getSgLatestReceiveCursor] ;
    self.msgOffsetsBeforeReq = messageOffsets;
    
    [[[ACGetSuperGroupOfflineMessagesPacket alloc] initWithOffset:maxOffset dialogMessageOffsets:messageOffsets readOffsets:readOffsets] sendWithSuccessBlockIdParameter:^(ACPBGetSuperGroupNewMessageResp * _Nonnull response) {
        __strong typeof(_self) self = _self;
        if (!self || [self isCancelled]) return;
        
        [self sortMsgs:response];
        [[ACDialogManager sharedDialogManger] addRemoteDialogsInfoIfNotExist:response.msg.allKeys];
        [self processDialogsUnreadStatus:response];
        [self parseMessage:response];
        
    } failure:^(NSError * _Nonnull error, NSInteger errorCode) {
        __strong typeof(_self) self = _self;
        if (!self || [self isCancelled]) return;
        
        [self.lock lock];
        if (![self isCancelled]) {
            ac_dispatch_sync_on_main_queue(^{
                self.errorBlock();
            });
        }
        [self finishOperation];
        [self.lock unlock];
    }];
}

- (NSArray *)getSuperGroupDialogIds {
    NSMutableArray *retVal = [NSMutableArray array];
    NSArray *dialogIdList = [[ACDialogManager sharedDialogManger] selectAllDialogIds];
    [dialogIdList enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([ACDialogIdConverter isSuperGroupType:obj]) {
            [retVal addObject:obj];
        }
    }];
    return retVal;
}

- (NSDictionary *)getReadOffsetsForDialogIds:(NSArray *)dialogIds {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSString *dialogId in dialogIds) {
        [dict setObject:@([[ACDialogManager sharedDialogManger] getDialogLastReadTime:dialogId]) forKey:dialogId];
    }
    return dict.copy;
}

// 升序排序
- (void)sortMsgs:(ACPBGetSuperGroupNewMessageResp *)response {
    [response.msg enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ACPBDialogMessageList * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj.dialogMessageArray sortUsingComparator:^NSComparisonResult(ACPBDialogMessage *obj1, ACPBDialogMessage *obj2) {
            if (obj1.seqno < obj2.seqno) return NSOrderedAscending;
            return NSOrderedDescending;
        }];
    }];
}

- (void)processDialogsUnreadStatus:(ACPBGetSuperGroupNewMessageResp *)response {
    NSArray *superGroupDialogIds = [self getSuperGroupDialogIds];
    for (NSString *dialogId in superGroupDialogIds) {
        long endTime = (long)response.msg[dialogId].dialogMessageArray.lastObject.seqno;
        int unreceivedUnreadCount;
        int64_t readOffset;
        [response.unreadCounts getInt32:&unreceivedUnreadCount forKey:dialogId];
        [response.readOffsets getInt64:&readOffset forKey:dialogId];
        if ( [[ACDialogManager sharedDialogManger] getDialogLastReadTime:dialogId] > readOffset) {
            // 忽略本地的ReadOffset大于服务器的
            continue;
        }
  
        if (endTime <= 0) {
            endTime = [self.msgOffsetsBeforeReq[dialogId] longValue];
        }

        [[ACDialogManager sharedDialogManger] setSuperGroupUnreadStatus:dialogId readOffset:(long)readOffset unreceivedUnreadCount:unreceivedUnreadCount unreceiveUnReadEndTime:endTime];
    }
}

- (void)parseMessage:(ACPBGetSuperGroupNewMessageResp *)response {
    NSDictionary<NSString*, ACPBDialogMessageList*> *originMsgDict = response.msg;
    ACGPBStringBoolDictionary *msgEnd = response.msgEnd;
    
    __weak typeof(self) _self = self;
    
    [[ACServerMessageDataParser new] parse:originMsgDict callback:^(BOOL done, NSDictionary<NSString *,NSArray<ACMessageMo *> *> * _Nonnull msgMaps) {
        __strong typeof(_self) self = _self;
        if (!self || [self isCancelled]) return;
        
        [msgMaps enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull dialogId, NSArray<ACMessageMo *> * _Nonnull orignalMsgArr, BOOL * _Nonnull stop) {
            
            if (!orignalMsgArr.count) return;
            
            ACMessageFilter *filter = [ACMessageFilter new];
            NSArray *contentArr = [filter filter:[[ACCommandMessageProcesser new] processNewMessages:orignalMsgArr ignoreAck:YES readOffset:[[ACDialogManager sharedDialogManger] getDialogLastReadTime:dialogId]]];
            
            NSArray *newMessages = [[ACMessageManager shared] storeAndFilterMessageList:contentArr isOldMessage:NO];
            if (newMessages.count) {
                [[ACEventBus globalEventBus] emit:kReceiveNewMessagesNotification withArguments:@[@{dialogId: newMessages}]];
            }
            
            BOOL isEnd;
            [msgEnd getBool:&isEnd forKey:dialogId];
            if (!isEnd) {
                // 记录未拉取完的离线消息游标区间
                long left = [[ACDialogManager sharedDialogManger] getLastReceiveRecordTimeForDialog:dialogId];
                long right = orignalMsgArr.firstObject.Property_ACMessage_msgSendTime;
                if (right > left) {
                    ACMissingMsgsInterval *interval = [[ACMissingMsgsInterval alloc] initWithLeft:left right:right];
                    [[ACDatabase DataBase] addMissingMsgsIntervalForDialog:dialogId interval:interval];
                }
            }
            
            [[ACDialogManager sharedDialogManger] updateSgLastReceiveRecordTime:dialogId time:orignalMsgArr.lastObject.Property_ACMessage_msgSendTime];
            [[ACDialogManager sharedDialogManger] flushDialogUpdateTimeByLatestMessageSentTime:dialogId];
        }];
        
        
        if (done) {
            [self.lock lock];
            if (![self isCancelled]) {
                ac_dispatch_sync_on_main_queue(^{
                    self.successBlock();
                });
            }
            [self finishOperation];
            [self.lock unlock];
        }
        
    }];
}


- (void)finishOperation {
    self.executing = NO;
    self.finished = YES;
}


- (void)cancelOperation {
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
