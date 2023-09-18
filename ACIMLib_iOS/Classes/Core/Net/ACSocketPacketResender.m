//
//  ACRequestResender.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACSocketPacketResender.h"
#import "ACConnectionListenerManager.h"
#import "ACSocketPacketCacheAgent.h"
#import "ACRetriedPacketMo.h"
#import "ACResendSocketPacket.h"

static NSTimeInterval const SOCKET_PACKET_RESEND_INTERVAL = 0.2;

@interface ACSocketPacketResender()<ACConnectionListenerProtocol>
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) dispatch_source_t resendTimer;
@property (nonatomic, strong) NSMutableArray *resendPacketList;
@end

@implementation ACSocketPacketResender

+ (ACSocketPacketResender *)shared {
    static ACSocketPacketResender *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ACSocketPacketResender alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    [[ACConnectionListenerManager shared] addListener:self];
    _queue = dispatch_queue_create("com.socketpacket.resender", DISPATCH_QUEUE_SERIAL);
    return self;
}

- (void)onConnected {
    dispatch_async(self.queue, ^{
        self.resendPacketList = [[ACSocketPacketCacheAgent getAllSendingPackets] mutableCopy];
        if (self.resendPacketList.count)
            [self startResendTimer];
    });
}

- (void)onClosed {
    dispatch_async(self.queue, ^{
        self.resendPacketList = [@[] mutableCopy];
        [self stopResendTimer];
    });
}

- (void)startResendTimer {
    [self stopResendTimer];
    self.resendTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.queue);
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SOCKET_PACKET_RESEND_INTERVAL*NSEC_PER_SEC));
    dispatch_source_set_timer(self.resendTimer, start, SOCKET_PACKET_RESEND_INTERVAL*NSEC_PER_SEC, 0);
    
    dispatch_source_set_event_handler(self.resendTimer, ^{
        [self resendPacket];
    });
    dispatch_resume(self.resendTimer);
}

- (void)stopResendTimer {
    if (self.resendTimer) {
        dispatch_source_cancel(self.resendTimer);
        self.resendTimer = nil;
    }
}

- (void)resendPacket {
    if (self.resendPacketList.count) {
        ACRetriedPacketMo *packetMo = [self.resendPacketList firstObject];
        [self.resendPacketList removeObjectAtIndex:0];
        [[[ACResendSocketPacket alloc] initWithRetriedPacketMo:packetMo] send];
    }
    if (!self.resendPacketList.count) {
        [self stopResendTimer];
    }
}

@end
