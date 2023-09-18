#import "ACRequestGetMessageBuilder.h"
#import "ACAccountManager.h"
#import "ACFileManager.h"
#import "ACLetterBox.h"
#import "ACConnectionListenerProtocol.h"
#import "ACIMLibLoader.h"
#import "ACServerMessageDataParser.h"
#import "ACDialogManager.h"
#import "ACMessageFilter.h"
#import "ACMessageManager.h"
#import "ACCommandMessageProcesser.h"
#import "ACEventBus.h"
#import "ACActionType.h"
#import "ACDialogIdConverter.h"
#import "ACLogger.h"
#import "ACMessageSerializeSupport.h"
#import "ACConnectionListenerManager.h"
#import "ACGetNewMessagesPacket.h"

#define Request_count 60


@interface ACRequestGetMessageBuilder ()<ACConnectionListenerProtocol>
@property(nonatomic, assign) long  seqNo;//用以记录最新的seqNo
@property(nonatomic, assign) int64_t offSet;


@property (nonatomic, strong) NSOperationQueue *loadNewMsgQueue;
@property (nonatomic, strong) dispatch_queue_t synQueue;
@property (nonatomic, strong) dispatch_block_t delayGetNextMessageBlock;
@property (nonatomic, assign) BOOL isOfflineMsgLoaded; // 离线消息是否加载完成

@end

@implementation ACRequestGetMessageBuilder


+ (ACRequestGetMessageBuilder*)builder {
    static ACRequestGetMessageBuilder* builder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        builder = [[ACRequestGetMessageBuilder alloc] init];
        
    });
    return builder;
}


+ (void)loadNewMessageWithSeqNo:(long)seqNo {
    
    [[self builder] loadNewMessageWithSeqNo:seqNo];
}

+ (BOOL)isOfflineMessagesLoaded {
    return [[ACIMLibLoader sharedLoader] getConnectionStatus] == ConnectionStatus_Connected && [self builder].isOfflineMsgLoaded;
}

- (instancetype)init {
    self = [super init];
    _loadNewMsgQueue = [[NSOperationQueue alloc] init];
    _loadNewMsgQueue.maxConcurrentOperationCount = 1;
    _loadNewMsgQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    _synQueue = dispatch_queue_create("com.getMessageBuilder.syn", DISPATCH_QUEUE_SERIAL);
    [[ACConnectionListenerManager shared] addListener:self];
    return self;
}

#pragma mark - ACConnectionListenerProtocol

- (void)userDataDidLoad {
    dispatch_async(_synQueue, ^{
        [self loadOffSet];
    });
}

- (void)onConnected {
    dispatch_async(_synQueue, ^{
        self.isOfflineMsgLoaded = NO;
        [self getNewMessages];
    });
}

- (void)onClosed {
    dispatch_async(_synQueue, ^{
        self.seqNo = 0;
        [self.loadNewMsgQueue cancelAllOperations];
        [self cancelDelayTask];
    });
}


- (void)rerequestNewMessageAfterDelay:(NSTimeInterval)delay {
    [self cancelDelayTask];
    self.delayGetNextMessageBlock = dispatch_block_create(0, ^{
        [self getNewMessages];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), self.synQueue, self.delayGetNextMessageBlock);
}


- (void)cancelDelayTask {
    if (self.delayGetNextMessageBlock) {
        dispatch_block_cancel(self.delayGetNextMessageBlock);
        self.delayGetNextMessageBlock = nil;
    }
}

- (void)getNewMessages {
    [self loadNewMessageWithSeqNo:0];
}


- (void)loadNewMessageWithSeqNo:(long)seqNo {
    dispatch_async(_synQueue, ^{
        [self doRequestNewMessageWithSeqNo:seqNo withRows:Request_count];
    });
}




