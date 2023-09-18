//
//  ACMentionedInfo.m
//  ACIMLib
//
//  Created by 子木 on 2022/8/5.
//

#import "ACMentionedInfo.h"

@implementation ACMentionedInfo

- (instancetype)initWithMentionedType:(ACMentionedType)type
                           userIdList:(NSArray *)userIdList {
    self = [super init];
    _type = type;
    NSMutableArray *tmp = [NSMutableArray array];
    for (id item in userIdList) {
        if ([item isKindOfClass:[NSNumber class]]) {
            [tmp addObject:item];
        } else if ([item isKindOfClass:[NSString class]]) {
            NSInteger n = [item integerValue];
            if (n) {
                [tmp addObject:@(n)];
            }
        }
    }
    _userIdList = [tmp copy];
    return self;
}

@end
