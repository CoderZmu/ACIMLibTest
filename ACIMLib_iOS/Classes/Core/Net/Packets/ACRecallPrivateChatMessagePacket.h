//
//  ACRecallPrivateChatMessagePacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACSocketPacket.h"

NS_ASSUME_NONNULL_BEGIN

// 单聊消息撤回
@interface ACRecallPrivateChatMessagePacket : ACSocketPacket

- (instancetype)initWithDialogId:(NSString *)dialogId messageRemoteId:(long)messageRemoteId;
@end

NS_ASSUME_NONNULL_END
