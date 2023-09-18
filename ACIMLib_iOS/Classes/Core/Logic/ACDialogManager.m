//
//  SGDialogsManger.m
//  Sugram
//
//  Created by bu88 on 2017/7/4.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import "ACDialogManager.h"
#import "ACDialogMo.h"
#import "ACMessageManager.h"
#import "ACDatabase.h"
#import "ACDatabase+Dialog.h"
#import "ACAccountManager.h"
#import "ACBase.h"
#import "ACMessageType.h"
#import "ACConnectionListenerProtocol.h"
#import "ACDialogIdConverter.h"
#import "ACFileManager.h"
#import "ACNetErrorConverter.h"
#import "ACConnectionListenerManager.h"
#import "ACLetterBox.h"
#import "ACServerTime.h"
#import "ACIMLibLoader.h"
#import "ACSecretKey.h"
#import "ACDeletePrivateChatDialogPacket.h"
#import "ACDeleteGroupChatDialogPacket.h"
#import "ACUpdatePrivateChatMuteConfigPacket.h"
#import "ACUpdateGroupChatMuteConfigPacket.h"
#import "ACUpdateGroupChatStickyConfigPacket.h"
#import "ACUpdatePrivateChatStickyConfigPacket.h"
#import "ACUpdateGroupChatsPushNotificationLevelConfigPacket.h"
#import "ACClearSuperGroupUnreadStatusPacket.h"
#import "ACGetBriefDialogListPacket.h"
#import "ACGetDialogChangedStatusPacket.h"

#define LOCK(...) dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(self->_lock);


@interface ACDialogManager ()<ACConnectionListenerProtocol>

@property (nonatomic, strong) NSMutableArray<ACDialogMo *> *sgDialogs;//会话页的会话数据
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *dialogIndexesDict; // 会话索引
@property (nonatomic, strong) dispatch_semaphore_t lock;
@property (nonatomic, assign) BOOL isPullingDialogChangedData;
@end

@implementation ACDialogManager

SGSingletonM(DialogManger)

- (instancetype)init {
    self = [super init];
    _sgDialogs = [NSMutableArray array];
    _dialogIndexesDict = [NSMutableDictionary dictionary];
    _lock = dispatch_semaphore_create(1);
    [[ACConnectionListenerManager shared] addListener:self];
    return self;
}

- (NSArray *)getDialogList {
    NSArray *retVal;
    LOCK(
         
         NSInteger lastNotHiddenDialogIndex = self.sgDialogs.count - 1;
         while (lastNotHiddenDialogIndex >= 0 && (self.sgDialogs[lastNotHiddenDialogIndex].Property_ACDialogs_isHidden || self.sgDialogs[lastNotHiddenDialogIndex].Property_ACDialogs_msgInvisible)) {
             lastNotHiddenDialogIndex--;
         }
         if (lastNotHiddenDialogIndex >= 0) {
             retVal = [self.sgDialogs subarrayWithRange:NSMakeRange(0, lastNotHiddenDialogIndex+1)];
         } else {
             retVal = @[];
         }
         );
    return retVal;
}



- (NSArray *)selectAllDialogIds {
    NSArray *dialogs = [self.sgDialogs copy];
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (ACDialogMo *dialog in dialogs) {
        NSString *cid = dialog.Property_ACDialogs_dialogId;
        [arr addObject:cid];
    }
    return arr;
}

- (NSArray *)selectAllTrustyDialogIds {
    NSArray *dialogs = [self.sgDialogs copy];
    NSMutableArray *retArray = [NSMutableArray array];
    for (ACDialogMo *mo in dialogs) {
        if (mo.Property_ACDialogs_tmpLocalType <= 1) {
            [retArray addObject:mo.Property_ACDialogs_dialogId];
        }
    }
    return retArray;
}


- (NSArray *)selectAllLoadedDialogIds {
    LOCK(
         NSMutableArray *retArray = [NSMutableArray array];
         for (ACDialogMo *mo in self.sgDialogs) {
             if (!mo.Property_ACDialogs_tmpLocalType) {
                 [retArray addObject:mo.Property_ACDialogs_dialogId];
             }
         }
         );
    return [retArray copy];
}

