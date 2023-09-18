//
//  ACGetBriefDialogListPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACSocketPacket.h"
#import "AcpbPrivatechat.pbobjc.h"

NS_ASSUME_NONNULL_BEGIN

// 获取会话摘要信息
@interface ACGetBriefDialogListPacket : ACSocketPacket

- (instancetype)initWithDialogIdArray:(NSArray<NSString* > *)dialogIdArray;

- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBGetBriefDialogListResp * response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock;


@end

NS_ASSUME_NONNULL_END
