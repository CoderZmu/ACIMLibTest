//
//  ACGetPushConfigPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACSocketPacket.h"
#import "AcpbUser.pbobjc.h"

NS_ASSUME_NONNULL_BEGIN
// 获取推送配置
@interface ACGetPushConfigPacket : ACSocketPacket

- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBGetPushConfigResp * response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
