//
//  ACSendMessageStore.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/21.
//

#import "ACSendMessageStore.h"
#import "ACConnectionListenerManager.h"

@interface ACSendMessageStore()<ACConnectionListenerProtocol>

@property (nonatomic, strong) NSMutableSet *sendMessageSet;
@property (nonatomic, strong) NSLock *lock;
@end

@implementation ACSendMessageStore

+ (ACSendMessageStore *)shared {
    static ACSendMessageStore *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ACSendMessageStore alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    [[ACConnectionListenerManager shared] addListener:self];
    _lock = [[NSLock alloc] init];
    _sendMessageSet = [NSMutableSet set];
    return self;
}


- (void)addMessage:(long)messageId {
    [_lock lock];
    [_sendMessageSet addObject:@(messageId)];
    [_lock unlock];
}

- (void)remove:(long)messageId {
    [_lock lock];
    [_sendMessageSet removeObject:@(messageId)];
    [_lock unlock];
}

- (BOOL)has:(long)messageId {
    BOOL result;
    [_lock lock];
    result = [_sendMessageSet containsObject:@(messageId)];
    [_lock unlock];
    return result;
}

- (void)reset {
    [_lock lock];
    [_sendMessageSet removeAllObjects];
    [_lock unlock];
}


- (void)userDataDidLoad {
    [self reset];
}

@end
