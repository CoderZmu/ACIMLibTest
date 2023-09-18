//
//  ACLogger.h
//  ACConnection
//
//  Created by 子木 on 2022/6/9.
//

#import <Foundation/Foundation.h>
#import "ACStatusDefine.h"

NS_ASSUME_NONNULL_BEGIN

#define ACLog(format, ...) [ACLogger info: format, ##__VA_ARGS__];

@interface ACLogger : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (void)debug:(NSString *)format,...;
+ (void)info:(NSString *)format,...;
+ (void)warn:(NSString *)format,...;
+ (void)error:(NSString *)format,...;
+ (void)setLogLevel:(ACLogLevel)logLevel;
+ (NSArray<NSString *> *)getLogFilePaths;
+ (void)cleanLogFiles;
@end

NS_ASSUME_NONNULL_END
