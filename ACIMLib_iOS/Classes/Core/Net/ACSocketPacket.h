//
//  ACRequest.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/21.
//

#import "ACBaseSocketPacket.h"

NS_ASSUME_NONNULL_BEGIN


typedef void (^ACSendPacketFailureBlock)(NSError *error, NSInteger errorCode);
typedef void (^ACSendPacketSuccessBlockIdParameter)(id response);
typedef void (^ACSendPacketSuccessBlockEmptyParameter)(void);

@interface ACSocketPacket : ACBaseSocketPacket
/**
 true表示本包需要进行QoS质量保证，否则不需要. 默认为false
 */
@property (nonatomic, assign) BOOL openQoS;

- (int)packetSendTimes;

- (NSString *)packekId;

- (NSInteger)getBusinessCode:(id)responseModel;

- (void)sendWithSuccessBlockEmptyParameter:(nullable ACSendPacketSuccessBlockEmptyParameter)successBlock failure: (nullable ACSendPacketFailureBlock)failureBlock;

- (void)sendWithSuccessBlockIdParameter:(nullable ACSendPacketSuccessBlockIdParameter)successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock
modelClassType: (Class)modelClassType;
@end

NS_ASSUME_NONNULL_END
