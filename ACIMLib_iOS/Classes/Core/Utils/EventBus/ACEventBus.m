//
//  EventBus.m
//  IOSBehind
//
//  Created by Apple on 7/23/13.
//  Copyright (c) 2018 6rooms. All rights reserved.
//

#import "ACEventBus.h"

NSString *const SLEventBusArgsKey = @"SLEventBusArgsKey";

@interface SLEventBusWrap : NSObject

@property (nonatomic, weak) id receiver;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, strong) ACEventName eventName;

@property (nonatomic, weak) id observer;

- (instancetype)initWithReceiver:(id)receiver
                        selector:(SEL)aSelector
                       eventName:(ACEventName)eventName;

- (void)invoke:(NSArray *)args;

@end

@implementation SLEventBusWrap

- (instancetype)initWithReceiver:(id)receiver
                        selector:(SEL)aSelector
                       eventName:(ACEventName)eventName {
    self = [super init];
    if (self) {
        self.receiver = receiver;
        self.selector = aSelector;
        self.eventName = eventName;
    }
    return self;
}

- (void)invoke:(NSArray *)args {
    if (!self.receiver) {
        return;
    }
    id strongReceiver = self.receiver;
    @try {
        NSMethodSignature *methodSignature = [self.receiver methodSignatureForSelector:self.selector];
        if (methodSignature) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
            [invocation setTarget:strongReceiver];
            [invocation setSelector:self.selector];
            for (NSUInteger i = 0; i < [args count]; ++i) {
                id arg = args[i];
                [invocation setArgument:&arg atIndex:i + 2];
            }
            [invocation invoke];
            strongReceiver = nil;
        } else {
            NSString *exception = [NSString stringWithFormat:@"event not implement selector %@", NSStringFromSelector(self.selector)];
            NSLog(@"event not implement selector %@", NSStringFromSelector(self.selector));
            [NSException raise:exception format:@"%@", exception];
        }
    }
    @catch (NSException *exception) {

    }
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        SLEventBusWrap *other = object;
        if ([self.eventName isEqualToString:other.eventName] &&
                [self.receiver isEqual:other.receiver] &&
                [NSStringFromSelector(self.selector) isEqualToString:NSStringFromSelector(other.selector)]) {
            return YES;
        }
    }
    return NO;
}

@end

@interface ACEventBus()

@property (nonatomic, strong) NSMutableSet<SLEventBusWrap *> *connections;

@property (nonatomic, strong) NSOperationQueue *notifyQueue;
@end

@implementation ACEventBus

+ (instancetype)globalEventBus {
    static ACEventBus *__singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __singleton = [[self alloc] init];
    });
    return __singleton;
}

- (instancetype)init {
    self = [super init];
    self.notifyQueue = [[NSOperationQueue alloc] init];
    self.notifyQueue.maxConcurrentOperationCount = 1;

    return self;
}

- (NSMutableSet<SLEventBusWrap *> *)connections {
    if (!_connections) {
        _connections = [NSMutableSet<SLEventBusWrap *> set];
    }
    return _connections;
}

- (void)addObserver:(id)object selector:(SEL)aSelector name:(ACEventName)name {
    SLEventBusWrap *wrap = [[SLEventBusWrap alloc] initWithReceiver:object selector:aSelector eventName:name];
    if ([self.connections containsObject:wrap]) {
        NSLog(@"warning you have added observer for Event name %@ to observer %@ selector %@", name, object, NSStringFromSelector(aSelector));
        return;
    }
    __weak SLEventBusWrap *weakWrap = wrap;
    __weak ACEventBus *weakEventBus = self;
    wrap.observer = [[NSNotificationCenter defaultCenter] addObserverForName:name
                                                          object:self
                                                           queue:self.notifyQueue
                                                      usingBlock:^(NSNotification *note) {
                                                          if (weakWrap && weakWrap.receiver) {
                                                              [weakWrap invoke:note.userInfo[SLEventBusArgsKey]];
                                                          } else {
                                                              [weakEventBus cleanUp];
                                                          }
                                                      }];
    [self.connections addObject:wrap];
}


- (void)cleanUp {
    NSSet<SLEventBusWrap *> *copied = [self.connections copy];
    for (SLEventBusWrap *wrap in copied) {
        if (!wrap.receiver) {
            [[NSNotificationCenter defaultCenter] removeObserver:wrap.observer];
            [self.connections removeObject:wrap];
        }
    }
}

- (void)removeObserver:(id)object {
    NSSet<SLEventBusWrap *> *copied = [self.connections copy];
    for (SLEventBusWrap *wrap in copied) {
        if (wrap.receiver == object) {
            [[NSNotificationCenter defaultCenter] removeObserver:wrap.observer];
            [self.connections removeObject:wrap];
            wrap.receiver = nil;
        }
    }
}

- (void)removeObserver:(id)object name:(ACEventName)name {
    NSSet<SLEventBusWrap *> *copied = [self.connections copy];
    for (SLEventBusWrap *wrap in copied) {
        if (wrap.receiver == object && [wrap.eventName isEqualToString:name]) {
            [[NSNotificationCenter defaultCenter] removeObserver:wrap.observer];
            [self.connections removeObject:wrap];
            wrap.receiver = nil;
        }
    }
}

- (void)emit:(ACEventName)name {
    [self emit:name withArguments:@[]];
}

- (void)emit:(ACEventName)name withArguments:(NSArray *)argsArray {
    NSDictionary *userInfo;
    if (argsArray) {
        userInfo = @{SLEventBusArgsKey : argsArray};
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
}

- (void)dealloc {
    NSSet<SLEventBusWrap *> *copied = [self.connections copy];
    for (SLEventBusWrap *wrap in copied) {
        [[NSNotificationCenter defaultCenter] removeObserver:wrap.observer];
    }
    [self.connections removeAllObjects];
}

@end