- (NSInteger)getDialogUnreadCount:(NSString *)dialogId {
    ACDialogMo *dialog = [self getDialogMoForDialogId:dialogId];
    if (!dialog) return 0;
    if (dialog.Property_ACDialogs_lastReadTime >= dialog.Property_ACDialogs_updateTime) return 0;
    
    return [[ACDatabase DataBase] selectDialogUnreadCount:dialogId afterTime:MAX(dialog.Property_ACDialogs_lastReadTime, dialog.Property_ACDialogs_unreceiveUnreadEndTime)] + dialog.Property_ACDialogs_unreceiveUnReadCount;
}


- (int)getTotalUnreadCount {
    NSArray *dialogList = [self getDialogList];
    int unreadCount = 0;
    for (ACDialogMo *dialog in dialogList) {
        if (!dialog.Property_ACDialogs_muteFlag && !dialog.Property_ACDialogs_blockFlag) {
            unreadCount += [self getDialogUnreadCount:dialog.Property_ACDialogs_dialogId];
        }
    }
    
    return unreadCount;
}

- (int)getUnreadCountWithDialogType:(ACDialogType)type {
    NSArray *dialogList = [self getDialogList];
    int unreadCount = 0;
    for (ACDialogMo *dialog in dialogList) {
        if (type == (ACDialogType)[ACDialogIdConverter getRCConversationInfoWithDialogId:dialog.Property_ACDialogs_dialogId].type && !dialog.Property_ACDialogs_muteFlag && !dialog.Property_ACDialogs_blockFlag) {
            unreadCount += [self getDialogUnreadCount:dialog.Property_ACDialogs_dialogId];
        }
        
    }
    
    return unreadCount;
}



- (BOOL)hasUnreadMentioned:(NSString *)dialogId {
    ACDialogMo *dialog = [self getDialogMoForDialogId:dialogId];
    if (!dialog) return NO;
    return [[ACDatabase DataBase] hasUnreadMentionedMessageForDialog:dialogId afterTime:MAX(dialog.Property_ACDialogs_lastReadTime, dialog.Property_ACDialogs_unreceiveUnreadEndTime)];
    
}


- (BOOL)removeDialogBy:(NSString *)dialogId {
    ACDialogMo *dialog = [self getDialogMoForDialogId:dialogId];
    if (dialog) {
        LOCK(
             NSNumber *indexNum = self.dialogIndexesDict[dialogId];
             if (indexNum) [self.sgDialogs removeObjectAtIndex:indexNum.integerValue];
             );
        [self updateDialogIndexes];
        
        ACSocketPacket *packet;
        if (dialog.Property_ACDialogs_groupFlag) {
            packet = [[ACDeleteGroupChatDialogPacket alloc] initWithDialogId:dialog.Property_ACDialogs_dialogId];
        } else {
            packet = [[ACDeletePrivateChatDialogPacket alloc] initWithDialogId:dialog.Property_ACDialogs_dialogId];
        }
        [packet sendWithSuccessBlockEmptyParameter:nil failure:nil];
        
        [[ACDatabase DataBase] deleteDialog:dialogId];
    }
    return YES;
}


/**
 查询会话
 */
-(ACDialogMo *)getDialogMoForDialogId:(NSString *)dialogId {
    if (![NSString ac_isValidString:dialogId]) return nil;
    
    __block ACDialogMo *retVal;
    LOCK(
         NSNumber *indexNum = self.dialogIndexesDict[dialogId];
         if (indexNum) retVal = self.sgDialogs[indexNum.intValue];
         );
    return retVal;
}

// 加载会话
- (void)loadDialogMoForDialogId:(NSString *)dialogId complete:(void(^)(ACDialogMo * _Nullable dialogMo))complete {
    if (![NSString ac_isValidString:dialogId]) {
        complete(nil);
        return;
    } ;
    ACDialogMo *localDialog = [self getDialogMoForDialogId:dialogId];
    if (localDialog && localDialog.Property_ACDialogs_tmpLocalType == 0) {
        complete(localDialog);
        return;
    }
    
    [self createHiddenDialog:dialogId];
    [self requestDialogsInfo:@[dialogId] complete:^{
        ac_dispatch_async_on_main_queue(^{
            complete([self getDialogMoForDialogId:dialogId]);
        });
    }];
   
}

