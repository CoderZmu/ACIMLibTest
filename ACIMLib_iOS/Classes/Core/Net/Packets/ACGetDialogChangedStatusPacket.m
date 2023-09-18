//
//  ACGetDialogChangedStatusPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACGetDialogChangedStatusPacket.h"
#import "ACUrlConstants.h"

@interface ACGetDialogChangedStatusPacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACGetDialogChangedStatusPacket

- (instancetype)initWithOffset:(long)offset {
    self = [super init];
    ACPBGetNewSettingDialogListReq *mo = [[ACPBGetNewSettingDialogListReq alloc] init];
    mo.time = offset;
    _data = [mo data];
    return self;
}

- (int32_t)packetUrl {
    return AC_API_NAME_GetDialogChangedData;
}

- (NSData *)packetBody {
    return self.data;
}

- (void)sendWithSuccessBlockIdParameter:(void (^)(ACPBGetNewSettingDialogListResp * _Nonnull))successBlock failure:(ACSendPacketFailureBlock)failureBlock {
    [super sendWithSuccessBlockIdParameter:successBlock failure:failureBlock modelClassType:ACPBGetNewSettingDialogListResp.class];
}

@end
