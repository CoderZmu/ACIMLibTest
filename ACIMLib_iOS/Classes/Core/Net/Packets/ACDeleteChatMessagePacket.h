//
//  ACDeleteChatMessagePacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACSocketPacket.h"

NS_ASSUME_NONNULL_BEGIN

// 删除会话消息

@interface ACDeleteChatMessagePacket : ACSocketPacket

- (instancetype)initWithDialogId:(NSString *)dialogId messageRemoteIdList:(NSArray<NSNumber *> *)messageRemoteIdList;


@end

NS_ASSUME_NONNULL_END
