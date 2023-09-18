//
//  ACAuthInfo.m
//  ACConnection
//
//  Created by 子木 on 2022/6/16.
//

#import "ACAuthInfo.h"

@implementation ACAuthInfo

- (instancetype)initWithDeviceId:(int64_t)deviceId sessionId:(int64_t)sessionId uid:(int64_t)uid {
    self = [super init];
    _deviceId = deviceId;
    _sessionId = sessionId;
    _uid = uid;
    return self;
}

@end
