//
//  ACBaseSocketPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACBaseSocketPacket;

typedef void(^ACSendPacketCompletionBlock)(__kindof ACBaseSocketPacket *request);

@interface ACBaseSocketPacket : NSObject

@property (nonatomic, strong, readonly) NSData *responseData;

@property (nonatomic, strong, readonly) NSError *error;

#pragma mark - SubClass Override

- (int32_t)packetUrl;

- (NSData *)packetBody;

- (NSTimeInterval)timeoutInterval;

#pragma mark - Action

- (void)sendWithCompletionBlockWithSuccess:(nullable ACSendPacketCompletionBlock)success
                                    failure:(nullable ACSendPacketCompletionBlock)failure;
@end

NS_ASSUME_NONNULL_END
