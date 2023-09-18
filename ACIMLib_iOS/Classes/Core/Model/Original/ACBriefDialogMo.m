//
//  SGBriefDialog.m
//  Sugram-debug
//
//  Created by gnutech004 on 2017/2/24.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import <objc/runtime.h>
#import "ACBriefDialogMo.h"
#import "AcpbGlobalStructure.pbobjc.h"

@implementation ACBriefDialogMo

- (NSDictionary *)properties_aps {
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i<outCount; i++) {
        objc_property_t property = properties[i];
        const char* char_f =property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:char_f];
        id propertyValue = [self valueForKey:(NSString *)propertyName];
        if (propertyValue) [props setObject:propertyValue forKey:propertyName];
    }
    free(properties);
    return props;
}

+ (instancetype)briefDialogCopyWithBriefDialog:(ACPBBriefDialog *)briefDialog {
	ACBriefDialogMo *brief = [[ACBriefDialogMo alloc] init];
	brief.dialogId = briefDialog.destId;
	brief.dialogTitle = briefDialog.dialogTitle;
	brief.smallAvatarUrl = briefDialog.smallAvatarURL;
	brief.backgroundImage = briefDialog.backgroundImage;
	brief.stickyFlag = briefDialog.stickyFlag;
	brief.muteFlag = briefDialog.muteFlag;
	brief.blockFlag = briefDialog.blockFlag;
	brief.burnAfterReadingFlag = briefDialog.burnAfterReadingFlag;
    brief.burnInterval = briefDialog.burnAfterReadingTime;
	brief.takeScreenshotFlag = briefDialog.takeScreenshotFlag;
	brief.groupFlag = briefDialog.groupFlag;
	brief.totalMemeberNumber = briefDialog.totalMemberNumber;
	brief.groupMemberSmallAvatarUrlList = [[NSMutableArray alloc] init];
	brief.groupMemberSmallAvatarUrlList = briefDialog.groupMemberSmallAvatarURLArray;
    brief.notificationLevel = briefDialog.pushNotificationLevel;
	return brief;
}

@end
