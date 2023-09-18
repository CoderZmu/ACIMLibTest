#import "ACDatabase.h"
#import "ACLogger.h"
#import "ACFMDB.h"
#import "ACBase.h"
#import "ACSecretKey.h"
#import "ACChatMessageMo.h"	
#import "ACAccountManager.h"
#import "ACHelper.h"
#import "ACDialogMo.h"
#import "ACFileManager.h"
#import "ACDialogSecretKeyMo.h"

static NSInteger const kMsgAttributeLengthThreshold = 1024;

//数据库版本
#define DBVERSION_KEY @"AC_DBVERSION_KEY"
int const ACIMStorageVersion = 0;

/*
添加字段步骤：
 1.给类添加属性
 2.在craeat Table 添加
 3.在数据库版本升级 添加
 4.update的时候要把字段更新进去
 5.读的时候要读出来
 */

/*
 DB更新：
 Verson_1：~~
 */

@interface ACDatabase ()

@property(nonatomic,strong)NSString* dbPath;

@property(nonatomic,strong)ACFMDatabaseQueue *queue;

//把未解密的消息解密后存回数据库
@property(nonatomic, strong) NSTimer *updateDecodeMessagesTimer;
@property(nonatomic, strong) NSMutableArray *updateDecodeMessages;

@property (nonatomic, assign) long previousUid;
@end

@implementation ACDatabase



- (void)addUnDecodeMessage:(ACMessageMo *)message {
    if(!self.updateDecodeMessagesTimer) {
        self.updateDecodeMessagesTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateUnDecodeMessage) userInfo:nil repeats:false];
    }
    if (!self.updateDecodeMessages) {
        self.updateDecodeMessages = [NSMutableArray array];
    }
    [self.updateDecodeMessages addObject:message];
}

- (void)updateUnDecodeMessage {
    if (self.updateDecodeMessages.count > 0) {
        [self updateMessageArr:self.updateDecodeMessages.copy];
        [self.updateDecodeMessages removeAllObjects];
    }
}


static ACDatabase* share;
+ (ACDatabase*)DataBase {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[ACDatabase alloc] init];
    });
    return share;
}


-(BOOL)prepareForUid:(long)uid {
    if (self.previousUid == uid)  return YES;
    
    self.dbPath = [ACFileManager dbPathForUid:uid];
    if (!_dbPath) return NO;
    
    self.queue = [ACFMDatabaseQueue databaseQueueWithPath:_dbPath];
    
    if (![self initDataBase]) return NO;
    
    self.previousUid = uid;
    return YES;
}


-(BOOL)initDataBase {
    __block NSError *error = nil;

    [self.queue inDatabase:^(ACFMDatabase *db) {
        
        [db setKey:[[ACSecretKey instance] dbSecretKey]];
        
        [self updateDBVersionIfNeed:ACIMStorageVersion withDb:db];
        
        NSString* createDialogSql = @"CREATE TABLE IF NOT EXISTS ACDialog(dialogId TEXT,dialogTitle TEXT,smallAvatarUrl TEXT,stickyFlag INTEGER,muteFlag INTEGER,blockFlag INTEGER,groupFlag INTEGER, readTime INTEGER, tmpLocal INTEGER, INTEGER,draftText TEXT,unreceivedUnreadCount INTEGER, unreceiveUnreadEndTime INTEGER, updateTime INTEGER, notificationLevel INTEGER, isHidden INTEGER,invisible INTEGER, PRIMARY KEY(dialogId))";
        [db executeUpdate:createDialogSql values:nil error:&error];
        
        NSString *createMediaAttributeSql = @"CREATE TABLE IF NOT EXISTS ACMediaAttributeExtend(msgId INTEGER,mediaAttribute TEXT,dialogId TEXT,PRIMARY KEY(msgId))";
        [db executeUpdate:createMediaAttributeSql values:nil error:&error];
        
        NSString *createMsgIdMapSql = @"CREATE TABLE IF NOT EXISTS ACMsgIdMap(msgId INTEGER,remoteId INTEGER,dialogId TEXT,PRIMARY KEY(msgId))";
        if ([db executeUpdate:createMsgIdMapSql values:nil error:&error]) {
            [db executeUpdate:@" CREATE INDEX IF NOT EXISTS ACMsgIdMapRemoteIdIndex ON ACMsgIdMap(remoteId);"];
        }
        
        NSString *createSearchIndexSql = @"CREATE TABLE IF NOT EXISTS ACSearchIndex(msgId INTEGER,dialogId TEXT,messageType TEXT, msgSendTime INTEGER, words TEXT,PRIMARY KEY(msgId))";
        [db executeUpdate:createSearchIndexSql values:nil error:&error];

        NSString *createSuperDialogRecordTimeSql = @"CREATE TABLE IF NOT EXISTS ACSuperDialogRecordTime(dialogId TEXT,lastMsgTime INTEGER,PRIMARY KEY(dialogId))";
            [db executeUpdate:createSuperDialogRecordTimeSql values:nil error:&error];
        
        NSString *createSuperDialogAddDefaultIntervalFlagSql = @"CREATE TABLE IF NOT EXISTS ACDialogAddDefaultIntervalFlag(dialogId TEXT,flag INTEGER, PRIMARY KEY(dialogId))";
        [db executeUpdate:createSuperDialogAddDefaultIntervalFlagSql values:nil error:&error];
        
        NSString *createSuperDialogMissingMsgIntervalSql = @"CREATE TABLE IF NOT EXISTS ACMissingMsgInterval(dialogId TEXT,left INTEGER,right INTEGER)";
        [db executeUpdate:createSuperDialogMissingMsgIntervalSql values:nil error:&error];
        
        NSString *createDialogSecretKeySql = @"CREATE TABLE IF NOT EXISTS ACDialogSecretKey(dialogId TEXT,key TEXT,iv TEXT,PRIMARY KEY(dialogId))";
        [db executeUpdate:createDialogSecretKeySql values:nil error:&error];
    }];
    
    if (error) {
        [self resetSgMessage:error];
    }
    return error == nil;
}


- (void)updateDBVersionIfNeed:(int)version withDb:(ACFMDatabase *)db {
    [db executeUpdate:@"CREATE TABLE IF NOT EXISTS VERSION(version INTEGER PRIMARY KEY)"];
    int oldVersion = 0;
    ACFMResultSet *resultSet = [db executeQuery:@"SELECT * FROM VERSION"];
    if ([resultSet next]) {
        oldVersion = [resultSet intForColumn:@"version"];
    }
    [resultSet close];
    
    if (oldVersion >= version) return;
    
    [db executeUpdate:@"DELETE FROM VERSION"];
    [db executeUpdate:@"INSERT OR REPLACE INTO VERSION (version) VALUES(?)", @(version)];

}

- (void)dataBaseOperation:(void(^)(ACFMDatabase* db))operation {
    [self.queue inDatabase:operation];
}


#pragma mark - Message

//根据会话id获得消息表名称
- (NSString *)ac_message_tableName:(NSString *)dialogId {
    return [NSString stringWithFormat:@"ACMessage_%@", [dialogId stringByReplacingOccurrencesOfString:@"::" withString:@"__"]];
}


