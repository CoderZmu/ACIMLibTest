//
//  ACUploadResponseCache.m
//  ACIMLib
//
//  Created by 子木 on 2022/9/9.
//

#import <UIKit/UIKit.h>
#import "ACFMDB.h"
#import "ACUploadResponseCache.h"

static const NSInteger kMaxCacheAge = 60 * 60 * 24 * 2;

@interface ACUploadResponseCache()
@property(nonatomic,strong) ACFMDatabaseQueue *dbQueue;
@end

@implementation ACUploadResponseCache

+ (ACUploadResponseCache *)shared {
    static ACUploadResponseCache *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ACUploadResponseCache alloc] init];
    });
    return instance;
}


- (instancetype)init {
    self = [super init];
    [self initDatabase];
    [self cleanDisk];
    return self;
}

- (void)setResponse:(NSString *)response forKey:(NSString *)key {
    if (!key || !response) return;
    
    int timestamp = (int)time(NULL);
    [self.dbQueue inDatabase:^(ACFMDatabase * _Nonnull db) {
        NSString* sql = @"INSERT OR REPLACE INTO Manifest(key,content,createTime) VALUES (?,?,?)";
        [db executeUpdate:sql, key, response, @(timestamp)];
    }];
}

- (NSString *)resonseForKey:(NSString *)key {
    if (!key) return nil;
    __block NSString *content;
    [self.dbQueue inDatabase:^(ACFMDatabase * _Nonnull db) {
        NSString *sql = @"SELECT content FROM Manifest WHERE key = ? LIMIT 1";
        ACFMResultSet *set = [db executeQuery:sql, key];
        while ([set next]) {
            
            content = [set stringForColumn:@"content"];
        }
        [set close];
    }];
    return content;
}

- (void)cleanDisk {
    long timestamp = time(NULL);
    if (timestamp <= kMaxCacheAge) return;
    long age = timestamp - kMaxCacheAge;
    if (age >= INT_MAX) return;
    [self deleteItemsWithTimeEarlierThan:(int)age];
}

- (void)deleteItemsWithTimeEarlierThan:(int)time {
    [self.dbQueue inDatabase:^(ACFMDatabase * _Nonnull db) {
        NSString *sql = @"DELETE FROM Manifest WHERE createTime < ?";
        [db executeUpdate:sql, @(time)];
    }];
    
}

- (void)initDatabase {
    NSString *dbPath = [self databasePathWithName:@"Manifest"];
    if (dbPath) {
        _dbQueue = [ACFMDatabaseQueue databaseQueueWithPath:dbPath];
        [_dbQueue inDatabase:^(ACFMDatabase * _Nonnull db) {
            NSString* sql = @"CREATE TABLE IF NOT EXISTS Manifest(key TEXT, content TEXT,createTime INTEGER, PRIMARY KEY(key))";
            
            if ([db executeUpdate:sql]) {
                [db executeUpdate:@"CREATE INDEX IF NOT EXISTS createTime_index on Manifest(createTime)"];
            };
         
        }];
    }
}


- (NSString*)databasePathWithName:(NSString*)dbName {
    if (!dbName) {
        return nil;
    }
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dbPathDir = [cacheFolder stringByAppendingPathComponent:@"ACResponse"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isFileExists = [fileManager fileExistsAtPath:dbPathDir isDirectory:&isDir];
    if (isFileExists) {
        if (isDir) {
            return [dbPathDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.db",dbName]];
        }
        NSError *error = nil;
        BOOL result =  [fileManager removeItemAtPath:dbPathDir error:&error];
        if (result) {
            NSError *error = nil;
            if ([fileManager createDirectoryAtPath:dbPathDir withIntermediateDirectories:YES attributes:nil error:&error]) {
                if (!error) {
                    return  [dbPathDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.db",dbName]];
                }
            }
        }
        return nil;
    }
    else {
        NSError *error = nil;
        if ([fileManager createDirectoryAtPath:dbPathDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            if (!error) {
                return  [dbPathDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.db",dbName]];
            }
        }
    }
    return nil;
}

@end
