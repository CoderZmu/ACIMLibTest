//
//  ACResendSocketPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACSocketPacket.h"

NS_ASSUME_NONNULL_BEGIN

@class ACRetriedPacketMo;

@interface ACResendSocketPacket : ACSocketPacket

- (instancetype)initWithRetriedPacketMo:(ACRetriedPacketMo *)mo;

- (void)send;
@end

NS_ASSUME_NONNULL_END
