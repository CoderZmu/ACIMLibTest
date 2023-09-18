//
//  ACUpdatePrivateChatStickyConfigPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACSocketPacket.h"

NS_ASSUME_NONNULL_BEGIN

// 修改单聊消息置顶

@interface ACUpdatePrivateChatStickyConfigPacket : ACSocketPacket

- (instancetype)initWithDialogId:(NSString *)dialogId stickyFlag:(BOOL)stickyFlag;

@end

NS_ASSUME_NONNULL_END
