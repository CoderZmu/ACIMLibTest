//
//  NSObject+EventBus.h
//  ChatFramework
//
//  Created by Dylan on 18/11/2016.
//  Copyright © 2018 otchat. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACEventBus;

@interface NSObject (EventBus)

- (void)ac_connectGlobalEventName:(NSString *)eventName selector:(SEL)aSelector;
- (void)ac_removeGlobalEventName:(NSString *)eventName;
- (void)ac_removeAllGlobalEvent;

- (void)ac_connectEventName:(NSString *)eventName selector:(SEL)aSelector toEventbus:(ACEventBus *)eventBus;
- (void)ac_removeEventName:(NSString *)eventName fromEventbus:(ACEventBus *)eventBus;
- (void)ac_removeAllFromEventBus:(ACEventBus *)eventBus;

@end
