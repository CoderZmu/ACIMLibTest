//
//  SGChatMessage.m
//  Sugram
//
//  Created by gnutech003 on 2017/6/5.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import "ACChatMessageMo.h"
#import "ACBase.h"

@implementation ACChatMessageMo

ACHHJNSCoding(ACChatMessageMo)

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if ([self class] != [object class]) return NO;
    
    ACChatMessageMo *otherChatMo = (ACChatMessageMo *)object;
    return [_dialogId isEqualToString:otherChatMo.dialogId] && [_msgIdSet isEqualToSet:otherChatMo.msgIdSet];
}

- (NSUInteger)hash {
    NSUInteger value = [_dialogId hash];
    for (NSNumber *item in _msgIdSet) {
        value ^= [item hash];
    }
    return value;
}


@end
