//
//  NSObject+EventBus.m
//  ChatFramework
//
//  Created by Dylan on 18/11/2016.
//  Copyright © 2018 otchat. All rights reserved.
//

#import "NSObject+EventBus.h"
#import "ACEventBus.h"

@implementation NSObject (EventBus)

- (void)ac_connectGlobalEventName:(ACEventName)eventName selector:(SEL)aSelector {
    [self ac_connectEventName:eventName selector:aSelector toEventbus:[ACEventBus globalEventBus]];
}

- (void)ac_removeGlobalEventName:(ACEventName)eventName {
    [self ac_removeEventName:eventName fromEventbus:[ACEventBus globalEventBus]];
}

- (void)ac_removeAllGlobalEvent {
    [self ac_removeAllFromEventBus:[ACEventBus globalEventBus]];
}

- (void)ac_connectEventName:(ACEventName)eventName selector:(SEL)aSelector toEventbus:(ACEventBus *)eventBus {
    [eventBus addObserver:self selector:aSelector name:eventName];
}

- (void)ac_removeEventName:(ACEventName)eventName fromEventbus:(ACEventBus *)eventBus {
    [eventBus removeObserver:self name:eventName];
}

- (void)ac_removeAllFromEventBus:(ACEventBus *)eventBus {
    [eventBus removeObserver:self];
}

@end
