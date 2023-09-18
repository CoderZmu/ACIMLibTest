//
//  ACGetSuperGroupOfflineMessagesPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACSocketPacket.h"
#import "AcpbSupergroupchat.pbobjc.h"

NS_ASSUME_NONNULL_BEGIN
// 获取超级群离线消息
@interface ACGetSuperGroupOfflineMessagesPacket : ACSocketPacket

- (instancetype)initWithOffset:(long)offset dialogMessageOffsets:(NSDictionary *)dialogMessageOffsets readOffsets:(NSDictionary *)readOffsets;

- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBGetSuperGroupNewMessageResp * response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
