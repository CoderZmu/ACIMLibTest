//
//  SGDialogs.h
//  Sugram-debug
//
//  Created by gnutech004 on 2017/2/24.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACBriefDialogMo.h"
#import "ACUserMo.h"

@class ACMessageMo;

typedef NS_ENUM(NSUInteger, ACDialogType) {
    /*!
     单聊
     */
    ACDialogType_PRIVATE = 1,
    
    /*!
     讨论组
     */
    ACDialogType_DISCUSSION = 2,

    /*!
     群组
     */
    ACDialogType_GROUP = 3,
    /*!
     超级群
     */
    ACDialogType_ULTRAGROUP = 10,
};


@interface ACDialogMo : NSObject

////////协议部分
@property (nonatomic, copy) NSString *Property_ACDialogs_dialogId; //目标id: 单聊时是对方uin, 群聊时是groupUin

@property (nonatomic, strong) NSString *Property_ACDialogs_dialogTitle; //单聊时是对方名称, 群聊时是groupTitle

@property (nonatomic, strong) NSString *Property_ACDialogs_nickName;

@property (nonatomic, strong) NSString *Property_ACDialogs_smallAvatarUrl; //头像缩略图

@property (nonatomic, assign) BOOL Property_ACDialogs_stickyFlag; //是否置顶

@property (nonatomic, assign) BOOL Property_ACDialogs_muteFlag; //是否免打扰

@property (nonatomic, assign) BOOL Property_ACDialogs_blockFlag; //是否拉黑

@property (nonatomic, assign) int Property_ACDialogs_tmpLocalType; // 临时创建的本地会话类型 0:已同步服务端会话信息 1:接收新消息创建的临时会话（可信任的） 2:发消息创建的会话（未知的）

@property (nonatomic, assign) long Property_ACDialogs_lastReadTime; // 已读消息游标

@property (nonatomic, assign, readonly) BOOL Property_ACDialogs_groupFlag; //是否群聊

@property (nonatomic, copy) NSString *Property_ACDialogs_draftText; // 草稿

@property (nonatomic, assign) NSUInteger Property_ACDialogs_unreceiveUnReadCount; // 未接收的离线消息未读消息条数

@property (nonatomic, assign) NSUInteger Property_ACDialogs_unreceiveUnreadEndTime;

@property (nonatomic, assign) long Property_ACDialogs_updateTime; // 操作时间,默认是最后一条消息的发送时间

@property (nonatomic, assign) int Property_ACDialogs_notificationLevel; // 免打扰级别

@property (nonatomic, assign) BOOL Property_ACDialogs_isHidden; // 是否隐藏的会话，不会展示在会话列表中

@property (nonatomic, assign) BOOL Property_ACDialogs_msgInvisible; // 是否因收取的消息暂没加载到秘钥导致消息无法查看


- (id) initWithBriefDialog:(ACBriefDialogMo *)briefDialog;

- (void)reloadBy:(ACBriefDialogMo *)briefDialog;

- (NSComparisonResult)compareToDialog:(ACDialogMo *)dialog;

+ (NSString *)loadProperty_ACDialogs_stickyFlagKey;
+ (NSString *)loadProperty_ACDialogs_muteFlagKey;
+ (NSString *)loadProperty_ACDialogs_dialogIdKey;

@end