- (NSInteger)selectDialogUnreadCount:(NSString *)dialogId afterTime:(long)time {
    __block NSInteger count = 0;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        
        NSString *sql = [NSString stringWithFormat:@"SELECT count(*) as 'count' FROM %@ WHERE msgSendTime > ? AND countedFlag=1 AND isOut=0 AND readType < ?",[self ac_message_tableName:dialogId]];
        ACFMResultSet *rs = [db executeQuery:sql, @(time), @(ACMessageReadTypeReaded)];
        while ([rs next]) {
            count += [rs intForColumn:@"count"];
        }
        [rs close];
     
    }];
    return count;
}

- (NSInteger)selectDialogUnreadMentionedCount:(NSString *)dialogId afterTime:(long)time {
    __block NSInteger count = 0;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        
        NSString *sql = [NSString stringWithFormat:@"SELECT count(*) as 'count' FROM %@ WHERE msgSendTime > ? AND atFlag = 1 AND countedFlag=1 AND isOut=0 AND readType < ?",[self ac_message_tableName:dialogId]];
        ACFMResultSet *rs = [db executeQuery:sql, @(time), @(ACMessageReadTypeReaded)];
        while ([rs next]) {
            count += [rs intForColumn:@"count"];
        }
        [rs close];
     
    }];
    return count;
}

- (BOOL)hasUnreadMentionedMessageForDialog:(NSString *)dialogId afterTime:(long)time {
    __block BOOL isExist = NO;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        
        NSString *sql = [NSString stringWithFormat:@"SELECT msgId FROM %@ WHERE msgSendTime > ? AND atFlag = 1 AND countedFlag=1 AND isOut=0 AND readType < ? LIMIT 1",[self ac_message_tableName:dialogId]];
        ACFMResultSet *rs = [db executeQuery:sql, @(time), @(ACMessageReadTypeReaded)];
        while ([rs next]) {
            isExist = YES;
        }
        [rs close];
     
    }];
    return isExist;
}


//根据会话id创建消息表
- (void)creatSg_message_table:(NSString *)dialogId db:(ACFMDatabase* )db {
    NSString *tableName = [self ac_message_tableName:dialogId];
    void (^ creatSg_Message_table_block)(ACFMDatabase* db) = ^ (ACFMDatabase* db){
        NSString* ac_message = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(msgId INTEGER, remoteId INTEGER,localId INTEGER,srcId INTEGER,isOut INTEGER, mediaFlag INTEGER,objectName Text,msgSendTime INTEGER,msgReceiveTime INTEGER,atFlag INTEGER,deliveryState INTEGER,readType INTEGER, groupFlag INTEGER, decode INTEGER,countedFlag INTEGER, messageType TEXT, mediaAttriExtendFlag INTEGER,localFlag INTEGER,mediaAttribute TEXT, extra TEXT, mediaData BLOB,expansion Text, PRIMARY KEY(msgId));", tableName];
        
        if ([db executeUpdate:ac_message]) {
            [db executeUpdate:[NSString stringWithFormat:@" CREATE INDEX IF NOT EXISTS %@SendTimeIndex ON %@(msgSendTime);",tableName, tableName]];
            [db executeUpdate:[NSString stringWithFormat:@" CREATE INDEX IF NOT EXISTS %@RemoteIdIndex ON %@(remoteId);",tableName, tableName]];
        }
    };
    if (db) {
        creatSg_Message_table_block(db);
    } else {
        [self dataBaseOperation:creatSg_Message_table_block];
    }
}

- (NSArray *)loadAllMessageTable:(ACFMDatabase *)db {
    NSString *allMesageSql = @"SELECT * FROM sqlite_master WHERE type='table' AND name LIKE 'ACMessage_%'";
    ACFMResultSet* result = [db executeQuery:allMesageSql];
    NSMutableArray *message_tabelNames = [NSMutableArray array];
    while ([result next]) {
        NSString *name = [result stringForColumn:@"name"];
        [message_tabelNames addObject:name];
    }
    return message_tabelNames.copy;
}


- (void)updateMessage:(ACMessageMo *)message {
    [self updateMessageArr:@[message]];
}

- (void)updateMessageArr:(NSArray *)messageArr {
    if (messageArr.count == 0) {
        return;
    }

    [self.queue inTransaction:^(ACFMDatabase *db, BOOL *rollback) {
        @try {
            for (ACMessageMo *message in messageArr) {
                [self updateMessage:message db:db];
            }
        } @catch (NSException *exception) {
            *rollback = YES;
        }
        
    }];
 
}

- (void)updateMessage:(ACMessageMo *)message db:(ACFMDatabase *)db {
    
    NSString* sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@(msgId,remoteId,localId,srcId,isOut, mediaFlag,objectName,msgSendTime,msgReceiveTime,atFlag,deliveryState,readType,groupFlag,decode,countedFlag,messageType,mediaAttriExtendFlag,localFlag,mediaAttribute,extra,mediaData,expansion) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", [self ac_message_tableName:message.Property_ACMessage_dialogIdStr]];
    
    BOOL ret = [self updateMessage:message sql:sql db:db];
    if (!ret && db.lastError.code == 1) {
        [self creatSg_message_table:message.Property_ACMessage_dialogIdStr db:db];
        ret = [self updateMessage:message sql:sql db:db];
    }
    if (!ret) {
        [ACLogger error:@"db insert message fail -> mTime: %ld, error: %@", message.Property_ACMessage_msgSendTime, db.lastError.userInfo];
    }
    
}


- (BOOL)updateMessage:(ACMessageMo *)message sql:(NSString *)sql db:(ACFMDatabase* )db {
    
    NSUInteger mediaAttributeLength = [message.Property_ACMessage_mediaAttribute lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    BOOL mediaAttriExtendFlag = mediaAttributeLength > kMsgAttributeLengthThreshold;
    
    BOOL ret = [db executeUpdate:sql,
                [NSNumber numberWithLong:message.Property_ACMessage_msgId],
                [NSNumber numberWithLong:message.Property_ACMessage_remoteId],
                [NSNumber numberWithLong:message.Property_ACMessage_localId],
                [NSNumber numberWithLong:message.Property_ACMessage_srcUin],
                [NSNumber numberWithBool:message.Property_ACMessage_isOut],
                [NSNumber numberWithBool:message.Property_ACMessage_mediaFlag],
                message.Property_ACMessage_objectName,
                [NSNumber numberWithLong:message.Property_ACMessage_msgSendTime],
                [NSNumber numberWithLong:message.Property_ACMessage_msgReceiveTime],
                [NSNumber numberWithBool:message.Property_ACMessage_atFlag],
                [NSNumber numberWithInt:message.Property_ACMessage_deliveryState],
                @(message.Property_ACMessage_readType),
                @(message.Property_ACMessage_groupFlag),
                @(message.Property_ACMessage_decode),
                @([message isCounted]),
                [message messageType],
                @(mediaAttriExtendFlag),
                @(message.Property_ACMessage_isLocal),
                mediaAttriExtendFlag ? @"" : message.Property_ACMessage_mediaAttribute,
                message.Property_ACMessage_extra,
                message.Property_ACMessage_originalMediaData,
                message.Property_ACMessage_expansionStr];
    
    if (ret) {
        [self updateMsgIdMap:message.Property_ACMessage_msgId remoteId:message.Property_ACMessage_remoteId dialogId:message.Property_ACMessage_dialogIdStr withDb:db];
        [self updateSearchIndex:message withDb:db];
        if (mediaAttriExtendFlag) {
            [self updateMsgMediaAttribute:message.Property_ACMessage_mediaAttribute dialogId:message.Property_ACMessage_dialogIdStr forMsgId:message.Property_ACMessage_msgId withDb:db];
        }
    }
    return ret;
}


- (NSArray *)selectMessageWithDialogId:(NSString *)dialogId count:(int)num {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY msgSendTime DESC LIMIT ?", [self ac_message_tableName:dialogId]];
        [arr addObjectsFromArray:[self selectMessageBySql:sql arguments:@[@(num)] forDialogId:dialogId db:db]];
    }];
    return arr;
}

