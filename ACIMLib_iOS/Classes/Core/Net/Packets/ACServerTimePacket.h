//
//  ACServerTimeRequest.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/21.
//

#import "ACSocketPacket.h"
#import "AcpbGlobalStructure.pbobjc.h"

NS_ASSUME_NONNULL_BEGIN

// 获取系统时间
@interface ACServerTimePacket : ACSocketPacket

- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBSystemCurrentTimeMillisResp* response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
