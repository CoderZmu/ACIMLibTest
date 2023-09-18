//
//  ACDatabase+Request.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/22.
//

#import "ACFMDB.h"
#import "ACDatabase+RetriedPacket.h"

NSString *ACCreateRequestTable(void)
{
    return @"CREATE TABLE IF NOT EXISTS ACPacket ( \
    uuid TEXT PRIMARY KEY , \
    url INTEGER, \
    data BLOB, \
    times INTEGER)";
}

@implementation ACDatabase (RetriedPacket)

- (void)addPacket:(int32_t)url data:(NSData *)data uuid:(NSString *)uuid {
    [self dataBaseOperation:^(ACFMDatabase *db) {
        if ([db executeUpdate:ACCreateRequestTable()]) {
            NSString *sql = @"INSERT INTO ACPacket (uuid, url, data, times) VALUES (?, ?,?,?)";
            [db executeUpdate:sql,
             uuid,
             @(url),
             data,
             @1];
        }
    }];
}

- (void)increasePacketRetryTimes:(NSString *)uuid {
    [self dataBaseOperation:^(ACFMDatabase *db) {
        if ([db tableExists:@"ACPacket"]) {
            NSString *sql = @"UPDATE ACPacket SET times = times + 1 WHERE uuid = ?";
            [db executeUpdate:sql, uuid];
        }
    }];
}

- (void)deletePacket:(NSString *)uuid {
    [self dataBaseOperation:^(ACFMDatabase *db) {
        if ([db tableExists:@"ACPacket"]) {
            NSString *sql = @"DELETE FROM ACPacket WHERE uuid = ?";
            [db executeUpdate:sql, uuid];
        }
    }];
}

- (NSMutableArray<ACRetriedPacketMo *> *)selectAllPackets {
    NSMutableArray *arr = [NSMutableArray array];
    [self dataBaseOperation:^(ACFMDatabase *db) {
        if ([db tableExists:@"ACPacket"]) {
            NSString *sql = @"SELECT * FROM ACPacket";
            ACFMResultSet *rs = [db executeQuery:sql];
            
            while (rs && [rs next]) {
                ACRetriedPacketMo *mo = [[ACRetriedPacketMo alloc] init];
                mo.uuid = [rs stringForColumn:@"uuid"];
                mo.url = (int32_t)[rs longForColumn:@"url"];
                mo.data = [rs dataForColumn:@"data"];
                mo.times = [rs intForColumn:@"times"];
                [arr addObject:mo];
            }
            [rs close];
        }
    }];
    
    return arr.copy;
}

@end
