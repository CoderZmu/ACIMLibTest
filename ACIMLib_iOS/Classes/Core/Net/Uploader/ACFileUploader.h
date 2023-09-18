//
//  ACUploader.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/27.
//

#import <Foundation/Foundation.h>
#import "ACOssBehavior.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACUploadCompleteBlock) (BOOL success,  NSString * _Nullable  path,  NSString * _Nullable encriptKey);

@interface ACFileUploader : NSObject

+ (nullable id<ACOssCancellableTask>)uploadSingleFile:(NSString *)filePath progress:(nullable void (^)(int progress))uploadProgress
                complete:(ACUploadCompleteBlock)completeBlock;


@end

NS_ASSUME_NONNULL_END