- (NSArray *)selectMessageBySql:(NSString *)sql arguments:(NSArray *)arguments forDialogId:(NSString *)dialogId db:(ACFMDatabase *)db{
    //查询
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    ACFMResultSet *result = nil;
    if (arguments) {
        result = [db executeQuery:sql withArgumentsInArray:arguments];
    } else {
        result = [db executeQuery:sql];
    }
    while ([result next]) {
        ACMessageMo *message = [self loadMessageFromDatabase:result dialogId:dialogId withDb:db];
        [arr addObject:message];
    }
    [result close];
    return arr;
}


- (NSArray *)selectMessageWithDialogId:(NSString *)dialogId count:(int)num baseMsgId:(long)msgId isForward:(BOOL)isForward messageTypes:(NSArray *)messageTypes {
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString *msgIdQueryStr;
        NSString *messageTypeQueryStr;
        if (msgId > 0) {
            msgIdQueryStr = [NSString stringWithFormat:@"msgId %s ?", isForward ? "<" : ">"];
        }
        
        if (messageTypes.count) {
            NSMutableString *holder = [NSMutableString stringWithString:@"?"];
            
            for (NSInteger i=1; i<messageTypes.count; i++) {
                [holder appendString:@",?"];
            }
            
            messageTypeQueryStr = [NSString stringWithFormat:@"messageType IN (%@)", holder];
        }
        
        
        NSMutableArray *arguments = [NSMutableArray array];
        NSMutableString *sql = [NSMutableString string];
        [sql appendFormat:@"SELECT * FROM %@", [self ac_message_tableName:dialogId]];
        if (msgIdQueryStr.length) {
            [sql appendFormat:@" WHERE %@", msgIdQueryStr];
            [arguments addObject:@(msgId)];
        }
        if (messageTypeQueryStr.length) {
            [sql appendFormat:@" %@ %@", arguments.count > 0 ? @"AND" : @"WHERE",  messageTypeQueryStr];
            [arguments addObjectsFromArray:messageTypes];
            
        }
        [sql appendFormat:@" ORDER BY msgId %@ LIMIT ?", isForward ? @"DESC" : @"ASC"];
        [arguments addObject:@(num)];
        
        [arr addObjectsFromArray:[self selectMessageBySql:sql arguments:arguments forDialogId:dialogId db:db]];
      
    }];

    return arr;
}


- (NSArray *)selectMessageWithDialogId:(NSString *)dialogId count:(int)num baseRecordTime:(long)recordTime isForward:(BOOL)isForward messageTypes:(NSArray *)messageTypes {
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString *sendTimeQueryStr;
        NSString *messageTypeQueryStr;
        if (recordTime > 0) {
            sendTimeQueryStr = [NSString stringWithFormat:@"msgSendTime %s ?", isForward ?  "<" : ">="];
        }
        
        if (messageTypes.count) {
            NSMutableString *holder = [NSMutableString stringWithString:@"?"];
            
            for (NSInteger i=1; i<messageTypes.count; i++) {
                [holder appendString:@",?"];
            }
            
            messageTypeQueryStr = [NSString stringWithFormat:@"messageType IN (%@)", holder];
        }
        
        
        NSMutableArray *arguments = [NSMutableArray array];
        NSMutableString *sql = [NSMutableString string];
        [sql appendFormat:@"SELECT * FROM %@", [self ac_message_tableName:dialogId]];
        if (sendTimeQueryStr.length) {
            [sql appendFormat:@" WHERE %@", sendTimeQueryStr];
            [arguments addObject:@(recordTime)];
        }
        if (messageTypeQueryStr.length) {
            [sql appendFormat:@" %@ %@", arguments.count > 0 ? @"AND" : @"WHERE",  messageTypeQueryStr];
            [arguments addObjectsFromArray:messageTypes];
            
        }
        [sql appendFormat:@" ORDER BY msgSendTime %@ LIMIT ?", isForward ? @"DESC" : @"ASC"];
        
        [arguments addObject:@(num)];
        
        [arr addObjectsFromArray:[self selectMessageBySql:sql arguments:arguments forDialogId:dialogId db:db]];
      
    }];

    return arr;
}

- (NSArray *)selectPreviousMessageWithDialogId:(NSString *)dialogId count:(int)count baseRecordTime:(long)baseRecordTime minTime:(long)minTime  {
    if (baseRecordTime > 0 && minTime > 0 && baseRecordTime <= minTime) return @[];
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [self dataBaseOperation:^(ACFMDatabase *db) {

        NSMutableArray *arguments = [NSMutableArray array];
        NSMutableString *sql = [NSMutableString string];
        [sql appendFormat:@"SELECT * FROM %@", [self ac_message_tableName:dialogId]];
        if (baseRecordTime > 0) {
            [sql appendString:@" WHERE msgSendTime < ?"];
            [arguments addObject:@(baseRecordTime)];
        }
        if (minTime > 0) {
            [sql appendFormat:@" %@ %@", arguments.count > 0 ? @"AND" : @"WHERE",  @"msgSendTime >= ?"];
            [arguments addObject:@(minTime)];
        }
  
        [sql appendString:@" ORDER BY msgSendTime DESC LIMIT ?"];
        [arguments addObject:@(count)];
        
        [arr addObjectsFromArray:[self selectMessageBySql:sql arguments:arguments forDialogId:dialogId db:db]];
      
    }];
    return arr;
}

- (NSArray *)selectNextMessageWithDialogId:(NSString *)dialogId count:(int)count baseRecordTime:(long)baseRecordTime maxTime:(long)maxTime  {
    if (baseRecordTime <= 0) return @[];
    if (maxTime > 0 && baseRecordTime >= maxTime) return @[];
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [self dataBaseOperation:^(ACFMDatabase *db) {

        NSMutableArray *arguments = [NSMutableArray array];
        NSMutableString *sql = [NSMutableString string];
        [sql appendFormat:@"SELECT * FROM %@  WHERE msgSendTime > ?", [self ac_message_tableName:dialogId]];
        [arguments addObject:@(baseRecordTime)];
        if (maxTime > 0) {
            [sql appendString:@" AND msgSendTime <= ?"];
            [arguments addObject:@(maxTime)];
        }
  
        [sql appendString:@" ORDER BY msgSendTime ASC LIMIT ?"];
        [arguments addObject:@(count)];
        
        [arr addObjectsFromArray:[self selectMessageBySql:sql arguments:arguments forDialogId:dialogId db:db]];
      
    }];
    return arr;
}

