//
//  ACGlobalHelper.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/14.
//

#import "ACHelper.h"
#import "ACBase.h"
#import "ACAccountManager.h"

#if ACGPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
 #import <Protobuf/ACGPBProtocolBuffers.h>
#else
 #import "ACGPBProtocolBuffers.h"
#endif


@implementation ACHelper


+ (BOOL)isEmptyString:(NSString *)string {
    if (string == nil || [string isEqualToString:@""]) {
        return true;
    }
    return false;
}

/**
 将数组转成网络请求的类型
 */
+ (ACGPBInt64Array *)getACGPBInt64ArrayFrom:(NSArray *)numbers {
    ACGPBInt64Array *memberUidArray = [ACGPBInt64Array array];
    for (NSNumber *number in numbers) {
        if ([number respondsToSelector:@selector(ac_int64Value)]) {
            [memberUidArray addValue:number.ac_int64Value];
        } else if ([number respondsToSelector:@selector(integerValue)]) {
            [memberUidArray addValue:number.integerValue];
        }
        
    }
    return memberUidArray;
}

+ (NSArray *)transACGPBInt64ArrayToNumberArray:(ACGPBInt64Array *)array {
    NSMutableArray *content = [NSMutableArray array];
    [array enumerateValuesWithBlock:^(int64_t value, NSUInteger idx, BOOL * _Nonnull stop) {
        [content addObject:@(value)];
    }];
    return array.copy;
}

+ (NSString *)getAPNsTokenStringWithData:(NSData *)tokenData {
    if (![tokenData isKindOfClass:[NSData class]]) return @"";
    
    NSString *tokenString;
    if ([UIDevice currentDevice].systemVersion.floatValue > 13.0) {
        NSUInteger len = [tokenData length];
        char *chars = (char *)[tokenData bytes];
        NSMutableString *hexString = [[NSMutableString alloc] init];
        for (NSUInteger i = 0; i < len; i ++) {
            [hexString appendString:[NSString stringWithFormat:@"%0.2hhx", chars[i]]];
        }
        tokenString = hexString;
    } else {
        tokenString = [[tokenData ac_hexString] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
        tokenString = [tokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    return tokenString;
}

@end
