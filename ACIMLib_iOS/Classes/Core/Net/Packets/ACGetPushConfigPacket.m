//
//  ACGetPushConfigPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACGetPushConfigPacket.h"
#import "ACUrlConstants.h"

@interface ACGetPushConfigPacket()

@end

@implementation ACGetPushConfigPacket

- (int32_t)packetUrl {
    return AC_API_NAME_GetPushConfig;
}

- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBGetPushConfigResp * response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock {
    [super sendWithSuccessBlockIdParameter:successBlock failure:failureBlock modelClassType:ACPBGetPushConfigResp.class];
}

@end
