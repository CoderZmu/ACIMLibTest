//
//  ACDialogsAesKeyPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACDialogsAesKeyPacket.h"
#import "ACUrlConstants.h"

@interface ACDialogsAesKeyPacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACDialogsAesKeyPacket

- (instancetype)initWithDialogIdArray:(NSArray<NSString* > *)dialogIdArray cert:(NSString *)cert {
    self = [super init];
    ACPBGetDialogKeyReq *mo = [[ACPBGetDialogKeyReq alloc] init];
    mo.destIdArray = [dialogIdArray mutableCopy];
    mo.clientSign = cert;
    _data = [mo data];
    return self;
}

- (int32_t)packetUrl {
    return AC_API_NAME_GetDialogKey;
}

- (NSData *)packetBody {
    return self.data;
}

- (void)sendWithSuccessBlockIdParameter:(void (^)(ACPBGetDialogKeyResp * _Nonnull))successBlock failure:(ACSendPacketFailureBlock)failureBlock {
    [super sendWithSuccessBlockIdParameter:successBlock failure:failureBlock modelClassType:ACPBGetDialogKeyResp.class];
}

@end
