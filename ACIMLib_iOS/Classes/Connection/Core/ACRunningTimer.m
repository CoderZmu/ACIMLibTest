//
//  CountDownTimer.m
//  CSleepDolphin
//
//  Created by lism on 2018/12/26.
//  Copyright © 2018年 HET. All rights reserved.
//

#import "ACRunningTimer.h"
#import "NSTimer+ACSafety.h"

@interface ACRunningTimer()

@property (nonatomic,assign) NSTimeInterval originalTimeInterval;
@property (nonatomic,strong) NSDate *startTime;
@property (nonatomic,assign) BOOL isRunning;
@property (nonatomic,assign) NSTimeInterval timeInterval;
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,copy) void(^finishBlock)(void);
@end

@implementation ACRunningTimer

+ (instancetype)timerWithTimeInterval:(NSTimeInterval)timeInterval
                     finishEventBlock:(nullable void(^)(void))finishEventBlock {
    ACRunningTimer *timer = [[ACRunningTimer alloc] init];
    timer.finishBlock = finishEventBlock;
    timer.timeInterval = timeInterval;
    timer.originalTimeInterval = timeInterval;
    return timer;
}

- (void)resume {
    if (self.timeInterval <= 0) return;
    if (self.isRunning) return;
    self.isRunning = YES;
    self.startTime = [NSDate date];
    [self p_startTimer];
}


- (void)suspend {
    [self p_stopTimer];
    self.isRunning = false;

    NSTimeInterval duration = -[self.startTime timeIntervalSinceNow];
    self.timeInterval -= duration;
}

- (NSTimeInterval)consumedDuration {
    NSTimeInterval remainingTime;
    if (self.isRunning) {
        NSTimeInterval duration = -[self.startTime timeIntervalSinceNow];
        remainingTime = self.timeInterval - duration;
    } else {
        remainingTime = self.timeInterval;
    }
    return self.originalTimeInterval - remainingTime;
}

- (void)p_startTimer {
    [self p_stopTimer];
    __weak __typeof__(self) wSelf = self;
    _timer = [NSTimer ac_safetyTimerWithTimeInterval:self.timeInterval block:^(NSTimer * _Nonnull timer) {
        __strong __typeof(self) sSelf = wSelf;
        if (!sSelf) return;
        sSelf.timeInterval = 0;
        [sSelf p_stopTimer];
        
        void (^block)(void) = [sSelf.finishBlock copy];
        if (block) {
            block();
        }
    } repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)p_stopTimer {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

@end

