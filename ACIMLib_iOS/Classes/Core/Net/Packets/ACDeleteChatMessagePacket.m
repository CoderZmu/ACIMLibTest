//
//  ACDeleteChatMessagePacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACDeleteChatMessagePacket.h"
#import "AcpbPrivatechat.pbobjc.h"
#import "ACHelper.h"
#import "ACUrlConstants.h"

@interface ACDeleteChatMessagePacket()

@property (nonatomic, strong) NSData *data;

@end


@implementation ACDeleteChatMessagePacket

- (instancetype)initWithDialogId:(NSString *)dialogId messageRemoteIdList:(NSArray<NSNumber *> *)messageRemoteIdList {
    self = [super init];
    ACPBDeleteChatMessageReq *mo = [[ACPBDeleteChatMessageReq alloc] init];
    mo.destId = dialogId;
    mo.msgIdListArray = [ACHelper getACGPBInt64ArrayFrom:messageRemoteIdList];
    _data = [mo data];
    return self;
}

- (int32_t)packetUrl {
    return AC_API_NAME_DeleteChatMessage;
}

- (NSData *)packetBody {
    return self.data;
}


@end
