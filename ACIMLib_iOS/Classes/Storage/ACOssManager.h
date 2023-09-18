//
//  ACOssManager.h
//  Sugram
//
//  Created by 子木 on 2023/1/5.
//  Copyright © 2023 Sugram. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACOssBehavior.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACOssManager : NSObject

+ (ACOssManager *)shareInstance;

- (id<ACOssCancellableTask>)uploadFile:(NSString *)key
                              fileData:(NSData *)fileData
                              progress:(nullable ACOssUploadProgressBlock)progressBlock
                             completed:(nullable ACOssUploadCompletedBlock)completedBlock;

- (void)uploadMultipleFiles:(NSArray<NSString *> *)keys
                  fileDatas:(NSArray<NSData *> *)fileDatas
                  completed:(nullable ACOssUploadCompletedBlock)completedBlock;


- (id<ACOssCancellableTask>)downloadFile:(NSString *)key
                                progress:(nullable ACOssDownloadProgressBlock)progressBlock
                               completed:(nullable ACOssDownloadCompletedBlock)completedBlock;

- (void)copyObjects:(NSArray<ACOssCopyObjectMeta *> *)objectMetaArray
          completed:(nullable ACOssCopyObjectsCompletedBlock)completedBlock;

- (void)doesObjectExist:(NSString *)key completed:(ACOssQueryObjectCompletedBlock)completedBlock;

- (NSString *)generateObjectKeyWithExt:(nullable NSString *)ext;

@end

NS_ASSUME_NONNULL_END
