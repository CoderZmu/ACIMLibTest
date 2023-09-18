//
//  ACConnectionListenerManager.m
//  ACIMLib
//
//  Created by 子木 on 2022/7/1.
//

#import "ACConnectionListenerManager.h"

@interface ACConnectionListenerManager()

@property (nonatomic,strong) NSHashTable *listenerArr;

@end

@implementation ACConnectionListenerManager


+ (ACConnectionListenerManager *)shared {
    static ACConnectionListenerManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ACConnectionListenerManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.listenerArr = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory];
    }
    return self;
}

- (void)addListener:(id<ACConnectionListenerProtocol>)listener {
    @synchronized (self) {
        [self.listenerArr addObject:listener];
    }
    
}

- (void)onConnected {
    [self enumerateListeners:^(id<ACConnectionListenerProtocol> listener, BOOL *stop) {
        if ([listener respondsToSelector:@selector(onConnected)]) {
            [listener onConnected];
        }
    }];
}

- (void)userDataDidLoad {
    [self enumerateListeners:^(id<ACConnectionListenerProtocol> listener, BOOL *stop) {
        if ([listener respondsToSelector:@selector(userDataDidLoad)]) {
            [listener userDataDidLoad];
        }
    }];
}

- (void)onClosed {
    [self enumerateListeners:^(id<ACConnectionListenerProtocol> listener, BOOL *stop) {
        if ([listener respondsToSelector:@selector(onClosed)]) {
            [listener onClosed];
        }
    }];
}

- (void)onConnectStatusChanged:(ACConnectionStatus)status {

    [self enumerateListeners:^(id<ACConnectionListenerProtocol> listener, BOOL *stop) {
        if ([listener respondsToSelector:@selector(onConnectStatusChanged:)]) {
            [listener onConnectStatusChanged:status];
        }
    }];
}

- (void)enumerateListeners:(void(^)(id<ACConnectionListenerProtocol> listener, BOOL *stop))enumeration {
    NSArray *arr;
    @synchronized (self) {
        arr = [self.listenerArr allObjects];
    }
    BOOL stop = NO;
    for (id<ACConnectionListenerProtocol> listener in arr) {
        enumeration(listener, &stop);
        if (stop) break;
    }
}
@end
