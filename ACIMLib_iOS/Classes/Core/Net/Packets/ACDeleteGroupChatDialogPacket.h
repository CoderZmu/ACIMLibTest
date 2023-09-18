//
//  ACDeleteGroupChatDialogPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACSocketPacket.h"

NS_ASSUME_NONNULL_BEGIN

// 删除群聊会话
@interface ACDeleteGroupChatDialogPacket : ACSocketPacket

- (instancetype)initWithDialogId:(NSString *)dialogId;

@end

NS_ASSUME_NONNULL_END
