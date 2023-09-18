//
//  ACDeletePrivateChatDialogPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACSocketPacket.h"

NS_ASSUME_NONNULL_BEGIN

// 删除单聊会话
@interface ACDeletePrivateChatDialogPacket : ACSocketPacket

- (instancetype)initWithDialogId:(NSString *)dialogId;

@end

NS_ASSUME_NONNULL_END
