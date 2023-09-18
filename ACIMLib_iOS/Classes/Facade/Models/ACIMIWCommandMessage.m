//
//  ACIMIWCommandMessage.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/30.
//

#import "ACIMIWCommandMessage.h"

@implementation ACIMIWCommandMessage

+ (ACMessagePersistent)persistentFlag {
    return MessagePersistent_NONE;
}

+ (NSString *)getObjectName {
    return ACIMIWCommandMessageIdentifier;
}

@end
