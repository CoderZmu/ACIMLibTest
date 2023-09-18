//
//  ACLogger.m
//  ACConnection
//
//  Created by 子木 on 2022/6/9.
//

#import "ACLogger.h"
#import "ACCocoaLumberjack.h"
#import "ACFileManager.h"

static int acddLogLevel = ACDDLogLevelDebug;

@interface ACDDTTYLoggerFormatter : NSObject<ACDDLogFormatter>
{
    NSDateFormatter *_dateFormatter;
}
@end
@implementation ACDDTTYLoggerFormatter

- (instancetype)init {
    self = [super init];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4]; // 10.4+ style
    [_dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [_dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [_dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
    return self;
}
- (NSString *)formatLogMessage:(ACDDLogMessage *)logMessage {
    NSString *dateAndTime = [_dateFormatter stringFromDate:logMessage->_timestamp];
    NSString *levelInfo;
    switch (logMessage -> _flag) {
        case ACDDLogFlagVerbose:
            levelInfo = @"VERBOSE";
            break;
        case ACDDLogFlagDebug:
            levelInfo = @"DEBUG";
            break;
        case ACDDLogFlagInfo:
            levelInfo = @"INFO";
            break;
        case ACDDLogFlagWarning:
            levelInfo = @"INFO";
            break;
        case ACDDLogFlagError:
            levelInfo = @"ERROR";
            break;
        default:
            break;
    }
    return [NSString stringWithFormat:@"%@[ACLog][%@]: %@",dateAndTime, levelInfo, logMessage->_message];
}

@end

@interface ACDDLogFileManagerDefault (Add)

- (void)cleanLogFiles;

@end

@implementation ACDDLogFileManagerDefault (Add)

- (void)cleanLogFiles {

    NSArray *sortedLogFileInfos = [self sortedLogFileInfos];
    NSUInteger firstIndexToDelete = 0;


    if (firstIndexToDelete == 0) {

        if (sortedLogFileInfos.count > 0) {
            ACDDLogFileInfo *logFileInfo = sortedLogFileInfos[0];

            if (!logFileInfo.isArchived) {
                ++firstIndexToDelete;
            }
        }
    }

    if (firstIndexToDelete != NSNotFound) {
        for (NSUInteger i = firstIndexToDelete; i < sortedLogFileInfos.count; i++) {
            ACDDLogFileInfo *logFileInfo = sortedLogFileInfos[i];

            NSError *error = nil;
             [[NSFileManager defaultManager] removeItemAtPath:logFileInfo.filePath error:&error];
            
        }
    }
}

@end

static ACDDFileLogger * __fileLogger;

@implementation ACLogger

+ (void)initialize {
    // 添加DDASLLogger，你的日志语句将被发送到Xcode控制台
    [ACDDTTYLogger sharedInstance].logFormatter = [ACDDTTYLoggerFormatter new];
    [ACDDLog addLogger:[ACDDTTYLogger sharedInstance]];
    
    // 添加DDFileLogger，你的日志语句将写入到一个文件中，默认路径在沙盒的[fileLogger.logFileManager logsDirectory]目录下，文件名为bundleid+空格+日期.log。
    ACDDFileLogger *fileLogger = [[ACDDFileLogger alloc] initWithLogFileManager:[[ACDDLogFileManagerDefault alloc] initWithLogsDirectory:[ACFileManager logsPath]]];
    // 刷新频率为24小时
    fileLogger.rollingFrequency = 60 * 60 * 24;
    // 最多同时包含的文件数量
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    __fileLogger = fileLogger;
    [ACDDLog addLogger:fileLogger];
}

+ (void)debug:(NSString *)format,... {
    va_list L;
    va_start(L, format);
    ACDDLogDebug(@"%@",[[NSString alloc] initWithFormat:format arguments:L]);
    va_end(L);
}
+ (void)info:(NSString *)format,... {
    va_list L;
    va_start(L, format);
    ACDDLogInfo(@"%@",[[NSString alloc] initWithFormat:format arguments:L]);
    va_end(L);
}
+ (void)warn:(NSString *)format, ... {
    va_list L;
    va_start(L, format);
    ACDDLogWarn(@"%@",[[NSString alloc] initWithFormat:format arguments:L]);
    va_end(L);
}
+ (void)error:(NSString *)format,... {
    va_list L;
    va_start(L, format);
    ACDDLogError(@"%@",[[NSString alloc] initWithFormat:format arguments:L]);
    va_end(L);
}

+ (void)setLogLevel:(ACLogLevel)logLevel {
    switch (logLevel) {
        case AC_Log_Level_None:
            acddLogLevel = ACDDLogLevelOff;
            break;
        case AC_Log_Level_Error:
            acddLogLevel = ACDDLogLevelError;
            break;
        case AC_Log_Level_Warn:
            acddLogLevel = ACDDLogLevelWarning;
            break;
        case AC_Log_Level_Info:
            acddLogLevel = ACDDLogLevelInfo;
            break;
        case AC_Log_Level_Debug:
            acddLogLevel = ACDDLogLevelDebug;
            break;
        case AC_Log_Level_Verbose:
            acddLogLevel = ACDDLogLevelVerbose;
            break;
    }
}

+ (NSArray<NSString *> *)getLogFilePaths {
    return [__fileLogger.logFileManager unsortedLogFilePaths];
}

+ (void)cleanLogFiles {
    ACDDLogFileManagerDefault *fileManager = __fileLogger.logFileManager;
    if ([fileManager isKindOfClass:ACDDLogFileManagerDefault.class]) {
        [fileManager cleanLogFiles];
    }
}

@end
