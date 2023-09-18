//
//  ACUpdateGroupChatMuteConfigPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACUpdateGroupChatMuteConfigPacket.h"
#import "AcpbGroupchat.pbobjc.h"
#import "ACUrlConstants.h"

@interface ACUpdateGroupChatMuteConfigPacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACUpdateGroupChatMuteConfigPacket

- (instancetype)initWithDialogId:(NSString *)dialogId muteFlag:(BOOL)muteFlag {
    self = [super init];
    ACPBUpdateGroupChatDialogMuteConfigReq *mo = [[ACPBUpdateGroupChatDialogMuteConfigReq alloc] init];
    mo.groupId = dialogId;
    mo.muteFlag = muteFlag;
    _data = [mo data];
    return self;
}


- (int32_t)packetUrl {
    return AC_API_NAME_UpdateGroupChatMuteConfig;
}

- (NSData *)packetBody {
    return self.data;
}


@end
