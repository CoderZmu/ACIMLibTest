//
//  ACUploadResponseCache.h
//  ACIMLib
//
//  Created by 子木 on 2022/9/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACUploadResponseCache : NSObject

+ (ACUploadResponseCache *)shared;
- (void)setResponse:(NSString *)response forKey:(NSString *)key;
- (NSString *)resonseForKey:(NSString *)key;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