- (NSArray<NSNumber *> *)selectOutMediaMessageIdsWithDialogId:(NSString *)dialogId beforeTimeSend:(long)recordTime {
    NSMutableArray<NSNumber *> *retVal = [NSMutableArray array];
    
    [self dataBaseOperation:^(ACFMDatabase* db){
        NSString *messageTable = [self ac_message_tableName:dialogId];

        NSString *sql = [NSString stringWithFormat:@"SELECT msgId FROM %@ WHERE isOut = 1 AND mediaFlag=1 AND msgSendTime <= ?", messageTable]; ;
        ACFMResultSet *set = [db executeQuery:sql, @(recordTime)];
        while ([set next]) {
            [retVal addObject:@([set longForColumn:@"msgId"])];
        }
        [set close];

    }];
    
    return [retVal copy];
}


- (ACMessageMo *)selectMessageWithLocalId:(long)localId dilogId:(NSString *)dialogId; {
    __block ACMessageMo *message;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE localId=? LIMIT 1", [self ac_message_tableName:dialogId]];
        ACFMResultSet *result = [db executeQuery:sql, @(localId)];
        if ([result next]) {
            message = [self loadMessageFromDatabase:result dialogId:dialogId withDb:db];;
        }
        [result close];
    
    }];
    return message;
}

- (ACMessageMo *)selectMessageWithMsgId:(long)msgId dilogId:(NSString *)dialogId {
    __block ACMessageMo *message;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE msgId=? LIMIT 1", [self ac_message_tableName:dialogId]];
        ACFMResultSet *result = [db executeQuery:sql, @(msgId)];
        if ([result next]) {
            message = [self loadMessageFromDatabase:result dialogId:dialogId withDb:db];;
        }
        [result close];
    
    }];
    return message;
}

- (ACMessageMo *)selectMessageWithRemoteId:(long)remoteId dilogId:(NSString *)dialogId {
    __block ACMessageMo *message;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE remoteId=? LIMIT 1", [self ac_message_tableName:dialogId]];
        ACFMResultSet *result = [db executeQuery:sql, @(remoteId)];
        if ([result next]) {
            message = [self loadMessageFromDatabase:result dialogId:dialogId withDb:db];;
        }
        [result close];
    
    }];
    return message;
}

- (ACMessageMo *)selectLatestMessageWithDialogId:(NSString *)dialogId {
    __block ACMessageMo *message;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY msgSendTime DESC LIMIT 1", [self ac_message_tableName:dialogId]];
        ACFMResultSet *result = [db executeQuery:sql];
        if ([result next]) {
            message = [self loadMessageFromDatabase:result dialogId:dialogId withDb:db];
        }
        [result close];

        
    }];
    return message;
}

- (NSArray *)selectUnreadMentionedMessagesWithDialogId:(NSString *)dialogId afterTime:(long)time count:(int)count {
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    [self dataBaseOperation:^(ACFMDatabase *db) {

        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE msgSendTime > ? AND readType < ? AND isOut = 0 AND atFlag = 1 ORDER BY msgSendTime DESC LIMIT ?", [self ac_message_tableName:dialogId]];
      
        [arr addObjectsFromArray:[self selectMessageBySql:sql arguments:@[@(time),@(ACMessageReadTypeReaded), @(count)] forDialogId:dialogId db:db]];
      
    }];
    return arr;
}

- (ACMessageMo *)selectFirstUnreadMessage:(NSString *)dialogId afterTime:(long)time {
    __block ACMessageMo *message;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE msgSendTime > ? AND readType < ? AND isOut = 0 ORDER BY msgSendTime ASC LIMIT 1", [self ac_message_tableName:dialogId]];
        message = [self selectMessageBySql:sql arguments:@[@(time),@(ACMessageReadTypeReaded)] forDialogId:dialogId db:db].firstObject;
    }];
    return message;
}

- (long)selectLatestMessageSentTime:(NSString *)dialogId {
    __block long msgSendTime = 0;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT msgSendTime FROM %@ ORDER BY msgSendTime DESC LIMIT 1", [self ac_message_tableName:dialogId]];
        ACFMResultSet *result = [db executeQuery:sql];
        if ([result next]) {
            msgSendTime = [result longForColumn:@"msgSendTime"];
        }
        [result close];
    
    }];
    return msgSendTime;
}

- (long)selectLatestReceivedMessageRecordTime:(NSString *)dialogId {
    __block long msgSendTime = 0;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT msgSendTime FROM %@ WHERE localFlag = 0 ORDER BY msgSendTime DESC LIMIT 1", [self ac_message_tableName:dialogId]];
        ACFMResultSet *result = [db executeQuery:sql];
        if ([result next]) {
            msgSendTime = [result longForColumn:@"msgSendTime"];
        }
        [result close];
    
    }];
    return msgSendTime;
}

- (long)selectOldestReceivedMessageRecordTime:(NSString *)dialogId {
    __block long msgSendTime = 0;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"SELECT msgSendTime FROM %@ WHERE localFlag = 0 ORDER BY msgSendTime ASC LIMIT 1", [self ac_message_tableName:dialogId]];
        ACFMResultSet *result = [db executeQuery:sql];
        if ([result next]) {
            msgSendTime = [result longForColumn:@"msgSendTime"];
        }
        [result close];
    
    }];
    return msgSendTime;
}


- (NSArray<ACMessageMo *> *)selectMessagesWithDialogId:(NSString *)dialogId
                                               keyword:(NSString *)keyword
                                                 count:(int)count
                                        baseRecordTime:(long long)recordTime {

    __block NSArray *retVal;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        if (recordTime > 0) {
            NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE msgId IN (SELECT msgId FROM ACSearchIndex WHERE dialogId =? AND msgSendTime < ? AND words LIKE '%%%@%%' LIMIT ?) ORDER BY msgSendTime DESC", [self ac_message_tableName:dialogId], keyword];
            retVal = [self selectMessageBySql:sql arguments:@[dialogId, @(recordTime), @(count)] forDialogId:dialogId db:db];
        } else {
            NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE msgId IN (SELECT msgId FROM ACSearchIndex WHERE dialogId =? AND words LIKE '%%%@%%' LIMIT ?) ORDER BY msgSendTime DESC", [self ac_message_tableName:dialogId], keyword];
            retVal = [self selectMessageBySql:sql arguments:@[dialogId, @(count)] forDialogId:dialogId db:db];
        }
    }];
    return retVal;
}

- (NSArray<NSDictionary *> *)selectMessageBriefInfosWithDialogId:(NSString *)dialogId forMsgIdList:(NSArray<NSNumber *> *)msgIdList {
    NSMutableArray *contentArray = [NSMutableArray array];
    [self dataBaseOperation:^(ACFMDatabase* db){
        NSString *sql = [NSString stringWithFormat:@"SELECT msgId, remoteId, mediaFlag, isOut FROM %@ WHERE msgId in (%@)", [self ac_message_tableName:dialogId], [msgIdList componentsJoinedByString:@","]];
        ACFMResultSet *result = [db executeQuery:sql];
        while ([result next]) {
            NSDictionary *info = @{
                @"msgId": @([result longForColumn:@"msgId"]),
                @"remoteId": @([result longForColumn:@"remoteId"]),
                @"mediaFlag": @([result boolForColumn:@"mediaFlag"]),
                @"isOut": @([result boolForColumn:@"isOut"]),
            };
            [contentArray addObject:info];
        }
        [result close];
    }];
    
    return [contentArray copy];
}




