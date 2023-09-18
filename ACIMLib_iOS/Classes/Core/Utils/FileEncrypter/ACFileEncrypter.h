//
//  ACFileEncrypter.h
//  ACIMLib
//
//  Created by 子木 on 2023/8/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACFileEncrypter : NSObject

+ (NSData*)isaac_encrypt:(NSData*)data withKey:(NSString*)key;
+ (NSData*)isaac_decrypt:(NSData*)data withKey:(NSString*)key;

@end

NS_ASSUME_NONNULL_END
