//
//  ACMissingMsgsInterval.m
//  ACIMLib
//
//  Created by 子木 on 2022/8/2.
//

#import "ACMissingMsgsInterval.h"

@implementation ACMissingMsgsInterval

- (instancetype)initWithLeft:(long)left right:(long)right {
    self = [super init];
    self.left = left;
    self.right = right;
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ACMissingMsgsInterval *copyItem = [[ACMissingMsgsInterval alloc] init];
    copyItem.left = _left;
    copyItem.right = _right;
    return copyItem;
}

@end