- (BOOL)isExistMessageWithDialogId:(NSString *)dialogId forSendTime:(long)sendTime {
    __block BOOL isExist = NO;
    [self dataBaseOperation:^(ACFMDatabase* db){
        NSString *sql = [NSString stringWithFormat:@"SELECT msgId FROM %@ WHERE msgSendTime = ? LIMIT 1", [self ac_message_tableName:dialogId]];
        ACFMResultSet *result = [db executeQuery:sql, @(sendTime)];
        while ([result next]) {
            isExist = YES;
        }
        [result close];
    }];
    
    return isExist;
}

- (BOOL)isExistMessageWithDialogId:(NSString *)dialogId forRemoteId:(long)remoteId {
    __block BOOL isExist = NO;
    [self dataBaseOperation:^(ACFMDatabase* db){
        NSString *sql = [NSString stringWithFormat:@"SELECT remoteId FROM %@ WHERE remoteId=? LIMIT 1", [self ac_message_tableName:dialogId]];
        ACFMResultSet *result = [db executeQuery:sql, @(remoteId)];
        while ([result next]) {
            isExist = YES;
        }
        [result close];
    }];
    
    return isExist;
}


- (ACMessageMo *)loadMessageFromDatabase:(ACFMResultSet *)result dialogId:(NSString *)dialogId withDb:(ACFMDatabase *)db  {
    ACMessageMo *message = [[ACMessageMo alloc] init];
    message.Property_ACMessage_dialogIdStr = dialogId;
    message.Property_ACMessage_msgId = [result longForColumn:@"msgId"];
    message.Property_ACMessage_remoteId = [result longForColumn:@"remoteId"];
    message.Property_ACMessage_localId = [result longForColumn:@"localId"];
    message.Property_ACMessage_srcUin = [result longForColumn:@"srcId"];
    message.Property_ACMessage_isOut = [result boolForColumn:@"isOut"];
    message.Property_ACMessage_mediaFlag = [result boolForColumn:@"mediaFlag"];
    message.Property_ACMessage_objectName = [result stringForColumn:@"objectName"];
    message.Property_ACMessage_msgSendTime = [result longLongIntForColumn:@"msgSendTime"];
    message.Property_ACMessage_msgReceiveTime = [result longLongIntForColumn:@"msgReceiveTime"];
    message.Property_ACMessage_atFlag = [result boolForColumn:@"atFlag"];
    message.Property_ACMessage_deliveryState = [result intForColumn:@"deliveryState"];
    message.Property_ACMessage_readType = [result intForColumn:@"readType"];
    message.Property_ACMessage_groupFlag = [result boolForColumn:@"groupFlag"];
    message.Property_ACMessage_decode = [result boolForColumn:@"decode"];
    message.Property_ACMessage_mediaAttribute = [result stringForColumn:@"mediaAttribute"];
    message.Property_ACMessage_isLocal = [result boolForColumn:@"localFlag"];;
    message.Property_ACMessage_extra = [result stringForColumn:@"extra"];
    message.Property_ACMessage_expansionStr = [result stringForColumn:@"expansion"];
    if (!message.Property_ACMessage_decode) {
        message.Property_ACMessage_originalMediaData = [result dataForColumn:@"mediaData"];
    }
    BOOL extendFlag = [result boolForColumn:@"mediaAttriExtendFlag"];
    if (extendFlag) {
        message.Property_ACMessage_mediaAttribute = [self selectMsgMediaAttributeWithMsgId:message.Property_ACMessage_msgId withDb:db];
    }

    if (!message.Property_ACMessage_decode) {
        // 未解析
        ACDialogSecretKeyMo *key = [self selectDialogSecretKeyDialog:message.Property_ACMessage_dialogIdStr withDb:db];
        if (key) {
            [message decryptWithAesKey:key];
            [self addUnDecodeMessage:message];
        }
    }
    return message;
}


- (void)updateReceiveMessagesAsReadStatusWithDialog:(NSString *)dialogId between:(long)startTime and:(long)endTime {
    if (startTime >= endTime) return;
    [self dataBaseOperation:^(ACFMDatabase* db) {
        
        NSString * sql = [NSString stringWithFormat:@"UPDATE %@ SET readType = ? WHERE msgSendTime BETWEEN ? AND ? AND  isOut=0 ", [self ac_message_tableName:dialogId]];
        [db executeUpdate:sql, @(ACMessageReadTypeReaded),@(startTime),@(endTime)];
        
    }];
}


- (void)updateMessageReadType:(NSDictionary *)dic dialogId:(NSString *)dialogId{
    [self dataBaseOperation:^(ACFMDatabase* db) {
        [dic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSDictionary *  _Nonnull obj, BOOL * _Nonnull stop) {
            NSNumber *readType = obj[@"readType"];
            NSNumber *time = obj[@"time"];
            if (time) {
                NSString * sql = [NSString stringWithFormat:@"UPDATE %@ SET readType = ?, msgReceiveTime = ? WHERE remoteId = ?", [self ac_message_tableName:dialogId]];
                 [db executeUpdate:sql,readType, time, key];
            } else {
                NSString * sql = [NSString stringWithFormat:@"UPDATE %@ SET readType = ? WHERE remoteId = ?", [self ac_message_tableName:dialogId]];
                 [db executeUpdate:sql,readType, key];
            }
            
        }];
    }];
}

- (BOOL)deleteMessageWithDialogId:(NSString *)dialogId {
    __block BOOL result = YES;
    [self.queue inTransaction:^(ACFMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        @try {
            NSString *sql1 = [NSString stringWithFormat:@"DELETE FROM %@", [self ac_message_tableName:dialogId]];
            result = [db executeUpdate:sql1];
            if (result) {
                [self deleteMsgIdForDialog:dialogId withDb:db];
                [self deleteSearchForDialog:dialogId withDb:db];
                [self deleteMsgMediaAttributeForDialog:dialogId withDb:db];
                [self deleteAllMissingMsgsIntervalForDialog:dialogId withDb:db];
                [self setAddedDefaultMissingMsgInvtervalForDialog:dialogId val:NO withDb:db];
            }
        } @catch (NSException *exception) {
            *rollback = YES;
            result = NO;
        }
    }];
    return result;
}

- (BOOL)deleteMessageWithDialogId:(NSString *)dialogId beforeTime:(long)timestamp {
    if (timestamp <= 0) {
        return [self deleteMessageWithDialogId:dialogId];
    }
    
    __block BOOL result = YES;
    [self.queue inTransaction:^(ACFMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        @try {
            NSString *messageTable = [self ac_message_tableName:dialogId];
            
            // 删除idMap
            NSString *deleteIdMapSql = [NSString stringWithFormat:@"DELETE FROM ACMsgIdMap WHERE msgId IN ( SELECT msgId FROM %@ WHERE msgSendTime <= ? )", messageTable]; ;
            [db executeUpdate:deleteIdMapSql ,@(timestamp)];
            
            // 删除search
            NSString *deleteSearchSql = [NSString stringWithFormat:@"DELETE FROM ACSearchIndex WHERE msgId IN ( SELECT msgId FROM %@ WHERE msgSendTime <= ? )", messageTable]; ;
            [db executeUpdate:deleteSearchSql ,@(timestamp)];
            
            // 删除mediaAttribute
            NSString *deleteMediaAttributeSql = [NSString stringWithFormat:@"DELETE FROM ACMediaAttributeExtend WHERE msgId IN ( SELECT msgId FROM %@ WHERE mediaAttriExtendFlag = 1 AND msgSendTime <= ? )", messageTable];
            [db executeUpdate:deleteMediaAttributeSql ,@(timestamp)];
            
            // 删除missingInterval
            NSString* deleteMissingIntevalSql = @"DELETE FROM ACMissingMsgInterval WHERE dialogId = ? AND right <= ?";
            [db executeUpdate:deleteMissingIntevalSql ,dialogId, @(timestamp)];
            [self addMissingMsgsIntervalForDialog:dialogId interval:[[ACMissingMsgsInterval alloc] initWithLeft:0 right:timestamp+1] withDb:db];
            
            // 删除消息
            NSString* deleteMessageSql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE msgSendTime <= ? ", [self ac_message_tableName:dialogId]];
            result = [db executeUpdate:deleteMessageSql ,@(timestamp)];
            
        } @catch (NSException *exception) {
            [ACLogger error:@"db delete message list fail -> dialogId: %@, error: %@", dialogId, db.lastError];
            *rollback = YES;
            result = NO;
        }
    }];
    
    return result;
}

