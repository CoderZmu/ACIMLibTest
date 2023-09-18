//
//  ACRecallNotificationMessage.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/22.
//

#import "ACRecallNotificationMessage.h"
#import "ACMessageSerializeSupport.h"

@implementation ACRecallNotificationMessage


- (NSDictionary *)encode {
    return nil;
}

- (void)decodeWithData:(NSDictionary *)data {
    [super decodeWithData:data];
    self.operatorId = [data[@"operatorId"] longLongValue];
    self.recallTime = [data[@"recallTime"] longLongValue];
    self.originalObjectName = data[@"originalObjectName"];
    self.recallContent = data[@"recallContent"];
    
}

+ (NSString *)getObjectName {
    return ACRecallNotificationMessageIdentifier;
}

+ (ACMessagePersistent)persistentFlag {
    return MessagePersistent_ISPERSISTED;
}

@end
