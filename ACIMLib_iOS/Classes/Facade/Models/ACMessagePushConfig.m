//
//  ACMessagePushConfig.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/9.
//

#import "ACMessagePushConfig.h"
#import "ACBase.h"

@implementation ACMessagePushConfig

- (NSString *)encodePushConfig {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
   
    if ([NSString ac_isValidString:self.pushTitle]) {
        [dict ac_setSafeObject:@{@"title": self.pushTitle} forKey:@"pushExt"];
    }
    if ([NSString ac_isValidString:self.pushContent]) {
        [dict ac_setSafeObject:self.pushContent forKey:@"pushContent"];
    }
    if ([NSString ac_isValidString:self.pushData]) {
        [dict ac_setSafeObject:self.pushData forKey:@"pushData"];
    }
    return [NSString ac_jsonStringWithJsonObject:dict];
}

@end