- (void)deleteMessageWithMsgIds:(NSArray *)msgIds dialogId:(NSString *)dialogId {
    
    if (!msgIds.count) return;
    [self.queue inTransaction:^(ACFMDatabase *db, BOOL *rollback) {
        @try {
            for (NSNumber *msgIdNum in msgIds) {
                if ([msgIdNum longLongValue]) {
                    [self deleteMessageWithMsgId:[msgIdNum longLongValue] dilogId:dialogId db:db];
                }
              
            }
        } @catch (NSException *exception) {
            *rollback = YES;
        }
    }];
    
}

- (void)deleteMessageWithMsgId:(int64_t)msgId dilogId:(NSString *)dialogId db:(ACFMDatabase *)db {

    NSString* sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE msgId=?", [self ac_message_tableName:dialogId]];
    if ([db executeUpdate:sql,@(msgId)]) {
        [self deleteMsgMediaAttribute:msgId  withDb:db];
        [self deleteMsgIdMap:msgId withDb:db];
        [self deleteSearchIndex:msgId withDb:db];
    } else {
        [ACLogger error:@"db delete message fail -> error: %@", db.lastError];
    }

}


#pragma mark - MediaAttributeExtend

- (void)updateMsgMediaAttribute:(NSString *)mediaAttribute dialogId:(NSString *)dialogId forMsgId:(long)msgId withDb:(ACFMDatabase *)db {
    NSString* sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO ACMediaAttributeExtend(msgId,dialogId,mediaAttribute) VALUES (?,?,?)"];
    [db executeUpdate:sql,
     [NSNumber numberWithLong:msgId],
     dialogId,
     mediaAttribute];
}


- (NSString *)selectMsgMediaAttributeWithMsgId:(long)msgId withDb:(ACFMDatabase *)db {
    NSString *mediaAttribute;
    NSString *sql = @"SELECT mediaAttribute FROM ACMediaAttributeExtend WHERE msgId=? LIMIT 1";
    ACFMResultSet *result = [db executeQuery:sql, @(msgId)];
    while ([result next]) {
        mediaAttribute = [result stringForColumn:@"mediaAttribute"];
    }
    [result close];
    
    return mediaAttribute;
}

- (void)deleteMsgMediaAttribute:(long)msgId withDb:(ACFMDatabase *)db {
    NSString* sql = @"DELETE FROM ACMediaAttributeExtend WHERE msgId=?";
    [db executeUpdate:sql,@(msgId)];
}

- (void)deleteMsgMediaAttributeForDialog:(NSString *)dialogId withDb:(ACFMDatabase *)db {
    NSString* sql = @"DELETE FROM ACMediaAttributeExtend WHERE dialogId=?";
    [db executeUpdate:sql,dialogId];
}


#pragma mark - MsgIdMap

- (void)updateMsgIdMap:(long)msgId remoteId:(long)remoteId dialogId:(NSString *)dialogId withDb:(ACFMDatabase *)db {
    NSString* sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO ACMsgIdMap(msgId,remoteId,dialogId) VALUES (?,?,?)"];
    [db executeUpdate:sql,
     @(msgId),
     @(remoteId),
     dialogId];
    
}

- (NSString *)selectDialogIdWithMsgId:(long)msgId {
    __block NSString *dialogId;
    [self dataBaseOperation:^(ACFMDatabase* db){
        NSString *sql = @"SELECT dialogId FROM ACMsgIdMap WHERE msgId=? LIMIT 1";
        ACFMResultSet *result = [db executeQuery:sql, @(msgId)];
        while ([result next]) {
            dialogId = [result stringForColumn:@"dialogId"];
        }
        [result close];
    }];
    
    return dialogId;
}

- (NSString *)selectDialogIdWithRemoteId:(long)remoteId {
    __block NSString *dialogId;
    [self dataBaseOperation:^(ACFMDatabase* db){
        NSString *sql = @"SELECT dialogId FROM ACMsgIdMap WHERE remoteId=? LIMIT 1";
        ACFMResultSet *result = [db executeQuery:sql, @(remoteId)];
        while ([result next]) {
            dialogId = [result stringForColumn:@"dialogId"];
        }
        [result close];
    }];
    
    return dialogId;
}

- (long)selectLatestMsgId {
    __block long msgId = 0;
    [self dataBaseOperation:^(ACFMDatabase* db){
        NSString *sql = @"SELECT msgId FROM ACMsgIdMap ORDER BY msgId DESC LIMIT 1";
        ACFMResultSet *result = [db executeQuery:sql];
        while ([result next]) {
            msgId = [result longForColumn:@"msgId"];
        }
        [result close];
    }];
    
    return msgId;
}

- (long)selectOldestMsgId {
    __block long msgId = 0;
    [self dataBaseOperation:^(ACFMDatabase* db){
        NSString *sql = @"SELECT msgId FROM ACMsgIdMap ORDER BY msgId ASC LIMIT 1";
        ACFMResultSet *result = [db executeQuery:sql];
        while ([result next]) {
            msgId = [result longForColumn:@"msgId"];
        }
        [result close];
    }];
    
    return msgId;
}

- (void)deleteMsgIdMap:(long)msgId withDb:(ACFMDatabase *)db {
    NSString* sql = @"DELETE FROM ACMsgIdMap WHERE msgId=?";
    [db executeUpdate:sql,@(msgId)];
}


- (void)deleteMsgIdForDialog:(NSString *)dialogId withDb:(ACFMDatabase *)db {
    NSString* sql = @"DELETE FROM ACMsgIdMap WHERE dialogId=?";
    [db executeUpdate:sql,dialogId];
}


#pragma mark - Search

- (void)updateSearchIndex:(ACMessageMo *)message withDb:(ACFMDatabase *)db {
    NSString *words = [message searchableWords];
    if (!words.length) return;
    NSString* sql = @"INSERT OR REPLACE INTO ACSearchIndex(msgId,dialogId,messageType,msgSendTime,words) VALUES (?,?,?,?,?)";
    [db executeUpdate:sql,
     @(message.Property_ACMessage_msgId),
     message.Property_ACMessage_dialogIdStr,
     [message messageType],
     @(message.Property_ACMessage_msgSendTime),
     words];
    
}

