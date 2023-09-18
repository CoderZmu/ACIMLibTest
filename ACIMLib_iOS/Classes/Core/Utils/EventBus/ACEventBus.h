//
//  EventBus.h
//  IOSBehind
//
//  Created by Apple on 7/23/13.
//  Copyright (c) 2018 6rooms. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString *ACEventName;

@interface ACEventBus : NSObject

+ (instancetype)globalEventBus;

- (void)addObserver:(id)object selector:(SEL)aSelector name:(ACEventName)name;
- (void)removeObserver:(id)object;
- (void)removeObserver:(id)object name:(ACEventName)name;

- (void)emit:(ACEventName)name;
- (void)emit:(ACEventName)name withArguments:(NSArray *)argsArray;

@end
