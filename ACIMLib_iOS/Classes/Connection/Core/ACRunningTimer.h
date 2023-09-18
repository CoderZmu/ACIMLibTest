//
//  CountDownTimer.h
//  CSleepDolphin
//
//  Created by lism on 2018/12/26.
//  Copyright © 2018年 HET. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACRunningTimer : NSObject

+ (instancetype)timerWithTimeInterval:(NSTimeInterval)timeInterval
                              finishEventBlock:(nullable void(^)(void))finishEventBlock;

- (void)suspend;
- (void)resume;
- (NSTimeInterval)consumedDuration;

@end

NS_ASSUME_NONNULL_END
