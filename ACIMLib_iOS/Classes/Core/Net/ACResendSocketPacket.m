//
//  ACResendSocketPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACResendSocketPacket.h"
#import "ACRetriedPacketMo.h"

@interface ACResendSocketPacket()

@property (nonatomic, strong) ACRetriedPacketMo *packetMo;
@end

@implementation ACResendSocketPacket

- (instancetype)initWithRetriedPacketMo:(ACRetriedPacketMo *)mo {
    self = [super init];
    _packetMo = mo;
    return self;
}

- (int32_t)packetUrl {
    return self.packetMo.url;
}

- (NSData *)packetBody {
    return self.packetMo.data;
}

- (BOOL)openQoS {
    return YES;
}

- (int)packetSendTimes {
    return self.packetMo.times + 1;
}

- (NSString *)packekId {
    return self.packetMo.uuid;
}

- (void)send {
    [self sendWithSuccessBlockEmptyParameter:nil failure:nil];
}

@end