- (ACDialogMo *)selectDialogsForMsgId:(long)msgId {
    NSString *dialogId = [[ACDatabase DataBase] selectDialogIdWithMsgId:msgId];
    if (!dialogId.length) return nil;
    return [self getDialogMoForDialogId:dialogId];
}

- (ACDialogMo *)selectDialogsForMsgRemoteId:(long)msgRemoteId {
    NSString *dialogId = [[ACDatabase DataBase] selectDialogIdWithRemoteId:msgRemoteId];
    if (!dialogId.length) return nil;
    return [self getDialogMoForDialogId:dialogId];
}

// 设置一个会话免打扰
- (void)setDialog:(NSString *)dialogId muteFlag:(BOOL)flag complete:(void(^)(ACErrorCode code))completeBlock  {
    
    ACSocketPacket *packet;
    if ([ACDialogIdConverter isGroupType:dialogId]) {
        packet = [[ACUpdateGroupChatMuteConfigPacket alloc] initWithDialogId:dialogId muteFlag:flag];
    } else {
        packet = [[ACUpdatePrivateChatMuteConfigPacket alloc] initWithDialogId:dialogId muteFlag:flag];
    }
    [packet sendWithSuccessBlockEmptyParameter:^{
        ACDialogMo *dialogs = [self getDialogMoForDialogId:dialogId];
        dialogs.Property_ACDialogs_muteFlag = flag;
        [self updateDbDialog:dialogs];
        completeBlock(AC_SUCCESS);
    } failure:^(NSError * _Nonnull error, NSInteger errorCode) {
        completeBlock([ACNetErrorConverter toAcErrorCodeEnumProperty:errorCode]);
    }];
    
}

- (void)setGroupDialogs:(NSArray<NSString *> *)dialogIdList pushNotificationLevel:(int)level complete:(void(^)(ACErrorCode code))completeBlock {
    [[[ACUpdateGroupChatsPushNotificationLevelConfigPacket alloc] initWithDialogId:dialogIdList pushLevel:level] sendWithSuccessBlockEmptyParameter:^{
        // 设置成功, 更新本地会话状态
        [dialogIdList enumerateObjectsUsingBlock:^(NSString * _Nonnull dialogId, NSUInteger idx, BOOL * _Nonnull stop) {
            ACDialogMo* dialog = [self getDialogMoForDialogId:dialogId];
            if (dialog) {
                dialog.Property_ACDialogs_notificationLevel = level;
                [self updateDbDialog:dialog];
            }
        }];
        completeBlock(AC_SUCCESS);
    } failure:^(NSError * _Nonnull error, NSInteger errorCode) {
        completeBlock([ACNetErrorConverter toAcErrorCodeEnumProperty:errorCode]);
    }];
}

// 设置一个会话聊天置顶
- (BOOL)setDialog:(NSString *)dialogId stickyFlag:(BOOL)flag {
    ACDialogMo* dialog = [self getDialogMoForDialogId:dialogId];
    if (!dialog) {
        return NO;
    }
    
    if (dialog.Property_ACDialogs_stickyFlag == flag) {
        return YES;
    };
    
    dialog.Property_ACDialogs_stickyFlag = flag;
    [self updateDbDialog:dialog];
    [self sortDialogListByInsertionType];
    
    ACSocketPacket *packet;
    if (dialog.Property_ACDialogs_groupFlag) {
        packet = [[ACUpdateGroupChatStickyConfigPacket alloc] initWithDialogId:dialogId stickyFlag:flag];
    } else {
        packet = [[ACUpdatePrivateChatStickyConfigPacket alloc] initWithDialogId:dialogId stickyFlag:flag];
    }
    [packet sendWithSuccessBlockEmptyParameter:^{
        NSLog(@"success");
    } failure:^(NSError * _Nonnull error, NSInteger errorCode) {
        NSLog(@"fail");
    }];
    return YES;
}


