//
//  ACOssBehavior.h
//  Sugram
//
//  Created by 子木 on 2023/1/3.
//  Copyright © 2023 Sugram. All rights reserved.
//
#import "ACOssCopyObjectMeta.h"
#import "ACOssConfig.h"

#ifndef ACOssBehavior_h
#define ACOssBehavior_h

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACOssUploadProgressBlock)(NSProgress *progress);
typedef void(^ACOssUploadCompletedBlock)(NSError* _Nullable error);

typedef ACOssUploadProgressBlock ACOssDownloadProgressBlock;
typedef void(^ACOssDownloadCompletedBlock)(NSData* _Nullable data ,NSError* _Nullable error);
typedef void(^ACOssCopyObjectsCompletedBlock)(BOOL success);
typedef void(^ACOssQueryObjectCompletedBlock)(BOOL isExisted);

typedef NS_ENUM(NSInteger, ACOssErrorCODE) {
    ACOssErrorCODE_InitializeServiceFailed,
    ACOssErrorCODE_SignFailed,
    ACOssErrorCODE_AccessDenied,
    ACOssErrorCODE_NetworkError,
    ACOssErrorCODE_NotExist,
    ACOssErrorCODE_InvalidArgument,
    ACOssErrorCODE_TaskCancelled,
    ACOssErrorCODE_Unknown,
};


@protocol ACOssCancellableTask <NSObject>

- (void)ac_cancel;

@end

@protocol ACOssBehavior <NSObject>

- (void)configurate:(ACOssConfig *)ossInfo;

- (id<ACOssCancellableTask>)uploadFile:(NSString *)key
                               fileData:(NSData *)fileData
                              progress:(nullable ACOssUploadProgressBlock)progressBlock
                             completed:(nullable ACOssUploadCompletedBlock)completedBlock;

- (id<ACOssCancellableTask>)downloadFile:(NSString *)key
                                progress:(nullable ACOssDownloadProgressBlock)progressBlock
                               completed:(nullable ACOssDownloadCompletedBlock)completedBlock;

- (void)copyObjects:(NSArray<ACOssCopyObjectMeta *> *)objectMetaArray
          completed:(nullable ACOssCopyObjectsCompletedBlock)completedBlock;

- (void)doesObjectExist:(NSString *)key completed:(ACOssQueryObjectCompletedBlock)completedBlock;

@end

NS_ASSUME_NONNULL_END

#endif /* ACStorageBehavior_h */
