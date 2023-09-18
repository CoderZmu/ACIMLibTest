//
//  ACContactNotificationMessage.m
//  ACIMLib
//
//  Created by 子木 on 2022/7/1.
//

#import "ACContactNotificationMessage.h"
#import "ACBase.h"

@implementation ACContactNotificationMessage

+ (instancetype)notificationWithOperation:(NSString *)operation
                             sourceUserId:(NSString *)sourceUserId
                             targetUserId:(NSString *)targetUserId
                                  message:(NSString *)message
                                    extra:(NSString *)extra {
    ACContactNotificationMessage *instance = [[self alloc] init];
    instance.operation = operation;
    instance.sourceUserId = sourceUserId;
    instance.targetUserId = targetUserId;
    instance.message = message;
    instance.extra = extra;
    return instance;
}


- (NSDictionary *)encode {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super encode]];
    [dict ac_setSafeObject:self.operation forKey:@"operation"];
    [dict ac_setSafeObject:self.sourceUserId forKey:@"sourceUserId"];
    [dict ac_setSafeObject:self.targetUserId forKey:@"targetUserId"];
    [dict ac_setSafeObject:self.message forKey:@"message"];
    return dict;
}

- (void)decodeWithData:(NSDictionary *)data {
    [super decodeWithData:data];
    self.operation = data[@"operation"];
    self.sourceUserId = data[@"sourceUserId"];
    self.targetUserId = data[@"targetUserId"];
    self.message = data[@"message"];
}

+ (NSString *)getObjectName {
    return ACContactNotificationMessageIdentifier;
}

+ (ACMessagePersistent)persistentFlag {
    return MessagePersistent_ISPERSISTED;
}


@end
