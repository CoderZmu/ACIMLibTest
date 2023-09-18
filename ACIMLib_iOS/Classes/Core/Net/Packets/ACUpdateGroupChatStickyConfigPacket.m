//
//  ACUpdateGroupChatStickyConfigPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACUpdateGroupChatStickyConfigPacket.h"
#import "AcpbGroupchat.pbobjc.h"
#import "ACUrlConstants.h"

@interface ACUpdateGroupChatStickyConfigPacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACUpdateGroupChatStickyConfigPacket

- (instancetype)initWithDialogId:(NSString *)dialogId stickyFlag:(BOOL)stickyFlag {
    self = [super init];
    ACPBUpdateGroupChatDialogStickyConfigReq *mo = [[ACPBUpdateGroupChatDialogStickyConfigReq alloc] init];
    mo.groupId = dialogId;
    mo.stickyFlag = stickyFlag;
    _data = [mo data];
    return self;
}


- (int32_t)packetUrl {
    return AC_API_NAME_UpdateGroupChatStickyConfig;
}

- (NSData *)packetBody {
    return self.data;
}

@end
