//
//  ACGetSysConfigPacket.m
//  ACIMLib
//
//  Created by 子木 on 2023/8/16.
//

#import "ACGetSysConfigPacket.h"
#import "ACUrlConstants.h"

@implementation ACGetSysConfigPacket

- (int32_t)packetUrl {
    return AC_API_NAME_GetSysConfig;
}

- (void)sendWithSuccessBlockIdParameter:(void(^)(ACPBGetSysConfigResp* response))successBlock failure:(ACSendPacketFailureBlock)failureBlock {
    [super sendWithSuccessBlockIdParameter:successBlock failure:failureBlock modelClassType:ACPBGetSysConfigResp.class];
}


@end
