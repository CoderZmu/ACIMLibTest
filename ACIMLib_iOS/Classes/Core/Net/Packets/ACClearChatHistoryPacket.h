//
//  ACClearChatHistoryPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACSocketPacket.h"

NS_ASSUME_NONNULL_BEGIN
// 清空会话信息
@interface ACClearChatHistoryPacket : ACSocketPacket

- (instancetype)initWithDialogId:(NSString *)dialogId groupFlag:(BOOL)groupFlag offset:(long)offset;
@end

NS_ASSUME_NONNULL_END
