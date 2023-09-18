//
//  ACUpdateGroupChatsPushNotificationLevelConfigPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACSocketPacket.h"

NS_ASSUME_NONNULL_BEGIN

// 修改群聊免干扰等级配置

@interface ACUpdateGroupChatsPushNotificationLevelConfigPacket : ACSocketPacket

- (instancetype)initWithDialogId:(NSArray *)dialogIds pushLevel:(int)pushLevel;


@end

NS_ASSUME_NONNULL_END
