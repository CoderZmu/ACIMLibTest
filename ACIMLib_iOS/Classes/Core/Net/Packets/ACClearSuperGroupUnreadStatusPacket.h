//
//  ACClearSuperGroupUnreadStatusPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACSocketPacket.h"

NS_ASSUME_NONNULL_BEGIN
// 清空超级群消息未读状态
@interface ACClearSuperGroupUnreadStatusPacket : ACSocketPacket

- (instancetype)initWithDialogId:(NSString *)dialogId readOffset:(long)readOffset;

@end

NS_ASSUME_NONNULL_END
