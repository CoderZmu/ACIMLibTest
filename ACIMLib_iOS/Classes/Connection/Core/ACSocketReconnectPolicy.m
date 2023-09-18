//
//  ACSocketReconnectPolicy.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/24.
//

#import <UIKit/UIKit.h>
#import "ACSocketReconnectPolicy.h"
#import "NSTimer+ACSafety.h"

@interface ACSocketReconnectPolicy()

@property (nonatomic,assign) int reconnectTimes;

@property (nonatomic, copy) void(^reconnectActionBlock)(void);

@end

@implementation ACSocketReconnectPolicy

- (instancetype)init {
    self = [super init];
    
    self.reconnectTimes = -1;
    return self;
}

- (void)reconnect:(void(^)(void))callback {
    if (self.reconnectActionBlock != nil) return;
    
    self.reconnectTimes += 1;
    self.reconnectActionBlock = callback;
    [self performReconnectAfterAWhile];
}

- (void)cancel {
    self.reconnectActionBlock = nil;
    self.reconnectTimes = -1;
}


- (void)performReconnectAfterAWhile {
    if (!self.reconnectActionBlock) return;

    // 0s, 0.25s, 0.5s, 1s, 2s, 4s, 8s, 16s, 32s, 64s, 64s, 64s…
    NSTimeInterval duration = 0;
    if (self.reconnectTimes > 0) {
        duration = 0.25 * pow(2, MIN(self.reconnectTimes - 1, 8));
    }
    
    __weak __typeof__(self) weakSelf = self;
    void (^execBlock)(void) = ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (!self.reconnectActionBlock) return;
        void(^reconnectActionBlock)(void) = [self.reconnectActionBlock copy];
        reconnectActionBlock();
        self.reconnectActionBlock = nil;
    };
    
    if (duration <= 0) {
        execBlock();
    } else {
        NSTimer *timer = [NSTimer ac_safetyTimerWithTimeInterval:duration block:^(NSTimer * _Nonnull timer) {
            execBlock();
        } repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
}


@end
