//
//  ACDialogsAesKeyPacket.h
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACSocketPacket.h"
#import "AcpbPrivatechat.pbobjc.h"

NS_ASSUME_NONNULL_BEGIN

// 获取dialogKey
@interface ACDialogsAesKeyPacket : ACSocketPacket

- (instancetype)initWithDialogIdArray:(NSArray<NSString* > *)dialogIdArray cert:(NSString *)cert;

- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBGetDialogKeyResp * response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock;

@end

NS_ASSUME_NONNULL_END
