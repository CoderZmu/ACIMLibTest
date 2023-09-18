//
//  ACIMIWNormalMessage.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/30.
//

#import "ACIMIWNormalMessage.h"

@implementation ACIMIWNormalMessage

+ (ACMessagePersistent)persistentFlag {
    return MessagePersistent_ISCOUNTED;
}

+ (NSString *)getObjectName {
    return ACIMIWNormalMessageIdentifier;
}


@end
