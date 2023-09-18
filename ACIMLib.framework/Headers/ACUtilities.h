//
//  ACUtilities.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACUtilities : NSObject

+ (NSString *)base64EncodedStringFrom:(NSData *)data;
+ (NSData *)dataWithHexString:(NSString *)hexStr;

+ (NSString *)jsonStringWithJsonObject:(id)jsonObject;
@end

NS_ASSUME_NONNULL_END
