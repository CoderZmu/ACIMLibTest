//
//  ACSocketPacketCacheAgent.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACSocketPacketCacheAgent : NSObject

+ (void)storeSendingPacket:(uint32_t)url data:(nullable NSData *)data uuid:(NSString *)uuid;
+ (void)increasePacketSendTimes:(NSString *)uuid;
+ (void)drop:(NSString *)uuid;
+ (NSArray *)getAllSendingPackets;
@end

NS_ASSUME_NONNULL_END
