//
//  ACAliYunStorage.m
//  Sugram
//
//  Created by 子木 on 2023/1/3.
//  Copyright © 2023 Sugram. All rights reserved.
//


#import "ACAliYunOss.h"
#import <AliyunOssiOS/AliyunOssiOS.h>
#import "ACOssConfig.h"

static NSString * const ACAliyunOssErrorDomain = @"ac.aliyun.oss.error";

@interface OSSPutObjectRequest (ACCancellable)<ACOssCancellableTask>
@end
@implementation OSSPutObjectRequest (ACCancellable)
- (void)ac_cancel {
    [self cancel];
}
@end

@interface OSSGetObjectRequest (ACCancellable)<ACOssCancellableTask>
@end
@implementation OSSGetObjectRequest (ACCancellable)
- (void)ac_cancel {
    [self cancel];
}
@end


@interface ACAliYunOss()

@property (nonatomic, strong) OSSClient *client;

@property (nonatomic,strong) ACOssConfig *ossInfo;

@end

@implementation ACAliYunOss

- (instancetype)init {
    self = [super init];

    return self;
}

- (void)configurate:(ACOssConfig *)mo {
    if ([mo isEqual:_ossInfo]) return;
    _ossInfo = mo;
    
    id <OSSCredentialProvider> credential = [[OSSPlainTextAKSKPairCredentialProvider alloc] initWithPlainTextAccessKey:_ossInfo.accessKey secretKey:_ossInfo.secretKey];
    OSSClientConfiguration * configuration = [[OSSClientConfiguration alloc] init];
    configuration.maxRetryCount = 3; // 网络请求遇到异常失败后的重试次数
    configuration.timeoutIntervalForRequest = 60; // 网络请求的超时时间
    configuration.timeoutIntervalForResource = 24 * 60 * 60;    // 允许资源传输的最长时间
    configuration.maxConcurrentRequestCount = 1;    // 最大并发数
    _client = [[OSSClient alloc] initWithEndpoint:_ossInfo.endPoint credentialProvider:credential clientConfiguration:configuration];
}


- (id<ACOssCancellableTask>)uploadFile:(NSString *)key fileData:(NSData *)fileData  progress:(nullable ACOssUploadProgressBlock)progressBlock completed:(nullable ACOssUploadCompletedBlock)completedBlock {

    OSSPutObjectRequest * put = [OSSPutObjectRequest new];

    put.bucketName = _ossInfo.chatBucket;
    put.objectKey = key;
    put.uploadingData = fileData;


    put.uploadProgress = progressBlock ? ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        NSProgress *progress = [NSProgress progressWithTotalUnitCount:totalBytesExpectedToSend];
        progress.completedUnitCount = totalByteSent;
        progressBlock(progress);
    } : nil;
    
    OSSTask *putTask = [self.client putObject:put];
    [putTask continueWithBlock:^id(OSSTask *task) {
        !completedBlock ?: completedBlock([self customizedOssErrorFromAliyunOSSClientError:task.error]);
        return nil;
    }];
    
    return put;
  
}

- (id<ACOssCancellableTask>)downloadFile:(nonnull NSString *)key progress:(nullable ACOssDownloadProgressBlock)progressBlock completed:(nullable ACOssDownloadCompletedBlock)completedBlock {
   
    OSSGetObjectRequest * request = [OSSGetObjectRequest new];

    request.bucketName = _ossInfo.chatBucket;
    request.objectKey = key;


    request.downloadProgress = progressBlock ? ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSProgress *progress = [NSProgress progressWithTotalUnitCount:totalBytesExpectedToWrite];
        progress.completedUnitCount = totalBytesWritten;
        progressBlock(progress);
    } : nil;
    OSSTask * getTask = [self.client getObject:request];
    
    [getTask continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            OSSGetObjectResult * getResult = task.result;
            !completedBlock ?: completedBlock(getResult.downloadedData, nil);
        } else {
            !completedBlock ?: completedBlock(nil, [self customizedOssErrorFromAliyunOSSClientError:task.error]);
        }
        
        return nil;
    }];

    return request;
}

- (void)copyObjects:(nonnull NSArray<ACOssCopyObjectMeta *> *)objectMetaArray completed:(nullable ACOssCopyObjectsCompletedBlock)completedBlock {
  
    if (!objectMetaArray.count) {
        !completedBlock ?: completedBlock(YES);
        return;
    }
    
    __block BOOL success = NO;
    dispatch_group_t group = dispatch_group_create();
    
    for (ACOssCopyObjectMeta *meta in objectMetaArray) {
        
        dispatch_group_enter(group);
        
        OSSCopyObjectRequest *request = [[OSSCopyObjectRequest alloc] init];
        request.bucketName =  _ossInfo.chatBucket;;
        request.objectKey = meta.destKey;
        request.sourceBucketName =  _ossInfo.chatBucket;
        request.sourceObjectKey = meta.sourceKey;
        
        [self.client copyObject:request];
        OSSTask *cloneTask = [self.client copyObject:request];

        [cloneTask continueWithBlock:^id _Nullable(OSSTask * _Nonnull task) {
            // 存在一个对象拷贝成功则算成功
            if (!success && !task.error) success = YES;
            dispatch_group_leave(group);
            
            return nil;
        }];
        
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        !completedBlock ?: completedBlock(success);
    });
}


- (void)doesObjectExist:(NSString *)key completed:(nonnull ACOssQueryObjectCompletedBlock)completedBlock {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        completedBlock([self.client doesObjectExistInBucket:self.ossInfo.chatBucket objectKey:key error:nil]);
    });
}


- (NSError *)customizedOssErrorFromAliyunOSSClientError:(NSError *)originalError {
    if (!originalError) return nil;
    
    ACOssErrorCODE code = ACOssErrorCODE_Unknown;
    if ([originalError.domain isEqualToString:OSSClientErrorDomain]) {
        
        switch (originalError.code) {
            case OSSClientErrorCodeNetworkingFailWithResponseCode0:
            case OSSClientErrorCodeNetworkError:
                code = ACOssErrorCODE_NetworkError;
                break;
            case OSSClientErrorCodeSignFailed:
                code = ACOssErrorCODE_SignFailed;
                break;
                
            case OSSClientErrorCodeNilUploadid:
            case OSSClientErrorCodeInvalidArgument:
                code = ACOssErrorCODE_InvalidArgument;
                break;
                
            case OSSClientErrorCodeFileCantWrite:
            case OSSClientErrorCodeFileCantRead:
                code = ACOssErrorCODE_AccessDenied;
                break;
                
            case OSSClientErrorCodeTaskCancelled:
                code = ACOssErrorCODE_TaskCancelled;
                break;
                
            default:
                break;
        }
        
    } else if ([originalError.domain isEqualToString:OSSServerErrorDomain]) {
        if (originalError.code == -404) {
            code = ACOssErrorCODE_NotExist;
        }
    }
    return [NSError errorWithDomain:ACAliyunOssErrorDomain code:code userInfo:nil];
}

@end