- (long)getDialogLastReadTime:(NSString *)dialogId {
    ACDialogMo *dialog = [self getDialogMoForDialogId:dialogId];
    if (!dialog)  return 0;
    
    return dialog.Property_ACDialogs_lastReadTime;
}

- (void)setSuperGroupUnreadStatus:(NSString *)dialogId readOffset:(long)readOffset unreceivedUnreadCount:(int)unreceivedUnreadCount unreceiveUnReadEndTime:(long)endTime {
    ACDialogMo *dialog = [self getDialogMoForDialogId:dialogId];
    if (!dialog) return;
    
    [[ACDatabase DataBase] updateReceiveMessagesAsReadStatusWithDialog:dialogId between:dialog.Property_ACDialogs_lastReadTime and:readOffset];
    
    dialog.Property_ACDialogs_unreceiveUnreadEndTime = endTime;
    dialog.Property_ACDialogs_unreceiveUnReadCount = unreceivedUnreadCount;
    dialog.Property_ACDialogs_lastReadTime = readOffset;
    [self updateDbDialog:dialog];
}

- (void)clearAllMessagesUnreadStatusWithDialog:(NSString *)dialogId clearRemote:(BOOL)clearRemote {
    if ([self getDialogUnreadCount:dialogId] <= 0) return;
    ACDialogMo *dialog = [self getDialogMoForDialogId:dialogId];
    
    long latestReceivedMsgSendTime = [[ACDatabase DataBase] selectLatestReceivedMessageRecordTime:dialogId];
    long oldReadTime = dialog.Property_ACDialogs_lastReadTime;
    
    if (latestReceivedMsgSendTime <= oldReadTime) return;
    
    dialog.Property_ACDialogs_unreceiveUnReadCount = 0;
    dialog.Property_ACDialogs_unreceiveUnreadEndTime = 0;
    dialog.Property_ACDialogs_lastReadTime = latestReceivedMsgSendTime;
    [self updateDbDialog:dialog];
    
    [[ACDatabase DataBase] updateReceiveMessagesAsReadStatusWithDialog:dialogId between:oldReadTime and:latestReceivedMsgSendTime];
    
    if ([ACDialogIdConverter isSuperGroupType:dialogId] && clearRemote) {
        [[[ACClearSuperGroupUnreadStatusPacket alloc] initWithDialogId:dialogId readOffset:latestReceivedMsgSendTime] sendWithSuccessBlockEmptyParameter:nil failure:nil];
    }
}

- (void)clearMessagesUnreadStatusWithDialog:(NSString *)dialogId
                                   tillTime:(long)timestamp clearRemote:(BOOL)clearRemote {
    if (timestamp <= 0) return;
    ACDialogMo *dialog = [self getDialogMoForDialogId:dialogId];
    if (!dialog)  return;
    
    long latestReceivedMsgSendTime = [[ACDatabase DataBase] selectLatestReceivedMessageRecordTime:dialogId];
    if (latestReceivedMsgSendTime <= 0) return;
    
    timestamp = MIN(timestamp, latestReceivedMsgSendTime);
    long oldReadTime = dialog.Property_ACDialogs_lastReadTime;
    if (oldReadTime >= timestamp) return;
    
    if (timestamp >= dialog.Property_ACDialogs_unreceiveUnreadEndTime) {
        dialog.Property_ACDialogs_unreceiveUnReadCount = 0;
    }
    dialog.Property_ACDialogs_lastReadTime = timestamp;
    [self updateDbDialog:dialog];
    [[ACDatabase DataBase] updateReceiveMessagesAsReadStatusWithDialog:dialogId between:oldReadTime and:timestamp];
    
    if (clearRemote && [ACDialogIdConverter isSuperGroupType:dialogId]) {
        [[[ACClearSuperGroupUnreadStatusPacket alloc] initWithDialogId:dialogId readOffset:timestamp] sendWithSuccessBlockEmptyParameter:nil failure:nil];
    }
    
}


/**
 设置会话的草稿
 */
