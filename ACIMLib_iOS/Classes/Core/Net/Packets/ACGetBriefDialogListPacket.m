//
//  ACGetBriefDialogListPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACGetBriefDialogListPacket.h"
#import "ACUrlConstants.h"

@interface ACGetBriefDialogListPacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACGetBriefDialogListPacket

- (instancetype)initWithDialogIdArray:(NSArray<NSString* > *)dialogIdArray {
    self = [super init];
    ACPBGetBriefDialogListReq *mo = [[ACPBGetBriefDialogListReq alloc] init];
    mo.destIdArray = [dialogIdArray mutableCopy];
    _data = [mo data];
    return self;
}

- (int32_t)packetUrl {
    return AC_API_NAME_GetBriefDialogList;
}

- (NSData *)packetBody {
    return self.data;
}

- (void)sendWithSuccessBlockIdParameter:(void (^)(ACPBGetBriefDialogListResp * _Nonnull))successBlock failure:(ACSendPacketFailureBlock)failureBlock {
    [super sendWithSuccessBlockIdParameter:successBlock failure:failureBlock modelClassType:ACPBGetBriefDialogListResp.class];
}

@end
