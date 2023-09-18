//
//  ACGetDialogChangedStatusPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACSocketPacket.h"
#import "AcpbPrivatechat.pbobjc.h"

NS_ASSUME_NONNULL_BEGIN
// 获取会话变更状态
@interface ACGetDialogChangedStatusPacket : ACSocketPacket

- (instancetype)initWithOffset:(long)offset;

- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBGetNewSettingDialogListResp * response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
