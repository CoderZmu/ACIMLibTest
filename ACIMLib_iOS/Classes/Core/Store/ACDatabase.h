//
//  SGDatabase.h
//  Sugram
//
//  Created by gossip on 16/11/21.
//  Copyright © 2016年 gossip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACMessageMo.h"
#import "ACMissingMsgsInterval.h"

@class ACFMDatabase, ACDialogMo, ACDialogSecretKeyMo;

@interface ACDatabase : NSObject

/// 单例 - 初始化数据库
+ (ACDatabase*)DataBase;
- (void)dataBaseOperation:(void(^)(ACFMDatabase* db))operation;

- (BOOL)prepareForUid:(long)uid;

- (NSInteger)selectDialogUnreadCount:(NSString *)dialogId afterTime:(long)time;

- (NSInteger)selectDialogUnreadMentionedCount:(NSString *)dialogId afterTime:(long)time;

- (BOOL)hasUnreadMentionedMessageForDialog:(NSString *)dialogId afterTime:(long)time;

- (void)updateMessage:(ACMessageMo *)message;

- (void)updateMessageArr:(NSArray *)messageArr;
/*
 删除会话里的所有消息
 */
- (BOOL)deleteMessageWithDialogId:(NSString *)dialogId;

- (BOOL)deleteMessageWithDialogId:(NSString *)dialogId beforeTime:(long)timestamp;

- (NSArray *)selectMessageWithDialogId:(NSString *)dialogId count:(int)num;

- (NSArray *)selectMessageWithDialogId:(NSString *)dialogId count:(int)num baseMsgId:(long)msgId isForward:(BOOL)isForward messageTypes:(NSArray *)messageTypes;

- (NSArray *)selectMessageWithDialogId:(NSString *)dialogId count:(int)num baseRecordTime:(long)recordTime isForward:(BOOL)isForward messageTypes:(NSArray *)messageTypes;
- (NSArray *)selectPreviousMessageWithDialogId:(NSString *)dialogId count:(int)count baseRecordTime:(long)baseRecordTime minTime:(long)minTime;
- (NSArray *)selectNextMessageWithDialogId:(NSString *)dialogId count:(int)count baseRecordTime:(long)baseRecordTime maxTime:(long)maxTime;

- (NSArray<NSNumber *> *)selectOutMediaMessageIdsWithDialogId:(NSString *)dialogId beforeTimeSend:(long)recordTime;

- (ACMessageMo *)selectMessageWithLocalId:(long)localId dilogId:(NSString *)dialogId;
- (ACMessageMo *)selectMessageWithMsgId:(long)msgId dilogId:(NSString *)dialogId;
- (ACMessageMo *)selectMessageWithRemoteId:(long)remoteId dilogId:(NSString *)dialogId;
- (ACMessageMo *)selectLatestMessageWithDialogId:(NSString *)dialogId;
- (NSArray *)selectUnreadMentionedMessagesWithDialogId:(NSString *)dialogId afterTime:(long)time count:(int)count;
- (ACMessageMo *)selectFirstUnreadMessage:(NSString *)dialogId afterTime:(long)time;
- (long)selectLatestMessageSentTime:(NSString *)dialogId;
- (long)selectLatestReceivedMessageRecordTime:(NSString *)dialogId;
- (long)selectOldestReceivedMessageRecordTime:(NSString *)dialogId;
- (NSArray<ACMessageMo *> *)selectMessagesWithDialogId:(NSString *)dialogId
                                               keyword:(NSString *)keyword
                                                 count:(int)count
                                        baseRecordTime:(long long)recordTime;

- (NSArray<NSDictionary *> *)selectMessageBriefInfosWithDialogId:(NSString *)dialogId forMsgIdList:(NSArray<NSNumber *> *)msgIdList;

- (BOOL)isExistMessageWithDialogId:(NSString *)dialogId forSendTime:(long)sendTime;
- (BOOL)isExistMessageWithDialogId:(NSString *)dialogId forRemoteId:(long)remoteId;


- (void)deleteMessageWithMsgIds:(NSArray *)msgIds dialogId:(NSString *)dialogId;

- (void)updateReceiveMessagesAsReadStatusWithDialog:(NSString *)dialogId between:(long)startTime and:(long)endTime;
//更新消息的已读状态
- (void)updateMessageReadType:(NSDictionary *)dic dialogId:(NSString *)dialogId;

- (NSString *)selectDialogIdWithMsgId:(long)msgId;
- (NSString *)selectDialogIdWithRemoteId:(long)remoteId;
- (long)selectLatestMsgId;
- (long)selectOldestMsgId;

- (void)updateSgLastRecordTime:(NSString *)dialogId time:(long)time;
- (NSDictionary *)selectLastReceiveRecordTimeMap:(NSArray *)dialogIds;
- (long)selectSgLatestRecordTime;
- (BOOL)hasAddDefaultMissingMsgInvtervalForDialog:(NSString *)dialogId;
- (void)setAddedDefaultMissingMsgInvtervalForDialog:(NSString *)dialogId val:(BOOL)val;

// 查找指定会话中包含指定时间的消息段
- (ACMissingMsgsInterval *)selectMissingMsgsIntervalForDialog:(NSString *)dialogId recordTime:(long)time;
// 查找指定会话，小于指定时间的缺失消息段
- (ACMissingMsgsInterval *)selectFloorMissingMsgsIntervalForDialog:(NSString *)dialogId recordTime:(long)time;
// 查找指定会话，大于指定时间的缺失消息段
- (ACMissingMsgsInterval *)selectCeilMissingMsgsIntervalForDialog:(NSString *)dialogId recordTime:(long)time;
- (void)updateMissingMsgsIntervalForDialog:(NSString *)dialogId interval:(ACMissingMsgsInterval *)interval;
// 添加缺失消息段（开区间）
- (void)addMissingMsgsIntervalForDialog:(NSString *)dialogId interval:(ACMissingMsgsInterval *)interval;
/// 删除缺失消息段
/// @param dialogId 会话Id
/// @param pulledMsgInterval 已拉取到消息的闭区间
- (void)deleteMissingMsgsIntervalForDialog:(NSString *)dialogId pulledMsgInterval:(ACMissingMsgsInterval *)pulledMsgInterval;

- (void)updateDialogSecretKeyForDialog:(NSString *)dialogId secretKey:(ACDialogSecretKeyMo *)secretKey;
- (ACDialogSecretKeyMo *)selectDialogSecretKeyDialog:(NSString *)dialogId;
- (NSArray *)selectLoadedSecretKeyDialogIds;
@end
