//
//  ACIMConfig.h
//  ACIMLib
//
//  Created by 子木 on 2022/7/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACIMConfig : NSObject

+ (NSString *)getSDKInitToken;

//+ (NSString *)getFileUploadURLString;

//+ (NSString *)getFileDownloadURLString;

+ (NSString *)getFileUploadCert;

+ (NSString *)getLogReportUrl;

+ (void)setSDKInitToken:(NSString *)token;

+ (void)setFileUploadUrl:(NSString *)uploadUrl andDownLoadUrl:(NSString *)downloadUrl cert:(NSString *)cert;

+ (void)setLogReportUrl:(NSString *)logReportUrl;
@end

NS_ASSUME_NONNULL_END