- (void)doRequestNewMessageWithSeqNo:(long)seqNo withRows:(int)rows{
    if ([[ACIMLibLoader sharedLoader] getConnectionStatus] != ConnectionStatus_Connected) return;
    if (![ACAccountManager shared].user.Property_SGUser_active) return;

    
    self.seqNo = MAX(self.seqNo, seqNo);
    if (self.loadNewMsgQueue.operationCount > 0) return;
    [self cancelDelayTask];
    
    ACLog(@"pull message -> time: %ld", [self offSet]);
    
    ACGetMessageOperation *operation = [[ACGetMessageOperation alloc] initWithReqOffSet:[self offSet] rowCount:rows isLoadOffLineMsg:!self.isOfflineMsgLoaded];
    [operation setSuccessBlock:^(int64_t offset, int64_t seqno) {
        dispatch_async(self.synQueue, ^{
            
            [self setOffSet:offset];
            [self saveOffSet:offset];
            self.seqNo = MAX(seqno, self.seqNo);
            
            BOOL isFinished = offset >= self.seqNo;
            ACLog(@"pull message success -> syncTime: %ld, finished: %@", offset, isFinished ? @"YES" : @"NO");
            
            // 通知拉取离线消息完成
            if (isFinished && !self.isOfflineMsgLoaded) {
                self.isOfflineMsgLoaded = YES;
                [[ACEventBus globalEventBus] emit:kConversationListDidSyncNoti];
            }
            
            // 继续拉取
            if (!isFinished) {
                [self rerequestNewMessageAfterDelay:0.01];
            }
        });
    } errorBlock:^(NSInteger code){
        [ACLogger error:@"pull message fail -> code: %d", code];
        dispatch_async(self.synQueue, ^{
            [self rerequestNewMessageAfterDelay:5];
        });
    }];
    
    [self.loadNewMsgQueue addOperation:operation];
    
}

- (void)saveOffSet:(long)offset {
    [ACLetterBox setMessageOffSet:offset];
}

- (void)loadOffSet {
    self.offSet = [ACLetterBox getMessageOffSet];
    if (!self.offSet) self.offSet = 1;
}

@end



@interface ACGetMessageOperation()

@property (readwrite, getter=isExecuting) BOOL executing;
@property (readwrite, getter=isFinished) BOOL finished;
@property (readwrite, getter=isCancelled) BOOL cancelled;
@property (readwrite, getter=isStarted) BOOL started;
@property (nonatomic, strong) NSRecursiveLock *lock;

@property (nonatomic, assign) long offSet;
@property (nonatomic, assign) int rowCount;
@property (nonatomic, assign) BOOL isLoadOffLineMsg;

@property (nonatomic, assign) int64_t respOffset;
@property (nonatomic, assign) int64_t respSeqno;
@property (nonatomic, copy) ACGetMessageSuccessBlock successBlock;
@property (nonatomic, copy) ACGetMessageErrorBlock errorBlock;


@end

@implementation ACGetMessageOperation

@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize cancelled = _cancelled;

- (instancetype)initWithReqOffSet:(long)offSet rowCount:(int)rowCount isLoadOffLineMsg:(BOOL)isLoadOffLineMsg {
    self = [super init];
    
    _executing = NO;
    _finished = NO;
    _cancelled = NO;
    _lock = [NSRecursiveLock new];
    
    _offSet = offSet;
    _rowCount = rowCount;
    _isLoadOffLineMsg = isLoadOffLineMsg;
    
    return self;
}

- (void)setSuccessBlock:(ACGetMessageSuccessBlock)successBlock errorBlock:(ACGetMessageErrorBlock)errorBlock {
    self.successBlock = successBlock;
    self.errorBlock = errorBlock;
}

- (void)startOperation {
    [@"AA" hash];
    if ([self isCancelled]) return;
    
    __weak typeof(self) _self = self;
    
    [[[ACGetNewMessagesPacket alloc] initWithOffset:self.offSet rows:self.rowCount] sendWithSuccessBlockIdParameter:^(ACPBGetNewMessageResp * _Nonnull response) {
        __strong typeof(_self) self = _self;
        if (!self || [self isCancelled]) return;
        
        [self logResponse: response.msg];

        self.respOffset = response.offset;
        self.respSeqno = response.seqno;
        [self parseMsgDict:response.msg];
        
    } failure:^(NSError * _Nonnull error, NSInteger errorCode) {
        __strong typeof(_self) self = _self;
        if (!self || [self isCancelled]) return;
        
        [self.lock lock];
        if (![self isCancelled]) {
            self.errorBlock(errorCode);
        }
        [self finishOperation];
        [self.lock unlock];
    }];
}


