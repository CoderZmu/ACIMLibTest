//
//  ACUpdatePushConfigPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACUpdatePushConfigPacket.h"
#import "AcpbUser.pbobjc.h"
#import "ACUrlConstants.h"

@interface ACUpdatePushConfigPacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACUpdatePushConfigPacket

- (instancetype)initWithConfig:(NSString *)config {
    self = [super init];
    ACPBUpdatePushConfigReq *mo = [[ACPBUpdatePushConfigReq alloc] init];
    mo.content = config;
    _data = [mo data];
    return self;
}


- (int32_t)packetUrl {
    return AC_API_NAME_UpdatePushConfig;
}

- (NSData *)packetBody {
    return self.data;
}

@end