- (void)setDialog:(NSString *)dialogId draft:(NSString *)draft {
    [self addTmpLocalDialogIfNotExist:dialogId];
    ACDialogMo* dialog = [self getDialogMoForDialogId:dialogId];
    dialog.Property_ACDialogs_draftText = draft;
    if (draft.length) {
        [self setDialogUpdateTime:dialog time:[ACServerTime getServerMSTime]];
    }
    [self updateDbDialog:dialog];
}

- (NSString *)getDialogDraft:(NSString *)dialogId {
    ACDialogMo *dialog = [self getDialogMoForDialogId:dialogId];
    if (!dialog) return 0;
    return dialog.Property_ACDialogs_draftText;
}


- (ACMessageMo *)getLatestMessageForDialog:(ACDialogMo *)dialog {
    if (!dialog) return nil;
    
    ACMessageMo *message = [[ACDatabase DataBase] selectLatestMessageWithDialogId:dialog.Property_ACDialogs_dialogId];;
    if (message && message.Property_ACMessage_msgSendTime > 0) {
        // 更新会话操作时间
        [self setDialogUpdateTime:dialog time:message.Property_ACMessage_msgSendTime];
    }
    return message;
}


- (void)flushDialogUpdateTimeByLatestMessageSentTime:(NSString *)dialogId {
    ACDialogMo *dialog = [self getDialogMoForDialogId:dialogId];
    if (!dialog) return;
    
    long time = [[ACDatabase DataBase] selectLatestMessageSentTime:dialogId];
    if (time > 0) {
        [self setDialogUpdateTime:dialog time:time];
    }
    
}

// 更新会话更新时间
- (void)setDialogUpdateTime:(ACDialogMo *)dialog time:(long)time {

    if (dialog.Property_ACDialogs_updateTime == time) return;
    dialog.Property_ACDialogs_updateTime = time;
    [self updateDbDialog:dialog];
    [self sortDialogListByInsertionType];
}


- (void)addTmpLocalDialogIfNotExist:(NSString *)dialogId {
    [self createDialogIfNotExist:dialogId isTrusty:NO invisible:NO];
    ACDialogMo *dialog = [self getDialogMoForDialogId:dialogId];

    if (!dialog || dialog.Property_ACDialogs_tmpLocalType != 0) {
        [self requestDialogsInfo:@[dialogId] complete:nil];
    }
}

- (void)createDialogIfNotExist:(NSString *)dialogId isTrusty:(BOOL)isTrusty invisible:(BOOL)invisible {
    ACDialogMo *dialog = [self getDialogMoForDialogId:dialogId];
    if (!dialog) {
        dialog = [[ACDialogMo alloc] init];
        dialog.Property_ACDialogs_dialogId = dialogId;
        dialog.Property_ACDialogs_tmpLocalType = isTrusty ? 1 : 2;
        dialog.Property_ACDialogs_updateTime = 10000; // 设置初始值
        dialog.Property_ACDialogs_msgInvisible = invisible;
        [self insertDialog:dialog];
    } else {
        if (dialog.Property_ACDialogs_isHidden || dialog.Property_ACDialogs_msgInvisible) {
            dialog.Property_ACDialogs_isHidden = NO;
            if (dialog.Property_ACDialogs_msgInvisible)
                dialog.Property_ACDialogs_msgInvisible = invisible;
            [self updateDbDialog:dialog];
        }
    }
}

- (void)createHiddenDialog:(NSString *)dialogId {
    ACDialogMo *dialog = [self getDialogMoForDialogId:dialogId];
    if (!dialog) {
        dialog = [[ACDialogMo alloc] init];
        dialog.Property_ACDialogs_dialogId = dialogId;
        dialog.Property_ACDialogs_tmpLocalType = 2;
        dialog.Property_ACDialogs_isHidden = YES;
        dialog.Property_ACDialogs_updateTime = 10000; // 设置初始值
        [self insertDialog:dialog];
    }
}

