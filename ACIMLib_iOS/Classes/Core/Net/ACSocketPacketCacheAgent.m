//
//  ACSocketPacketCacheAgent.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACSocketPacketCacheAgent.h"
#import "ACDatabase+RetriedPacket.h"

@implementation ACSocketPacketCacheAgent

+ (void)storeSendingPacket:(uint32_t)url data:(nullable NSData *)data uuid:(NSString *)uuid {
    [[ACDatabase DataBase] addPacket:url data:data uuid:uuid];
}

+ (void)increasePacketSendTimes:(NSString *)uuid {
    [[ACDatabase DataBase] increasePacketRetryTimes:uuid];
}

+ (void)drop:(NSString *)uuid {
    [[ACDatabase DataBase] deletePacket:uuid];
}

+ (NSArray *)getAllSendingPackets {
    return [[ACDatabase DataBase] selectAllPackets];
    
}

@end