- (NSArray *)selectMsgIdsWithKeyword:(NSString *)keyword dialogId:(NSString *)dialogId count:(int)count recordTime:(double)recordTime withDb:(ACFMDatabase *)db {
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    ACFMResultSet *set;
    if (recordTime > 0) {
        NSString *sql = [NSString stringWithFormat:@"SELECT msgId FROM ACSearchIndex WHERE dialogId=? AND msgSendTime < ? AND words LIKE '%%%@%%' ORDER BY msgSendTime DESC LIMIT ?", keyword];
        set = [db executeQuery:sql,dialogId,recordTime,keyword,count];
    } else {
        NSString *sql = [NSString stringWithFormat:@"SELECT msgId FROM ACSearchIndex WHERE dialogId=? AND words LIKE '%%%@%%' ORDER BY msgSendTime DESC LIMIT ?", keyword];
        set = [db executeQuery:sql,dialogId,keyword,count];
    }
    
    while ([set next]) {
        [arr addObject:@([set longForColumn:@"msgId"])];
    }
    [set close];
    return arr;
}

- (void)deleteSearchIndex:(long)msgId withDb:(ACFMDatabase *)db {
    NSString* sql = @"DELETE FROM ACSearchIndex WHERE msgId=?";
    [db executeUpdate:sql,@(msgId)];
}


- (void)deleteSearchForDialog:(NSString *)dialogId withDb:(ACFMDatabase *)db {
    NSString* sql = @"DELETE FROM ACSearchIndex WHERE dialogId=?";
    [db executeUpdate:sql,dialogId];
}


#pragma mark - SuperDialogRecordTime

- (void)updateSgLastRecordTime:(NSString *)dialogId time:(long)time {
    [self dataBaseOperation:^(ACFMDatabase *db) {
        long storageVal = 0;
        NSString *sql = @"SELECT lastMsgTime FROM ACSuperDialogRecordTime WHERE dialogId=? LIMIT 1";
        ACFMResultSet *result = [db executeQuery:sql, dialogId];
        while ([result next]) {
            storageVal = [result longForColumn:@"lastMsgTime"];
        }
        [result close];
 
        
        if (storageVal < time) {
            NSString* sql = @"INSERT OR REPLACE INTO ACSuperDialogRecordTime(dialogId, lastMsgTime) VALUES (?,?)";
            [db executeUpdate:sql,
             dialogId,
             @(time)];
        }
    }];
}


- (NSDictionary *)selectLastReceiveRecordTimeMap:(NSArray *)dialogIds  {
    if (!dialogIds.count) return nil;
    
    NSMutableDictionary *retVal = [NSMutableDictionary dictionary];
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSMutableString *placeHolder = [NSMutableString stringWithString: @"?"];
        for (int i = 1; i < dialogIds.count; i++) {
            [placeHolder appendString:@",?"];
        }
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM ACSuperDialogRecordTime WHERE dialogId IN (%@)", placeHolder];
        ACFMResultSet *result = [db executeQuery:sql withArgumentsInArray:dialogIds];;
        while ([result next]) {
            NSString *dialogId = [result stringForColumn:@"dialogId"];
            long time = [result longForColumn:@"lastMsgTime"];
            [retVal setObject:@(time) forKey:dialogId];
        }
        [result close];
        
    }];
    return retVal;
}

- (long)selectSgLatestRecordTime {
    __block long retVal = 0;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString *sql = @"SELECT lastMsgTime FROM ACSuperDialogRecordTime ORDER BY lastMsgTime DESC LIMIT 1";
        ACFMResultSet *result = [db executeQuery:sql];
        while ([result next]) {
            retVal = [result longForColumn:@"lastMsgTime"];
        }
        [result close];
        
    }];
    return retVal;
}

- (BOOL)hasAddDefaultMissingMsgInvtervalForDialog:(NSString *)dialogId {
    __block BOOL retVal = NO;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString *sql = @"SELECT flag FROM ACDialogAddDefaultIntervalFlag WHERE dialogId = ? LIMIT 1";
        ACFMResultSet *result = [db executeQuery:sql, dialogId];
        while ([result next]) {
            retVal = [result boolForColumn:@"flag"];
        }
        [result close];
        
    }];
    return retVal;
}

- (void)setAddedDefaultMissingMsgInvtervalForDialog:(NSString *)dialogId val:(BOOL)val {
    [self dataBaseOperation:^(ACFMDatabase *db) {
        
        [self setAddedDefaultMissingMsgInvtervalForDialog:dialogId val:val withDb:db];
    }];
}

- (void)setAddedDefaultMissingMsgInvtervalForDialog:(NSString *)dialogId val:(BOOL)val withDb:(ACFMDatabase *)db {
    
    NSString* sql = @"INSERT OR REPLACE INTO ACDialogAddDefaultIntervalFlag(dialogId, flag) VALUES (?,?)";
    [db executeUpdate:sql,
     dialogId,
     @(val)];
}


#pragma mark - MissingMsgInterval

- (ACMissingMsgsInterval *)selectMissingMsgsIntervalForDialog:(NSString *)dialogId recordTime:(long)time {
    __block ACMissingMsgsInterval *retVal;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        
        NSString* sql = @"SELECT * FROM ACMissingMsgInterval WHERE dialogId = ? AND left < ? AND right > ? LIMIT 1";
        ACFMResultSet *result = [db executeQuery:sql,dialogId, @(time), @(time)];
        
        while ([result next]) {
            retVal = [[ACMissingMsgsInterval alloc] initWithLeft:[result longForColumn:@"left"] right:[result longForColumn:@"right"]];
            break;
        }
        [result close];
    }];
    return retVal;
}

- (ACMissingMsgsInterval *)selectFloorMissingMsgsIntervalForDialog:(NSString *)dialogId recordTime:(long)time {
    __block ACMissingMsgsInterval *retVal;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        ACFMResultSet *result;
        if (time > 0) {
            NSString* sql = @"SELECT * FROM ACMissingMsgInterval WHERE dialogId = ? AND right <= ? ORDER BY right DESC LIMIT 1";
            result = [db executeQuery:sql,dialogId, @(time)];
        } else {
            NSString* sql = @"SELECT * FROM ACMissingMsgInterval WHERE dialogId = ? ORDER BY right DESC LIMIT 1";
            result = [db executeQuery:sql,dialogId, @(time)];
        }
        
        while ([result next]) {
            retVal = [[ACMissingMsgsInterval alloc] initWithLeft:[result longForColumn:@"left"] right:[result longForColumn:@"right"]];
            break;
        }
        [result close];
    }];
    return retVal;
}

- (ACMissingMsgsInterval *)selectCeilMissingMsgsIntervalForDialog:(NSString *)dialogId recordTime:(long)time {
    __block ACMissingMsgsInterval *retVal;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString* sql = @"SELECT * FROM ACMissingMsgInterval WHERE dialogId = ? AND left >= ? ORDER BY left ASC LIMIT 1";
        ACFMResultSet *result = [db executeQuery:sql,dialogId, @(time)];
        
        while ([result next]) {
            retVal = [[ACMissingMsgsInterval alloc] initWithLeft:[result longForColumn:@"left"] right:[result longForColumn:@"right"]];
            break;
        }
        [result close];
    }];
    return retVal;
}