// 获取新增的会话信息
- (void)addRemoteDialogsInfoIfNotExist:(NSArray *)dialogIdArr  {
    for (NSString *dialogIdStr in dialogIdArr) {
        [self createDialogIfNotExist:dialogIdStr isTrusty:YES invisible:![[ACSecretKey instance] hasLoadedSecretKeyForDialogID:dialogIdStr]];
    }

    NSArray *newDialogIdArr = [self extraNewDialogIds:dialogIdArr];
    if (!newDialogIdArr.count) return;
    [self requestDialogsInfo:newDialogIdArr complete:nil];

}

- (void)flushDialogsKeyStatus:(NSArray *)dialogIdArr {
    if (!dialogIdArr.count) return;
    for (NSString *dialogIdStr in dialogIdArr) {
        ACDialogMo *dialog = [self getDialogMoForDialogId:dialogIdStr];
        if (dialog) {
            dialog.Property_ACDialogs_msgInvisible = ![[ACSecretKey instance] hasLoadedSecretKeyForDialogID:dialogIdStr];
            [self updateDbDialog:dialog];
        }
    }
    [self sortDialogList];
}

- (void)requestDialogsInfo:(NSArray *)dialogIdArr complete:(void(^)(void))complete  {
    [[[ACGetBriefDialogListPacket alloc] initWithDialogIdArray:dialogIdArr] sendWithSuccessBlockIdParameter:^(ACPBGetBriefDialogListResp * _Nonnull response) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        [response.briefDialog enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ACPBBriefDialog * _Nonnull object, BOOL * _Nonnull stop) {
            ACBriefDialogMo *briefDi = [ACBriefDialogMo briefDialogCopyWithBriefDialog:object];
            [arr addObject:briefDi];
        }];
        
        for (ACBriefDialogMo *dialog in arr){
            ACDialogMo *conversation = [self getDialogMoForDialogId:dialog.dialogId];
            if (conversation) {
                [conversation reloadBy:dialog];
                [self updateDbDialog:conversation];
            }
            
            
        }
        
        !complete ?: complete();
    } failure:^(NSError * _Nonnull error, NSInteger errorCode) {
        !complete ?: complete();
    }];
}



- (NSArray *)extraNewDialogIds:(NSArray *)originalDialogIdArr {
    if (!originalDialogIdArr.count) return originalDialogIdArr;
    
    NSMutableArray *contentArr = [NSMutableArray array];
    NSArray *dataAllDialogs = [self selectAllLoadedDialogIds];
    for (NSString *dialogId in originalDialogIdArr) {
        if (![dataAllDialogs containsObject:dialogId]) {
            [contentArr addObject:dialogId];
        }
    }
    return [contentArr copy];
}

- (void)updateSgLastReceiveRecordTime:(NSString *)dialogId time:(long)time {
    [[ACDatabase DataBase] updateSgLastRecordTime:dialogId time:time];
}

- (NSDictionary *)getLastReceiveRecordTimeMap:(NSArray *)dialogIds {
    return [[ACDatabase DataBase] selectLastReceiveRecordTimeMap:dialogIds];
}

- (long)getLastReceiveRecordTimeForDialog:(NSString *)dialogId {
    if (!dialogId.length) return 0;
    NSNumber *valNum = [self getLastReceiveRecordTimeMap:@[dialogId]][dialogId];
    if (valNum) return [valNum longValue];
    return 0;
}

- (long)getSgLatestReceiveCursor {
    return [[ACDatabase DataBase] selectSgLatestRecordTime];
}


- (void)syncDialogStatus {
    
    if (self.isPullingDialogChangedData) return;
    self.isPullingDialogChangedData = YES;
    
    
    long offset = [ACLetterBox getDialogStatusOffSet];
    if (offset <= 0) {
        offset = [ACServerTime getServerMSTime] - 10000; // 设置初始值为当前时间的前10s
        [ACLetterBox setDialogStatusOffSet:offset];
    }
    
    [[[ACGetDialogChangedStatusPacket alloc] initWithOffset:offset] sendWithSuccessBlockIdParameter:^(ACPBGetNewSettingDialogListResp * _Nonnull response) {
        self.isPullingDialogChangedData = NO;
        if (response.setTime > 0) {
            [ACLetterBox setDialogStatusOffSet:response.setTime];
        }
        if (response.briefDialog) {
            [self updateDialogsStatus:response.briefDialog];
        }
    } failure:^(NSError * _Nonnull error, NSInteger errorCode) {
        self.isPullingDialogChangedData = NO;
    }];
}

