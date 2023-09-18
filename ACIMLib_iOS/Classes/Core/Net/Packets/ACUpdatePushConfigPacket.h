//
//  ACUpdatePushConfigPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACSocketPacket.h"

NS_ASSUME_NONNULL_BEGIN
// 更新推送配置
@interface ACUpdatePushConfigPacket : ACSocketPacket

- (instancetype)initWithConfig:(NSString *)config;

@end

NS_ASSUME_NONNULL_END
