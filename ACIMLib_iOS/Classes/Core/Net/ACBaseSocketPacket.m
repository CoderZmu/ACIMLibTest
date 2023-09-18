//
//  ACBaseRequest.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/21.
//

#import "ACBaseSocketPacket.h"
#import "ACSocketManager+Request.h"

@interface ACBaseSocketPacket()
@property (nonatomic, strong, readwrite) NSData *responseData;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, copy, nullable) ACSendPacketCompletionBlock successCompletionBlock;
@property (nonatomic, copy, nullable) ACSendPacketCompletionBlock failureCompletionBlock;
@end

@implementation ACBaseSocketPacket

- (int32_t)packetUrl {
    return 0;
}

- (NSData *)packetBody {
    return nil;
}

- (NSTimeInterval)timeoutInterval {
    return 30;
}

- (void)sendWithCompletionBlockWithSuccess:(ACSendPacketCompletionBlock)success failure:(ACSendPacketCompletionBlock)failure {
    [self p_setCompletionBlockWithSuccess:success failure:failure];
    [self p_send];
}

- (void)p_send {
    [[ACSocketManager shareSocketManager] sendRequest:[self packetUrl] data:[self packetBody] timeout:[self timeoutInterval] success:^(NSData *response) {
        self.responseData = response;
        if (self.successCompletionBlock) self.successCompletionBlock(self);
    } failure:^(NSError *error, NSInteger code) {
        self.error = error;
        if (self.failureCompletionBlock) self.failureCompletionBlock(self);
    }];
}

- (void)p_setCompletionBlockWithSuccess:(ACSendPacketCompletionBlock)success
                              failure:(ACSendPacketCompletionBlock)failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

@end
