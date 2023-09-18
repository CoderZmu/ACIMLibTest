//
//  ACDatabase+Dialog.m
//  ACIMLib
//
//  Created by 子木 on 2022/12/8.
//

#import "ACDatabase+Dialog.h"
#import "ACFMDB.h"
#import "ACDialogMo.h"
#import "ACLogger.h"


@implementation ACDatabase (Dialog)


- (ACDialogMo *)dialogsModelWithDBResult:(ACFMResultSet *)result
{

    ACDialogMo *dialog = [[ACDialogMo alloc] init];
    dialog.Property_ACDialogs_dialogId = [result stringForColumn:@"dialogId"];
    dialog.Property_ACDialogs_dialogTitle = [result stringForColumn:@"dialogTitle"];
    dialog.Property_ACDialogs_smallAvatarUrl = [result stringForColumn:@"smallAvatarUrl"];
    dialog.Property_ACDialogs_stickyFlag = [result boolForColumn:@"stickyFlag"];
    dialog.Property_ACDialogs_muteFlag = [result boolForColumn:@"muteFlag"];
    dialog.Property_ACDialogs_blockFlag = [result boolForColumn:@"blockFlag"];
    dialog.Property_ACDialogs_lastReadTime = [result longForColumn:@"readTime"];
    dialog.Property_ACDialogs_tmpLocalType = [result intForColumn:@"tmpLocal"];
    dialog.Property_ACDialogs_draftText = [result stringForColumn:@"draftText"];
    dialog.Property_ACDialogs_unreceiveUnReadCount = [result intForColumn:@"unreceivedUnreadCount"];
    dialog.Property_ACDialogs_unreceiveUnreadEndTime = [result longForColumn:@"unreceiveUnreadEndTime"];
    dialog.Property_ACDialogs_updateTime = [result longForColumn:@"updateTime"];
    dialog.Property_ACDialogs_notificationLevel = [result intForColumn:@"notificationLevel"];
    dialog.Property_ACDialogs_isHidden = [result boolForColumn:@"isHidden"];
    dialog.Property_ACDialogs_msgInvisible = [result boolForColumn:@"invisible"];
    return dialog;
}


- (NSArray *)selectAllDialogs {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString *sql = @"SELECT * FROM ACDialog";
        ACFMResultSet *set = [db executeQuery:sql];
        while ([set next]) {
            
            ACDialogMo *dialog = [self dialogsModelWithDBResult:set];
            [arr addObject:dialog];
        }
        [set close];
    }];

    return arr;
}

- (void)updateDialog:(ACDialogMo *)dialog {
    if (!dialog.Property_ACDialogs_dialogId.length) {
        return;
    }
    
    [self dataBaseOperation:^(ACFMDatabase* db) {
         NSString* sql = @"INSERT OR REPLACE INTO ACDialog(dialogId,dialogTitle,smallAvatarUrl,stickyFlag,muteFlag,blockFlag,groupFlag,readTime,tmpLocal,draftText,unreceivedUnreadCount,unreceiveUnreadEndTime,updateTime,notificationLevel,isHidden,invisible) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
        
         BOOL ret = [db executeUpdate:sql,
                     dialog.Property_ACDialogs_dialogId,
                     dialog.Property_ACDialogs_dialogTitle,
                     dialog.Property_ACDialogs_smallAvatarUrl,
                     @(dialog.Property_ACDialogs_stickyFlag),
                     @(dialog.Property_ACDialogs_muteFlag),
                     @(dialog.Property_ACDialogs_blockFlag),
                     @(dialog.Property_ACDialogs_groupFlag),
                     @(dialog.Property_ACDialogs_lastReadTime),
                     @(dialog.Property_ACDialogs_tmpLocalType),
                     dialog.Property_ACDialogs_draftText,
                     @(dialog.Property_ACDialogs_unreceiveUnReadCount),
                     @(dialog.Property_ACDialogs_unreceiveUnreadEndTime),
                     @(dialog.Property_ACDialogs_updateTime),
                     @(dialog.Property_ACDialogs_notificationLevel),
                     @(dialog.Property_ACDialogs_isHidden),
                     @(dialog.Property_ACDialogs_msgInvisible)];
         if (ret) {
         }else {
             [ACLogger error:@"db insert dialog fail -> dialog: %@, error: %zd", dialog.Property_ACDialogs_dialogId, db.lastError.userInfo];
         }
        
     }];
}


- (void)deleteDialog:(NSString *)dialogId {
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString* sql = @"DELETE FROM ACDialog WHERE dialogId=?";
        if ([db executeUpdate:sql,dialogId]) {
        } else {
            [ACLogger error:@"db delete dialog fail -> %zd",db.lastError.code];
        }
    }];
}

@end