- (void)updateDialogsStatus:(NSDictionary<NSString*, ACPBBriefDialog*> *)briefDialog {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    [briefDialog enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ACPBBriefDialog * _Nonnull object, BOOL * _Nonnull stop) {
        ACBriefDialogMo *briefDi = [ACBriefDialogMo briefDialogCopyWithBriefDialog:object];
        [arr addObject:briefDi];
    }];
    
    for (ACBriefDialogMo *dialog in arr){
        ACDialogMo *conversation = [self getDialogMoForDialogId:dialog.dialogId];
        if (conversation) {
            [conversation reloadBy:dialog];
            [self updateDbDialog:conversation];
        }
    }
}

- (void)insertDialog:(ACDialogMo *)dialog {
    if (!dialog) {
        return;
    }
    [self updateDbDialog:dialog];
    LOCK(
         if (self.dialogIndexesDict[dialog.Property_ACDialogs_dialogId] == nil) {
             [self.sgDialogs addObject:dialog];
             self.dialogIndexesDict[dialog.Property_ACDialogs_dialogId] = @(self.sgDialogs.count - 1);
         }
         );
    
}

- (void)updateDbDialog:(ACDialogMo *)dialog {
    if (!dialog) {
        return;
    }
    [[ACDatabase DataBase] updateDialog:dialog];
}



- (void)sortDialogList {
    LOCK(
         [self.sgDialogs sortUsingComparator:^NSComparisonResult(ACDialogMo *obj1, ACDialogMo *obj2) {
             return [obj1 compareToDialog:obj2];
         }];
         );
    [self updateDialogIndexes];
}

- (void)updateDialogIndexes {
    LOCK(
    [self.dialogIndexesDict removeAllObjects];
    [self.sgDialogs enumerateObjectsUsingBlock:^(ACDialogMo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        self.dialogIndexesDict[obj.Property_ACDialogs_dialogId] = @(idx);
    }];
         );
}

- (void)sortDialogListByInsertionType {
    
    LOCK(
         for (int i = 1; i < self.sgDialogs.count; i++) {
             // 寻找元素sgDialogs[i]合适的插入位置
             ACDialogMo *item = self.sgDialogs[i];
             int j; // j保存元素item应该插入的位置
             for (j = i; j > 0 &&  [self.sgDialogs[j - 1] compareToDialog:item] == NSOrderedDescending; j--) {
                 self.sgDialogs[j] = self.sgDialogs[j - 1];
                 }
             self.sgDialogs[j] = item;
         }
         );
    [self updateDialogIndexes];
}


#pragma mark - ACConnectionListenerProtocol

- (void)userDataDidLoad {
    LOCK(
         _sgDialogs = [[[ACDatabase DataBase] selectAllDialogs] mutableCopy];
         _dialogIndexesDict = [NSMutableDictionary dictionary];
         );
    [self sortDialogList];
}

- (void)onConnected {
    // 请求keys
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *allDialogIds = [[ACDialogManager sharedDialogManger] selectAllTrustyDialogIds];
        NSArray *loadedDialogIds = [[ACDatabase DataBase] selectLoadedSecretKeyDialogIds];
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", loadedDialogIds];
        NSArray *notLoadDialogIds = [allDialogIds filteredArrayUsingPredicate:filterPredicate];
        if (notLoadDialogIds.count) {
            [[ACSecretKey instance] loadDialogAesKeysWithDidlogIDs:notLoadDialogIds withCompletion:^(NSDictionary *t) {
                [self flushDialogsKeyStatus:notLoadDialogIds];
            }];
        }
    });
    // 同步会话状态
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([[ACIMLibLoader sharedLoader] getConnectionStatus] != ConnectionStatus_Connected) return;
        [self syncDialogStatus];
    });
}


@end
