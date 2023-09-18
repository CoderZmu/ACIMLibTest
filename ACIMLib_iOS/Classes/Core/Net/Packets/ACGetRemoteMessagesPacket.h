//
//  ACGetRemoteMessagesPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACSocketPacket.h"
#import "AcpbPrivatechat.pbobjc.h"

NS_ASSUME_NONNULL_BEGIN
// 获取远端历史消息
@interface ACGetRemoteMessagesPacket : ACSocketPacket

- (instancetype)initWithDialogId:(NSString *)dialogId isSuperGroup:(BOOL)isSuperGroup oldOffset:(long)oldOffset newOffset:(long)newOffset rows:(int)rows isFromNewToOld:(BOOL)fromNewToOld;

- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBGetHistoryMessageResp * response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
