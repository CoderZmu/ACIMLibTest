//
//  ACDatabase+Request.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACDatabase.h"
#import "ACRetriedPacketMo.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACDatabase (RetriedPacket)

- (void)addPacket:(int32_t)url data:(NSData *)data uuid:(NSString *)uuid;
- (void)increasePacketRetryTimes:(NSString *)uuid;
- (void)deletePacket:(NSString *)uuid;
- (NSMutableArray<ACRetriedPacketMo *> *)selectAllPackets;

@end

NS_ASSUME_NONNULL_END
