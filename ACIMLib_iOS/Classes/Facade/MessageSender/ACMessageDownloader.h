//
//  ACMessageDownloader.h
//  ACIMLib
//
//  Created by 子木 on 2023/8/22.
//

#import <Foundation/Foundation.h>
#import "ACStatusDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACMessageDownloader : NSObject

+ (void)downloadMediaMessage:(long)messageId
                    progress:(void (^)(NSProgress *progress))progressBlock
                     success:(void (^)(NSString *mediaPath))successBlock
                       error:(void (^)(ACErrorCode errorCode))errorBlock
                      cancel:(void (^)(void))cancelBlock;

+ (BOOL)cancelDownloadMediaMessage:(long)messageId;
@end

NS_ASSUME_NONNULL_END
