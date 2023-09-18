//
//  ACUpdateGroupChatsPushNotificationLevelConfigPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACUpdateGroupChatsPushNotificationLevelConfigPacket.h"
#import "AcpbGroupchat.pbobjc.h"
#import "ACUrlConstants.h"

@interface ACUpdateGroupChatsPushNotificationLevelConfigPacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACUpdateGroupChatsPushNotificationLevelConfigPacket

- (instancetype)initWithDialogId:(NSArray *)dialogIds pushLevel:(int)pushLevel {
    self = [super init];
    ACPBUpdateGroupChatDialogNotificationLevelReq *mo = [[ACPBUpdateGroupChatDialogNotificationLevelReq alloc] init];
    mo.destIdArray = [dialogIds mutableCopy];
    mo.muteFlag = pushLevel;
    _data = [mo data];
    return self;
}


- (int32_t)packetUrl {
    return AC_API_NAME_UpdateGroupChatNotificationLevelConfig;
}

- (NSData *)packetBody {
    return self.data;
}


@end
