//
//  ACRecallGroupChatMessagePacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACRecallGroupChatMessagePacket.h"
#import "AcpbGroupchat.pbobjc.h"
#import "ACUrlConstants.h"

@interface ACRecallGroupChatMessagePacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACRecallGroupChatMessagePacket

- (instancetype)initWithDialogId:(NSString *)dialogId messageRemoteId:(long)messageRemoteId {
    self = [super init];
    ACPBRecallGroupChatMessageReq *revocation = [[ACPBRecallGroupChatMessageReq alloc] init];
    revocation.groupId = dialogId;
    revocation.msgId = messageRemoteId;
    _data = [revocation data];
    return self;
}


- (int32_t)packetUrl {
    return AC_API_NAME_RecallGroupMessage;
}

- (NSData *)packetBody {
    return self.data;
}

@end
