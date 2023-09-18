//
//  ACFileDownloaderCache.h
//  ACIMLib
//
//  Created by 子木 on 2023/8/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACFileDownloadCache : NSObject

+ (ACFileDownloadCache *)shared;

- (void)setResponseData:(NSData *)responseData forKey:(NSString *)key;
- (NSData *)resonseDataForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
