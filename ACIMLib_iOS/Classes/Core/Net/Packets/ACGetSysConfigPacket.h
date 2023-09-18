//
//  ACGetSysConfigPacket.h
//  ACIMLib
//
//  Created by 子木 on 2023/8/16.
//

#import "ACSocketPacket.h"
#import "AcpbUser.pbobjc.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACGetSysConfigPacket : ACSocketPacket

- (void)sendWithSuccessBlockIdParameter:(void(^)(ACPBGetSysConfigResp* response))successBlock failure:(ACSendPacketFailureBlock)failureBlock;
@end

NS_ASSUME_NONNULL_END
