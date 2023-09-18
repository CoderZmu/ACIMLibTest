//
//  NSTimer+SPSafety.m
//  SPBase_Example
//
//  Created by 子木 on 2019/6/13.
//  Copyright © 2019 ZiMu-cd. All rights reserved.
//

#import "NSTimer+ACSafety.h"

@implementation NSTimer (ACSafety)

+ (void)execBlock:(NSTimer *)timer {
    if ([timer userInfo]) {
        void (^block)(NSTimer *timer) = (void (^)(NSTimer *timer))[timer userInfo];
        block(timer);
    }
}

+ (NSTimer *)ac_safetyTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats {
    return [NSTimer timerWithTimeInterval:seconds target:self selector:@selector(execBlock:) userInfo:[block copy] repeats:repeats];
}

@end