- (void)updateMissingMsgsIntervalForDialog:(NSString *)dialogId interval:(ACMissingMsgsInterval *)interval {
    if (interval.left >= interval.right) return;
    
    [self.queue inTransaction:^(ACFMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        NSString *selectSql = @"SELECT * FROM ACMissingMsgInterval WHERE dialogId = ? AND right = ? OR left = ? LIMIT 1";
        ACFMResultSet *result = [db executeQuery:selectSql,dialogId, @(interval.right),@(interval.left)];
       ACMissingMsgsInterval *localInterval;
        while ([result next]) {
            localInterval = [[ACMissingMsgsInterval alloc] initWithLeft:[result longForColumn:@"left"] right:[result longForColumn:@"right"]];
            break;
        }
        [result close];
        
        if (localInterval && (interval.right - interval.left) < (localInterval.right - localInterval.left)) {
            NSString *sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO ACMissingMsgInterval(dialogId,left,right) VALUES (?,?,?)"];
            [db executeUpdate:sql,
             dialogId,
             @(interval.left),
             @(interval.right)];
        }
    }];
}


- (void)addMissingMsgsIntervalForDialog:(NSString *)dialogId interval:(ACMissingMsgsInterval *)interval {
    [self dataBaseOperation:^(ACFMDatabase *db) {
        [self addMissingMsgsIntervalForDialog:dialogId interval:interval withDb:db];
    }];
    
}


- (void)addMissingMsgsIntervalForDialog:(NSString *)dialogId interval:(ACMissingMsgsInterval *)interval withDb:(ACFMDatabase *)db {
    if (interval.right - interval.left <= 1) return;
    NSString* delSql = @"DELETE FROM ACMissingMsgInterval WHERE dialogId=? AND left >= ? AND right <= ?";
    [db executeUpdate:delSql,dialogId, @(interval.left), @(interval.right)];
    
    NSString* sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO ACMissingMsgInterval(dialogId,left,right) VALUES (?,?,?)"];
    [db executeUpdate:sql,
     dialogId,
     @(interval.left),
     @(interval.right)];
}


- (void)deleteMissingMsgsIntervalForDialog:(NSString *)dialogId pulledMsgInterval:(ACMissingMsgsInterval *)pulledMsgInterval {
    if (!pulledMsgInterval) return;
    // 转为开区间
    pulledMsgInterval = [pulledMsgInterval copy];
    pulledMsgInterval.left -= 1;
    pulledMsgInterval.right += 1;

  
    // 删除 已加载的区间 (pulledMsgInterval.left, pulledMsgInterval.right) 缺失区间 (ACMissingMsgInterval.left, ACMissingMsgInterval.right) 的交集
    
    [self.queue inTransaction:^(ACFMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        // 1. 查找交集
        NSString *selectSql = @"SELECT * FROM ACMissingMsgInterval WHERE dialogId=? AND left <= ? AND right >= ?";
        ACFMResultSet *result = [db executeQuery:selectSql,dialogId, @(pulledMsgInterval.right),@(pulledMsgInterval.left)];
        
        NSMutableArray *contentArr = [NSMutableArray array];
        while ([result next]) {
            ACMissingMsgsInterval *tmp = [[ACMissingMsgsInterval alloc] initWithLeft:[result longForColumn:@"left"] right:[result longForColumn:@"right"]];
            [contentArr addObject:tmp];
        }
        [result close];

        for (ACMissingMsgsInterval *item in contentArr) {
            
            // 2.删除item
            NSString* delSql = @"DELETE FROM ACMissingMsgInterval WHERE dialogId=? AND left = ? AND right = ?";
            [db executeUpdate:delSql,dialogId, @(item.left), @(item.right)];
            
            // 3.添加不相交的区间
            if (item.left >= pulledMsgInterval.left && item.right <= pulledMsgInterval.right) {
                // item ⊆ pulledMsgInterval
            }
            else  {
                // item被分割成两个区间 (item.left, pulledMsgInterval.left+1) (pulledMsgInterval.right-1, item.right)
                NSString* delSql = @"DELETE FROM ACMissingMsgInterval WHERE dialogId=? AND left = ? AND right = ?";
                [db executeUpdate:delSql,dialogId, @(item.left), @(item.right)];
                ACMissingMsgsInterval *add1 = [[ACMissingMsgsInterval alloc] initWithLeft:item.left right:pulledMsgInterval.left+1];
                ACMissingMsgsInterval *add2 = [[ACMissingMsgsInterval alloc] initWithLeft:pulledMsgInterval.right-1 right:item.right];
                if (add1.right - add1.left > 1) {
                    [self addMissingMsgsIntervalForDialog:dialogId interval:add1 withDb:db];
                }
                if (add2.right - add2.left > 1) {
                    [self addMissingMsgsIntervalForDialog:dialogId interval:add2 withDb:db];
                }
                
            }
        }
    }];
}

- (void)deleteAllMissingMsgsIntervalForDialog:(NSString *)dialogId withDb:(ACFMDatabase *)db {
    NSString* sql = @"DELETE FROM ACMissingMsgInterval WHERE dialogId=?";
    [db executeUpdate:sql,dialogId];
}


#pragma mark - ACDialogSecretKey

- (void)updateDialogSecretKeyForDialog:(NSString *)dialogId secretKey:(ACDialogSecretKeyMo *)secretKey {
    [self dataBaseOperation:^(ACFMDatabase *db) {
        
        NSString *sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO ACDialogSecretKey(dialogId,key,iv) VALUES (?,?,?)"];
        [db executeUpdate:sql,
         dialogId,
         secretKey.aesKey,
         secretKey.aesIv];
    }];
}

- (ACDialogSecretKeyMo *)selectDialogSecretKeyDialog:(NSString *)dialogId {
    __block ACDialogSecretKeyMo *retVal;
    [self dataBaseOperation:^(ACFMDatabase *db) {
        retVal = [self selectDialogSecretKeyDialog:dialogId withDb:db];
    }];
    return retVal;
}

- (ACDialogSecretKeyMo *)selectDialogSecretKeyDialog:(NSString *)dialogId withDb:(ACFMDatabase *)db {
    ACDialogSecretKeyMo *retVal;
    NSString* sql = @"SELECT * FROM ACDialogSecretKey WHERE dialogId = ? LIMIT 1";
    ACFMResultSet *result = [db executeQuery:sql,dialogId];
    
    while ([result next]) {
        retVal = [ACDialogSecretKeyMo new];
        retVal.aesKey = [result stringForColumn:@"key"];
        retVal.aesIv = [result stringForColumn:@"iv"];
        break;
    }
    [result close];
    return retVal;
}

- (NSArray *)selectLoadedSecretKeyDialogIds {
    NSMutableArray *retVal = [NSMutableArray array];
    [self dataBaseOperation:^(ACFMDatabase *db) {
        NSString* sql = @"SELECT dialogId FROM ACDialogSecretKey";
        ACFMResultSet *result = [db executeQuery:sql];
        while ([result next]) {
            [retVal addObject:[result stringForColumn:@"dialogId"]];
        }
        [result close];
    }];

    return retVal.copy;
}

- (void)resetSgMessage:(NSError *)error {
    if (error.code == 11) {
    // [self reSetDb];
    } else if (error.code == 13) {
    }
}


//重置数据库
- (void)reSetDb {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.dbPath error:&error];
    self.queue = nil;
    //重新创建数据库
    [self initDataBase];
}


@end
