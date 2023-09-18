//
//  SGDialogs.m
//  Sugram-debug
//
//  Created by gnutech004 on 2017/2/24.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import "ACDialogMo.h"
#import "ACBase.h"
#import "ACDialogIdConverter.h"

@implementation ACDialogMo

- (instancetype)init {
    self = [super init];
    self.Property_ACDialogs_lastReadTime = 0;
    return self;
}

- (instancetype)initWithBriefDialog:(ACBriefDialogMo *)briefDialog {
    self = [self init];
    if (self != nil) {
        _Property_ACDialogs_updateTime = 10000;
        [self reloadBy:briefDialog];
    }
    return self;
}


- (void)reloadBy:(ACBriefDialogMo *)briefDialog {
    _Property_ACDialogs_dialogId = briefDialog.dialogId;
    _Property_ACDialogs_dialogTitle = briefDialog.dialogTitle;
    _Property_ACDialogs_smallAvatarUrl = briefDialog.smallAvatarUrl;
    _Property_ACDialogs_stickyFlag = briefDialog.stickyFlag;
    _Property_ACDialogs_muteFlag = briefDialog.muteFlag;
    _Property_ACDialogs_blockFlag = briefDialog.blockFlag;
    _Property_ACDialogs_notificationLevel = briefDialog.notificationLevel;
    _Property_ACDialogs_tmpLocalType = 0;
}

- (NSComparisonResult)compareToDialog:(ACDialogMo *)targetDialog {
    if (_Property_ACDialogs_isHidden != targetDialog.Property_ACDialogs_isHidden) {
        if (!targetDialog.Property_ACDialogs_isHidden) return NSOrderedDescending;
        return NSOrderedAscending;
    }
    if (_Property_ACDialogs_msgInvisible != targetDialog.Property_ACDialogs_msgInvisible) {
        if (!targetDialog.Property_ACDialogs_msgInvisible) return NSOrderedDescending;
        return NSOrderedAscending;
    }
    if (_Property_ACDialogs_stickyFlag != targetDialog.Property_ACDialogs_stickyFlag) {
        if (targetDialog.Property_ACDialogs_stickyFlag) return NSOrderedDescending;
        return NSOrderedAscending;
    }
    if (_Property_ACDialogs_updateTime < targetDialog.Property_ACDialogs_updateTime) {
        return NSOrderedDescending;
    }
    return NSOrderedAscending;
}

+ (NSString *)loadProperty_ACDialogs_stickyFlagKey {
    return @"Property_ACDialogs_stickyFlag";
}

+ (NSString *)loadProperty_ACDialogs_muteFlagKey {
    return @"Property_ACDialogs_muteFlag";
}

+ (NSString *)loadProperty_ACDialogs_dialogIdKey {
    return @"Property_ACDialogs_dialogId";
}

- (BOOL)Property_ACDialogs_groupFlag {
    return [ACDialogIdConverter isGroupType:_Property_ACDialogs_dialogId];
}


@end
