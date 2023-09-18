//
//  ACUpdatePrivateChatMuteConfigPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACUpdatePrivateChatMuteConfigPacket.h"
#import "AcpbPrivatechat.pbobjc.h"
#import "ACUrlConstants.h"

@interface ACUpdatePrivateChatMuteConfigPacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACUpdatePrivateChatMuteConfigPacket

- (instancetype)initWithDialogId:(NSString *)dialogId muteFlag:(BOOL)muteFlag {
    self = [super init];
    ACPBUpdatePrivateChatDialogMuteConfigReq *mo = [[ACPBUpdatePrivateChatDialogMuteConfigReq alloc] init];
    mo.destId = dialogId;
    mo.muteFlag = muteFlag;
    _data = [mo data];
    return self;
}


- (int32_t)packetUrl {
    return AC_API_NAME_UpdatePrivateChatMuteConfig;
}

- (NSData *)packetBody {
    return self.data;
}


@end
