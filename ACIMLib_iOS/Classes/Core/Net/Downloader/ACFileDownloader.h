//
//  ACFileDownloader.h
//  ACIMLib
//
//  Created by 子木 on 2023/8/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ACFileDownloaderProgressBlock)(NSProgress *progress);
typedef void (^ACFileDownloaderCompletedBlock)( NSError * _Nullable error);

@interface ACFileDownloader : NSObject

+ (ACFileDownloader *)shared;

- (void)downloadFileWithOssKey:(NSString *)key
              fileEncryptKey:(NSString *)fileEncryptKey
                 destination:(NSURL *)destination
                   ignoreCache:(BOOL)ignoreCache
                    progress:(ACFileDownloaderProgressBlock)progressBlock
                   completed:(ACFileDownloaderCompletedBlock)completedBlock;


- (BOOL)isDownloading:(NSString *)key;

- (void)cancelDownloading:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
