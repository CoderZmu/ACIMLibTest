//
//  SGBriefDialog.h
//  Sugram-debug
//
//  Created by gnutech004 on 2017/2/24.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ACInputStream.h"

@class ACPBBriefDialog;
@interface ACBriefDialogMo : NSObject

@property (nonatomic, copy) NSString *dialogId; //目标id: 单聊时是对方uin, 群聊时是groupUin

@property (nonatomic, copy) NSString *dialogTitle; //单聊时是对方名称, 群聊时是groupTitle

@property (nonatomic, copy) NSString *smallAvatarUrl; //头像缩略图

@property (nonatomic, strong) NSMutableArray *groupMemberSmallAvatarUrlList; //群聊天头像

@property (nonatomic, copy) NSString *backgroundImage; //背景图

@property (nonatomic) BOOL stickyFlag; //是否置顶

@property (nonatomic) BOOL muteFlag; //是否免打扰

@property (nonatomic) BOOL blockFlag; //是否拉黑

@property (nonatomic) BOOL burnAfterReadingFlag; //是否阅后即焚
@property(nonatomic, assign) int64_t burnInterval;//阅后即焚的时长

@property (nonatomic) BOOL takeScreenshotFlag;

@property (nonatomic) BOOL groupFlag; //是否群聊

@property (nonatomic) int totalMemeberNumber; //总人数

@property (nonatomic) int notificationLevel; 

- (NSDictionary *)properties_aps;

+ (instancetype)briefDialogCopyWithBriefDialog:(ACPBBriefDialog *)briefDialog;

@end
