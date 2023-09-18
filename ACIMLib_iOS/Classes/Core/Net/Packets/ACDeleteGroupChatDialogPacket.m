//
//  ACDeleteGroupChatDialogPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACDeleteGroupChatDialogPacket.h"
#import "AcpbGroupchat.pbobjc.h"
#import "ACUrlConstants.h"

@interface ACDeleteGroupChatDialogPacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACDeleteGroupChatDialogPacket

- (instancetype)initWithDialogId:(NSString *)dialogId {
    self = [super init];
    ACPBDeleteGroupChatDialogReq *mo = [[ACPBDeleteGroupChatDialogReq alloc] init];
    mo.groupId = dialogId;
    _data = [mo data];
    return self;
}


- (int32_t)packetUrl {
    return AC_API_NAME_DeleteGroupDialog;
}

- (NSData *)packetBody {
    return self.data;
}


- (void)sendWithSuccessBlockEmptyParameter:(nullable ACSendPacketSuccessBlockEmptyParameter)successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock {
    [super sendWithSuccessBlockEmptyParameter:successBlock failure:failureBlock];
}

@end
