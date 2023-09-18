//
//  ACSendGroupMessagePacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACSocketPacket.h"
#import "AcpbGroupchat.pbobjc.h"

NS_ASSUME_NONNULL_BEGIN

// 发送群消息
@interface ACSendGroupMessagePacket : ACSocketPacket

- (instancetype)initWithDialogId:(NSString *)dialogId localId:(long)localId objectName:(NSString *)objectName mediaFlag:(BOOL)mediaFlag msgContent:(NSData *)msgContent atAll:(BOOL)isAtAll atListArr:(NSArray *)atListArr toUserIdStr:(NSString *)userIdStr persistedFlag:(BOOL)persistedFlag pushConfig:(NSString *)pushConfig;

- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBSendGroupChatMessageResp * response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
