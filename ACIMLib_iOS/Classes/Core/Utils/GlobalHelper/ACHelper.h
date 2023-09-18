//
//  ACGlobalHelper.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACGPBInt64Array;

@interface ACHelper : NSObject

+ (BOOL)isEmptyString:(NSString *)string;

+ (ACGPBInt64Array *)getACGPBInt64ArrayFrom:(NSArray *)numbers;
+ (NSArray *)transACGPBInt64ArrayToNumberArray:(ACGPBInt64Array *)array;
+ (NSString *)getAPNsTokenStringWithData:(NSData *)tokenData;

@end

NS_ASSUME_NONNULL_END
