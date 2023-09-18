//
//  ACServerTimeRequest.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/21.
//

#import "ACServerTimePacket.h"
#import "ACUrlConstants.h"

@implementation ACServerTimePacket

- (int32_t)packetUrl {
    return AC_API_NAME_GetServerTime;
}

- (void)sendWithSuccessBlockIdParameter:(void(^)(ACPBSystemCurrentTimeMillisResp* response))successBlock failure:(ACSendPacketFailureBlock)failureBlock {
    [super sendWithSuccessBlockIdParameter:successBlock failure:failureBlock modelClassType:ACPBSystemCurrentTimeMillisResp.class];
}

@end
