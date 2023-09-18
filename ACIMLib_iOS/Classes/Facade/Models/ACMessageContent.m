//
//  ACMessageContent.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/16.
//

#import "ACMessageContent.h"
#import "ACBase.h"

@implementation ACMessageContent

- (void)decodeWithData:(nonnull NSDictionary *)data {
    self.extra = data[@"extra"];
    self.senderUserInfo = [[ACUserInfo alloc] initWithEncodeData:data[@"user"]];
}

- (nonnull NSDictionary *)encode {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict ac_setSafeObject:[self.senderUserInfo encode] forKey:@"user"];
    if ([NSString ac_isValidString:self.extra]) {
        [dict ac_setSafeObject:self.extra forKey:@"extra"];
    }
    return [dict copy];
}

+ (nonnull NSString *)getObjectName {
    return @"";
}

+ (ACMessagePersistent)persistentFlag {
    return MessagePersistent_NONE;
}

@end
