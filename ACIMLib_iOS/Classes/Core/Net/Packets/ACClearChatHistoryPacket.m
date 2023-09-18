//
//  ACClearChatHistoryPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACClearChatHistoryPacket.h"
#import "AcpbPrivatechat.pbobjc.h"
#import "ACUrlConstants.h"

@interface ACClearChatHistoryPacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACClearChatHistoryPacket

- (instancetype)initWithDialogId:(NSString *)dialogId groupFlag:(BOOL)groupFlag offset:(long)offset {
    self = [super init];
    ACPBCleanHistoryMessageReq *mo = [[ACPBCleanHistoryMessageReq alloc] init];
    mo.destId = dialogId;
    mo.msgTime = offset;
    mo.type = groupFlag ? 1 : 0;
    _data = [mo data];
    return self;
}


- (int32_t)packetUrl {
    return AC_API_NAME_ClearChat;
}

- (NSData *)packetBody {
    return self.data;
}


- (void)sendWithSuccessBlockEmptyParameter:(nullable ACSendPacketSuccessBlockEmptyParameter)successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock {
    [super sendWithSuccessBlockEmptyParameter:successBlock failure:failureBlock];
}

@end
