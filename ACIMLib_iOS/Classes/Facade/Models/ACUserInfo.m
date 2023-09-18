//
//  ACUserInfo.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/16.
//

#import "ACUserInfo.h"
#import "ACBase.h"

@implementation ACUserInfo

- (instancetype)initWithUserId:(long)userId name:(NSString *)username portrait:(NSString *)portrait {
    self = [super init];
    _userId = userId;
    _name = [username copy];
    _portraitUri = [portrait copy];
    return self;
}

- (instancetype)initWithEncodeData:(nonnull NSDictionary *)data {
    self = [super init];
    if (!data || ![data isKindOfClass:NSDictionary.class] || ![data[@"userId"] longValue]) return nil;
    self.userId = [data[@"userId"] longValue];
    self.name = data[@"name"] ?: @"";
    self.portraitUri = data[@"portraitUri"] ?: @"";
    self.extra = data[@"extra"];
    return self;
}

- (nonnull NSDictionary *)encode {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
   
    [dict ac_setSafeObject:@(self.userId) forKey:@"userId"];
    if ([NSString ac_isValidString:self.name]) {
        [dict ac_setSafeObject:self.name forKey:@"name"];
    }
    if ([NSString ac_isValidString:self.portraitUri]) {
        [dict ac_setSafeObject:self.portraitUri forKey:@"portraitUri"];
    }
    if ([NSString ac_isValidString:self.extra]) {
        [dict ac_setSafeObject:self.extra forKey:@"extra"];
    }
    return [dict copy];
}

@end
