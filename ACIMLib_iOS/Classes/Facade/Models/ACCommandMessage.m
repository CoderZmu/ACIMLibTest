//
//  ACCommandMessage.m
//  ACIMLib
//
//  Created by 子木 on 2022/7/1.
//

#import "ACCommandMessage.h"
#import "ACBase.h"

@implementation ACCommandMessage

+ (instancetype)messageWithName:(NSString *)name data:(NSString *)data {
    ACCommandMessage *instance = [[self alloc] init];
    instance.name = name;
    instance.data = data;
    return instance;
}

- (NSDictionary *)encode {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super encode]];
    [dict ac_setSafeObject:self.name forKey:@"name"];
    [dict ac_setSafeObject:self.data forKey:@"data"];
    return [dict copy];
}

- (void)decodeWithData:(NSDictionary *)data {
    [super decodeWithData:data];
    self.name = data[@"name"];
    self.data = data[@"data"];
}

+ (NSString *)getObjectName {
    return ACCommandMessageIdentifier;
}

+ (ACMessagePersistent)persistentFlag {
    return MessagePersistent_NONE;
}

@end
