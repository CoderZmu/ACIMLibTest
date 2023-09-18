//
//  ACUtilities.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/28.
//

#import "ACUtilities.h"
#import "ACBase.h"

@implementation ACUtilities

+ (NSString *)base64EncodedStringFrom:(NSData *)data {
    return [data ac_base64EncodedString];
}

+ (NSData *)dataWithHexString:(NSString *)hexStr {
    return [NSData ac_dataWithBase64EncodedString:hexStr];
}

+ (NSString *)jsonStringWithJsonObject:(id)jsonObject {
    return [NSString ac_jsonStringWithJsonObject:jsonObject];
}

@end
