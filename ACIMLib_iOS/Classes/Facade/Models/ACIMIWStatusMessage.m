//
//  ACIMIWStatusMessage.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/30.
//

#import "ACIMIWStatusMessage.h"

@implementation ACIMIWStatusMessage

+ (ACMessagePersistent)persistentFlag {
    return MessagePersistent_STATUS;
}

+ (NSString *)getObjectName {
    return ACIMIWStatusMessageIdentifier;
}


@end
