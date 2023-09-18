//
//  ACReportLog.m
//  ACIMLib
//
//  Created by 子木 on 2023/2/28.
//

#import "ACReportLog.h"
//#import "ZipArchive.h"
#import "ACAFNetworking.h"
#import "ACIMConfig.h"
#import "ACLogger.h"
#import "ACFileUploader.h"
#import "ACAccountManager.h"
#import "ACServerTime.h"
#import "ACBase.h"



static NSString * const PWD = @"pQYASVN9dsjl3FKq";
static NSString * const LastReportTimeStorageKey = @"ACLastReportTime";
static BOOL __isReporting = NO;

@implementation ACReportLog

+ (void)report {
    
    dispatch_async([self serialQueue], ^{
        if (__isReporting) return;
        double lastTime = [[NSUserDefaults standardUserDefaults] doubleForKey:LastReportTimeStorageKey];
        if (lastTime && ([NSDate date].timeIntervalSince1970 - lastTime) < 0.5 * 60 * 60) {
            return;
        }
        
        NSString *URL = [ACIMConfig getLogReportUrl];
        if (!URL.length) return;
        
        NSArray<NSString *> *logFilePaths = [ACLogger getLogFilePaths];
        if (!logFilePaths.count) return;
        
        
        NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",[[NSUUID UUID] UUIDString]]];
//        BOOL zipResult = [SSZipArchive createZipFileAtPath:tempPath withFilesAtPaths:logFilePaths withPassword:PWD];
//        if (!zipResult) return;
        return;
        
        __isReporting = YES;
        [ACFileUploader uploadSingleFile:tempPath progress:nil complete:^(BOOL success, NSString * _Nonnull path, NSString *encryptKey) {
            if (!success) {
                dispatch_async([self serialQueue], ^{
                    __isReporting = NO;
                });
                return;
            }
            
            [[ACAFHTTPSessionManager manager] POST:URL parameters:@{
                @"deviceId": @2,
                @"param":@{@"encryptKey": encryptKey, @"ossKey": path},
                @"userId": @([ACAccountManager shared].user.Property_SGUser_uin)
            } headers:@{
                @"token": [[[ACAccountManager shared].user.Property_SGUser_token stringByAppendingFormat:@"-%ld",[ACServerTime getServerMSTime]] ac_base64EncodedString]
            } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                dispatch_async([self serialQueue], ^{
                    if (responseObject[@"code"] && [responseObject[@"code"] intValue] == 200) {
                        // 上传日志成功，清空本地日志
                        [ACLogger cleanLogFiles];
                        [[NSUserDefaults standardUserDefaults] setDouble:[NSDate date].timeIntervalSince1970 forKey:LastReportTimeStorageKey];
                    }
                    __isReporting = NO;
                });
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                dispatch_async([self serialQueue], ^{
                    __isReporting = NO;
                });
            }];
            
            
        }];
        
    });

}

+ (dispatch_queue_t)serialQueue {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.log.report", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}


@end
