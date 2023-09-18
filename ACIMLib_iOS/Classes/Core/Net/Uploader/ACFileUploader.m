//
//  ACUploader.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/27.
//

#import "ACFileUploader.h"
#import "ACStoreMacro.h"
#import "ACBase.h"
#import "ACIMConfig.h"
#import "ACUploadResponseCache.h"
#import "ACAccountManager.h"
#import "ACOssManager.h"
#import "ACFileEncrypter.h"

static NSString * const kSecretKey = @"v6JUJ95SHoDCs5n9";

@implementation ACFileUploader

+ (id<ACOssCancellableTask>)uploadSingleFile:(NSString *)filePath progress:(nullable void (^)(int progress))uploadProgress
                complete:(ACUploadCompleteBlock)completeBlock {
    
    NSData *uploadFileData = [NSData dataWithContentsOfFile:filePath];
    if (!uploadFileData) {
        completeBlock(NO, nil, nil);
        return nil;
    }
    
    
    NSString *cachedKey = [self cachedKeyForUploadData:uploadFileData];
    NSDictionary *cachedResponse = [self getCachedResponseForKey:cachedKey];
    
    if (cachedResponse) {
        completeBlock(YES, cachedResponse[@"remotePath"], cachedResponse[@"encryptKey"]);
        return nil;
    };
    
    NSString *type = [filePath pathExtension];
    if (!type.length) {
        type = [uploadFileData ac_imageType];
    }
    NSString *remotePath = [[ACOssManager shareInstance] generateObjectKeyWithExt:type];
    NSString *encryptKey = [self generateFileEncryptKey];
    NSData *uploadedData = [ACFileEncrypter isaac_encrypt:[NSData dataWithContentsOfFile:filePath] withKey:encryptKey];
    
    return [[ACOssManager shareInstance] uploadFile:remotePath fileData:uploadedData progress:^(NSProgress * _Nonnull progress) {
        !uploadProgress ?: uploadProgress((int)(progress.fractionCompleted * 100));
        } completed:^(NSError * _Nullable error) {
            if (error) {
                completeBlock(NO, nil, nil);
                return;
            }
            [self saveCacheResponse:remotePath encryptKey:encryptKey forKey:cachedKey];
            completeBlock(YES,remotePath,encryptKey);
        }];
}

+ (NSString *)generateFileEncryptKey {
    
    char data[16];
    for (int x=0;x<16;data[x++] = (char)('A' + (arc4random_uniform(26))));
    NSString *key = [[NSString alloc] initWithBytes:data length:16 encoding:NSUTF8StringEncoding];
    return [key ac_md5String];
    
}

+ (NSString *)cachedKeyForUploadData:(NSData *)data {
//    NSMutableData *requestData = [[[NSString stringWithFormat:@"Host: %@", url] dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
//    [requestData appendData:data];
    return [data ac_md5String];
}

+ (NSDictionary *)getCachedResponseForKey:(NSString *)key {
    NSString *encryptedText = [[ACUploadResponseCache shared] resonseForKey:key];
    if (encryptedText) {
        NSString *clearText = [encryptedText ac_aes128_decrypt:kSecretKey];
        NSDictionary *jsonValue = [clearText ac_jsonValueDecoded];
        return jsonValue;
    }
    return nil;
}

+ (void)saveCacheResponse:(NSString *)remotePath encryptKey:(NSString *)encryptKey forKey:(NSString *)key {
    NSDictionary *d = @{ @"remotePath": remotePath, @"encryptKey": encryptKey  };
    NSString *encryptedText = [[NSString ac_jsonStringWithJsonObject:d] ac_aes128_encrypt:kSecretKey];
    [[ACUploadResponseCache shared] setResponse:encryptedText forKey:key];
}

@end
