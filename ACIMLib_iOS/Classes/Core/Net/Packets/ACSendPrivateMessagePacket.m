//
//  ACSendPrivateMessagePacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACSendPrivateMessagePacket.h"
#import "ACUrlConstants.h"

@interface ACSendPrivateMessagePacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACSendPrivateMessagePacket

- (instancetype)initWithDialogId:(NSString *)dialogId localId:(long)localId objectName:(NSString *)objectName mediaFlag:(BOOL)mediaFlag msgContent:(NSData *)msgContent persistedFlag:(BOOL)persistedFlag pushConfig:(NSString *)pushConfig; {
    self = [super init];
    ACPBSendPrivateChatMessageReq *privateChatMessage = [[ACPBSendPrivateChatMessageReq alloc] init];
    privateChatMessage.destId = dialogId;
    privateChatMessage.localId = localId;
    privateChatMessage.objectName = objectName;
    privateChatMessage.mediaFlag = mediaFlag;
    privateChatMessage.msgContent = msgContent;
    privateChatMessage.pushContent = pushConfig;
    privateChatMessage.objectName = objectName;
    privateChatMessage.save = persistedFlag;
    _data = [privateChatMessage data];
    return self;
}

- (int32_t)packetUrl {
    return AC_API_NAME_SendPrivateChatMessage;
}

- (NSData *)packetBody {
    return self.data;
}


- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBSendPrivateChatMessageResp * response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock {
    [super sendWithSuccessBlockIdParameter:successBlock failure:failureBlock modelClassType:ACPBSendPrivateChatMessageResp.class];
}

@end
