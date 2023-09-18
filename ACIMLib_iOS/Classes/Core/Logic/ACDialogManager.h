//
//  SGDialogsManger.h
//  Sugram
//
//  Created by bu88 on 2017/7/4.
//  Copyright © 2017年 gossip. All rights reserved.
//
//  这个类是用来管理会话的

#import <Foundation/Foundation.h>
#import "ACUserMo.h"
#import "ACMessageMo.h"
#import "AcpbPrivatechat.pbobjc.h"
#import "AcpbGroupchat.pbobjc.h"
#import "ACBase.h"
#import "ACDialogMo.h"
#import "ACMissingMsgsInterval.h"
#import "ACStatusDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACDialogManager : NSObject

ACSingletonH(DialogManger);

- (NSArray *)getDialogList;

- (NSArray *)selectAllDialogIds;

- (NSArray *)selectAllTrustyDialogIds;

- (NSArray *)selectAllLoadedDialogIds;

- (void)updateDbDialog:(ACDialogMo *)dialog;

// 查询会话
- (ACDialogMo *)getDialogMoForDialogId:(NSString *)dialogId;
- (void)loadDialogMoForDialogId:(NSString *)dialogId complete:(void(^)(ACDialogMo * _Nullable dialogMo))complete;

// 查询指定消息id对应的会话
- (ACDialogMo *)selectDialogsForMsgId:(long)msgId;
- (ACDialogMo *)selectDialogsForMsgRemoteId:(long)msgRemoteId;

- (BOOL)removeDialogBy:(NSString *)dialogId;

// 设置一个会话免打扰
- (void)setDialog:(NSString *)dialogId muteFlag:(BOOL)flag complete:(void(^)(ACErrorCode code))completeBlock;

// 设置一组群聊会话免打扰等级
- (void)setGroupDialogs:(NSArray<NSString *> *)dialogIdList pushNotificationLevel:(int)level complete:(void(^)(ACErrorCode code))completeBlock;

// 设置一个会话聊天置顶
- (BOOL)setDialog:(NSString *)dialogId stickyFlag:(BOOL)flag;


// 获取指定会话的未读数
- (NSInteger)getDialogUnreadCount:(NSString *)dialogId;
- (int)getTotalUnreadCount;
- (int)getUnreadCountWithDialogType:(ACDialogType)type;
- (BOOL)hasUnreadMentioned:(NSString *)dialogId;
- (long)getDialogLastReadTime:(NSString *)dialogId;


- (void)setSuperGroupUnreadStatus:(NSString *)dialogId readOffset:(long)readOffset unreceivedUnreadCount:(int)unreceivedUnreadCount unreceiveUnReadEndTime:(long)endTime;
- (void)clearAllMessagesUnreadStatusWithDialog:(NSString *)dialogId clearRemote:(BOOL)clearRemote;
- (void)clearMessagesUnreadStatusWithDialog:(NSString *)dialogId
                                       tillTime:(long)timestamp clearRemote:(BOOL)clearRemote;
/**
 设置会话的草稿
 */
- (void)setDialog:(NSString *)dialogId draft:(nullable NSString *)draft;

- (NSString *)getDialogDraft:(NSString *)dialogId;

- (ACMessageMo *)getLatestMessageForDialog:(ACDialogMo *)dialog;

// 刷新会话的更新时间
- (void)flushDialogUpdateTimeByLatestMessageSentTime:(NSString *)dialogId;

- (void)addTmpLocalDialogIfNotExist:(NSString *)dialogId;
- (void)addRemoteDialogsInfoIfNotExist:(NSArray *)dialogIdArr;
- (void)flushDialogsKeyStatus:(NSArray *)dialogIdArr;

- (void)updateSgLastReceiveRecordTime:(NSString *)dialogId time:(long)cursor;
- (NSDictionary *)getLastReceiveRecordTimeMap:(NSArray *)dialogIds;
- (long)getLastReceiveRecordTimeForDialog:(NSString *)dialogId;
- (long)getSgLatestReceiveCursor;

// 同步会话状态
- (void)syncDialogStatus;

@end


NS_ASSUME_NONNULL_END
