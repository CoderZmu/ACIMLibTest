//
//  ACIMIWStorageMessage.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/30.
//

#import "ACIMIWStorageMessage.h"

@implementation ACIMIWStorageMessage

+ (ACMessagePersistent)persistentFlag {
    return MessagePersistent_ISPERSISTED;
}

+ (NSString *)getObjectName {
    return ACIMIWStorageMessageIdentifier;
}

@end
