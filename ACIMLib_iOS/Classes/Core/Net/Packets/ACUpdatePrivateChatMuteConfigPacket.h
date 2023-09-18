//
//  ACUpdatePrivateChatMuteConfigPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACSocketPacket.h"

NS_ASSUME_NONNULL_BEGIN

// 修改单聊静音配置（消息免打扰）

@interface ACUpdatePrivateChatMuteConfigPacket : ACSocketPacket

- (instancetype)initWithDialogId:(NSString *)dialogId muteFlag:(BOOL)muteFlag;

@end

NS_ASSUME_NONNULL_END
