//
//  ACClearSuperGroupUnreadStatusPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACClearSuperGroupUnreadStatusPacket.h"
#import "AcpbSupergroupchat.pbobjc.h"
#import "ACUrlConstants.h"

@interface ACClearSuperGroupUnreadStatusPacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACClearSuperGroupUnreadStatusPacket

- (instancetype)initWithDialogId:(NSString *)dialogId readOffset:(long)readOffset {
    self = [super init];
    ACPBClearSuperGroupUnreadStatusReq *mo = [[ACPBClearSuperGroupUnreadStatusReq alloc] init];
    mo.dialogId = dialogId;
    mo.readOffset = readOffset;
    _data = [mo data];
    return self;
}


- (int32_t)packetUrl {
    return AC_API_NAME_ClearSuperGroupUnreadStatus;
}

- (NSData *)packetBody {
    return self.data;
}


- (void)sendWithSuccessBlockEmptyParameter:(nullable ACSendPacketSuccessBlockEmptyParameter)successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock {
    [super sendWithSuccessBlockEmptyParameter:successBlock failure:failureBlock];
}

@end
