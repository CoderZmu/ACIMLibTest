//
//  ACMediaMessageContent.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/17.
//

#import "ACMediaMessageContent.h"

@implementation ACMediaMessageContent

+ (ACMessagePersistent)persistentFlag {
    return MessagePersistent_ISCOUNTED;
}

@end
