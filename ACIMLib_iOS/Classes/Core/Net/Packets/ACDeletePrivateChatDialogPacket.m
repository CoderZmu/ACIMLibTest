//
//  ACDeletePrivateChatDialogPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACDeletePrivateChatDialogPacket.h"
#import "AcpbPrivatechat.pbobjc.h"
#import "ACUrlConstants.h"

@interface ACDeletePrivateChatDialogPacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACDeletePrivateChatDialogPacket

- (instancetype)initWithDialogId:(NSString *)dialogId {
    self = [super init];
    ACPBDeletePrivateChatDialogReq *mo = [[ACPBDeletePrivateChatDialogReq alloc] init];
    mo.destId = dialogId;
    _data = [mo data];
    return self;
}


- (int32_t)packetUrl {
    return AC_API_NAME_DeleteDialog;
}

- (NSData *)packetBody {
    return self.data;
}


@end
