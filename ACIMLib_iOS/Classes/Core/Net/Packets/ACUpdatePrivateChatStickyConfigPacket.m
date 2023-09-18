//
//  ACUpdatePrivateChatStickyConfigPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACUpdatePrivateChatStickyConfigPacket.h"
#import "AcpbPrivatechat.pbobjc.h"
#import "ACUrlConstants.h"

@interface ACUpdatePrivateChatStickyConfigPacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACUpdatePrivateChatStickyConfigPacket

- (instancetype)initWithDialogId:(NSString *)dialogId stickyFlag:(BOOL)stickyFlag {
    self = [super init];
    ACPBUpdatePrivateChatDialogStickyConfigReq *mo = [[ACPBUpdatePrivateChatDialogStickyConfigReq alloc] init];
    mo.destId = dialogId;
    mo.stickyFlag = stickyFlag;
    _data = [mo data];
    return self;
}


- (int32_t)packetUrl {
    return AC_API_NAME_UpdatePrivateChatStickyConfig;
}

- (NSData *)packetBody {
    return self.data;
}


@end
