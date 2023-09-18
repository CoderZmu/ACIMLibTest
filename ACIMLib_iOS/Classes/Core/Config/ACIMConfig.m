//
//  ACIMConfig.m
//  ACIMLib
//
//  Created by 子木 on 2022/7/4.
//

#import "ACIMConfig.h"

static NSString *__token = @"";
static NSString *__uploadUrl = @"";
static NSString *__downloadUrl = @"";
static NSString *__cert = @"";
static NSString *__logReportUrl = @"";
static NSString * const kUploadUrlStoreKey = @"kACUploadUrlStoreKey";
static NSString * const kDownloadUrlStoreKey = @"kACDownloadUrlStoreKey";
static NSString * const kCertStoreKey = @"kACCertStoreKey";
static NSString * const kLogReportUrlStoreKey = @"kACLogReportUrlStoreKey";

@implementation ACIMConfig

+ (void)initialize {
    __uploadUrl = [[NSUserDefaults standardUserDefaults] objectForKey:kUploadUrlStoreKey];
    __downloadUrl = [[NSUserDefaults standardUserDefaults] objectForKey:kDownloadUrlStoreKey];
    __cert = [[NSUserDefaults standardUserDefaults] objectForKey:kCertStoreKey];
    __logReportUrl = [[NSUserDefaults standardUserDefaults] objectForKey:kLogReportUrlStoreKey];
}

+ (NSString *)getSDKInitToken {
    return __token;
}

+ (NSString *)getFileUploadURLString {
    return __uploadUrl;
}

+ (NSString *)getFileDownloadURLString {
    return __downloadUrl;
}

+ (NSString *)getFileUploadCert {
    return __cert;
}

+ (NSString *)getLogReportUrl {
    return __logReportUrl;
}

+ (void)setSDKInitToken:(NSString *)token {
    __token = token;
}

+ (void)setFileUploadUrl:(NSString *)uploadUrl andDownLoadUrl:(NSString *)downloadUrl cert:(NSString *)cert {
    __uploadUrl = uploadUrl;
    __downloadUrl = downloadUrl;
    __cert = cert;
    if (uploadUrl.length)
        [[NSUserDefaults standardUserDefaults] setObject:uploadUrl forKey:kUploadUrlStoreKey];
    
    if (downloadUrl.length)
        [[NSUserDefaults standardUserDefaults] setObject:downloadUrl forKey:kDownloadUrlStoreKey];
    
    if (__cert.length)
        [[NSUserDefaults standardUserDefaults] setObject:cert forKey:kCertStoreKey];
}

+ (void)setLogReportUrl:(NSString *)logReportUrl {
    __logReportUrl = logReportUrl;
    if (logReportUrl) {
        [[NSUserDefaults standardUserDefaults] setObject:logReportUrl forKey:kLogReportUrlStoreKey];
    }
}

@end