- (void)parseMsgDict:(NSDictionary<NSString*, ACPBDialogMessageList*> *)originMsgDict {
    
    __weak typeof(self) _self = self;
    [[ACServerMessageDataParser new] parse:originMsgDict callback:^(BOOL done, NSDictionary<NSString *,NSArray<ACMessageMo *> *> * _Nonnull msgMaps) {
        __strong typeof(_self) self = _self;
        if (!self || [self isCancelled]) return;
        
        NSMutableDictionary *newMessageMap = [NSMutableDictionary dictionary];
        
        [msgMaps enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull dialogId, NSArray<ACMessageMo *> * _Nonnull orignalMsgArr, BOOL * _Nonnull stop) {
     
            if (!originMsgDict.count) return;
            
            ACMessageFilter *filter = [ACMessageFilter new];
            NSArray *contentArr = [filter filter:[[ACCommandMessageProcesser new] processNewMessages:orignalMsgArr ignoreAck:NO readOffset:[[ACDialogManager sharedDialogManger] getDialogLastReadTime:dialogId]]];
       
            NSArray *newMessages = [[ACMessageManager shared] storeAndFilterMessageList:contentArr isOldMessage:NO];

            if (newMessages.count) {
                [newMessageMap setValue:newMessages forKey:dialogId];
            }
                        
        }];
        
       
        if (newMessageMap.count) {
            // 创建新会话
            NSMutableArray *newDialogs = [NSMutableArray array];
            for (NSString *dialogId in newMessageMap.allKeys) {
                if ([self isExistPersistedMessage:newMessageMap[dialogId]]) {
                    [newDialogs addObject:dialogId];
                }
            }
            [[ACDialogManager sharedDialogManger] addRemoteDialogsInfoIfNotExist:newDialogs.copy];
            for (NSString *dialogId in newDialogs) {
                [[ACDialogManager sharedDialogManger] flushDialogUpdateTimeByLatestMessageSentTime:dialogId];
            }
            
            
            
            // 广播新消息通知（需要过滤未解密的消息）
            NSMutableDictionary *receivedMessages = [NSMutableDictionary new];
            ACMessageFilter *filter = [ACMessageFilter new];
            [newMessageMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *messageList, BOOL * _Nonnull stop) {
                NSArray *filterMessageArr = [filter filterUndecodeMessage:messageList];
                if (filterMessageArr.count) {
                    if (self.isLoadOffLineMsg) {
                        // 设置离线消息标识
                        [filterMessageArr enumerateObjectsUsingBlock:^(ACMessageMo *msg, NSUInteger idx, BOOL * _Nonnull stop) {
                            msg.Property_ACMessage_isOffline = YES;
                        }];
                    }
                    [receivedMessages setValue:filterMessageArr forKey:key];
                }
            }];
            BOOL hasPackage = self.respOffset < self.respSeqno;
            [[ACEventBus globalEventBus] emit:kReceiveNewMessagesNotification withArguments:@[receivedMessages, @(hasPackage)]];
        }
        
        if (done) {
            [self.lock lock];
            if (![self isCancelled]) {
                self.successBlock(self.respOffset, self.respSeqno);
            }
            [self finishOperation];
            [self.lock unlock];
        }
        
    }];
}

- (BOOL)isExistPersistedMessage:(NSArray *)messageArr {
    for (ACMessageMo *message in messageArr) {
        if ([[ACMessageSerializeSupport shared] messageShouldPersisted:message.Property_ACMessage_objectName]) {
            return YES;
        }
    }
    return NO;
}

- (void)logResponse:(NSDictionary<NSString*, ACPBDialogMessageList*> *)msg {
    NSMutableDictionary *logContent = [NSMutableDictionary dictionary];
    [msg enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ACPBDialogMessageList * _Nonnull object, BOOL * _Nonnull stop) {
        NSMutableArray<ACPBDialogMessage*> *dialogMessageArray = object.dialogMessageArray;
        if (dialogMessageArray.count) {
            NSDictionary *info = @{@"f": @(dialogMessageArray[0].seqno),
                                   @"l":@(dialogMessageArray.lastObject.seqno),
                                   @"c": @(dialogMessageArray.count)
            };
            
            [logContent ac_setSafeObject:info forKey:key];
        }
    }];

    ACLog(@"pull message response -> %@", logContent.count ? [NSString ac_jsonStringWithJsonObject:logContent] : @"no message");
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
