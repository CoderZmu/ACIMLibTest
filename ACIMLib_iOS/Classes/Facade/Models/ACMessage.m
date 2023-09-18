//
//  ACMessage.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/16.
//

#import "ACMessage.h"

@implementation ACMessage

- (instancetype)initWithType:(ACConversationType)conversationType
                    targetId:(long)targetId
                   direction:(ACMessageDirection)messageDirection
                     content:(ACMessageContent *)content {
    self = [super init];
    self.conversationType = conversationType;
    self.targetId = targetId;
    self.messageDirection = messageDirection;
    self.content = content;
    return self;
}
@end
