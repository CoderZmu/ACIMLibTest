//
//  ACAuthInfo.h
//  ACConnection
//
//  Created by 子木 on 2022/6/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACAuthInfo : NSObject

@property (nonatomic, assign, readonly) int64_t deviceId;
@property (nonatomic, assign, readonly) int64_t sessionId;
@property (nonatomic, assign, readonly) int64_t uid;

- (instancetype)initWithDeviceId:(int64_t)deviceId sessionId:(int64_t)sessionId uid:(int64_t)uid;
@end

NS_ASSUME_NONNULL_END
