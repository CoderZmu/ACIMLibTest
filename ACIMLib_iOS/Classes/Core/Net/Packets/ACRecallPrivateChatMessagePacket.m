//
//  ACRecallPrivateChatMessagePacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACRecallPrivateChatMessagePacket.h"
#import "AcpbPrivatechat.pbobjc.h"
#import "ACUrlConstants.h"

@interface ACRecallPrivateChatMessagePacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACRecallPrivateChatMessagePacket

- (instancetype)initWithDialogId:(NSString *)dialogId messageRemoteId:(long)messageRemoteId {
    self = [super init];
    ACPBRecallPrivateChatMessageReq *revocation = [[ACPBRecallPrivateChatMessageReq alloc] init];
    revocation.destId = dialogId;
    revocation.msgId = messageRemoteId;
    _data = [revocation data];
    return self;
}


- (int32_t)packetUrl {
    return AC_API_NAME_RecallPrivateMessage;
}

- (NSData *)packetBody {
    return self.data;
}

@end
