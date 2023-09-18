//
//  ACSendPrivateMessagePacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACSocketPacket.h"
#import "AcpbPrivatechat.pbobjc.h"

NS_ASSUME_NONNULL_BEGIN

// 发送单聊消息

@interface ACSendPrivateMessagePacket : ACSocketPacket

- (instancetype)initWithDialogId:(NSString *)dialogId localId:(long)localId objectName:(NSString *)objectName mediaFlag:(BOOL)mediaFlag msgContent:(NSData *)msgContent persistedFlag:(BOOL)persistedFlag  pushConfig:(NSString *)pushConfig;

- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBSendPrivateChatMessageResp * response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
