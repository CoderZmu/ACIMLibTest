//
//  ACSendGroupMessagePacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACSendGroupMessagePacket.h"
#import "ACUrlConstants.h"
#import "ACHelper.h"

@interface ACSendGroupMessagePacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACSendGroupMessagePacket

- (instancetype)initWithDialogId:(NSString *)dialogId localId:(long)localId objectName:(NSString *)objectName mediaFlag:(BOOL)mediaFlag msgContent:(NSData *)msgContent atAll:(BOOL)isAtAll atListArr:(NSArray *)atListArr toUserIdStr:(NSString *)userIdStr persistedFlag:(BOOL)persistedFlag pushConfig:(NSString *)pushConfig; {
    self = [super init];
    ACPBSendGroupChatMessageReq *groupChatMessage = [[ACPBSendGroupChatMessageReq alloc] init];
    groupChatMessage.groupId = dialogId;
    groupChatMessage.localId = localId;
    groupChatMessage.objectName = objectName;
    groupChatMessage.mediaFlag = mediaFlag;
    groupChatMessage.atAll = isAtAll;
    groupChatMessage.atArray = [ACHelper getACGPBInt64ArrayFrom:atListArr];
    groupChatMessage.assign = userIdStr;
    groupChatMessage.msgContent = msgContent;
    groupChatMessage.save = persistedFlag;
    groupChatMessage.pushContent = pushConfig;
    _data = [groupChatMessage data];
    return self;
}

- (int32_t)packetUrl {
    return AC_API_NAME_SendGroupChatMessage;
}

- (NSData *)packetBody {
    return self.data;
}


- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBSendGroupChatMessageResp * response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock {
    [super sendWithSuccessBlockIdParameter:successBlock failure:failureBlock modelClassType:ACPBSendGroupChatMessageResp.class];
}

@end
