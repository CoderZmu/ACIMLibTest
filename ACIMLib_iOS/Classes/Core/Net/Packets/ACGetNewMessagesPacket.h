//
//  ACGetNewMessagesPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACSocketPacket.h"
#import "AcpbPrivatechat.pbobjc.h"

NS_ASSUME_NONNULL_BEGIN

// 获取新消息
@interface ACGetNewMessagesPacket : ACSocketPacket

- (instancetype)initWithOffset:(long)offset rows:(int)rows;

- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBGetNewMessageResp * response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
