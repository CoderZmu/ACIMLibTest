//
//  ACTextMessage.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/17.
//

#import "ACTextMessage.h"
#import "ACBase.h"

@implementation ACTextMessage

+ (instancetype)messageWithContent:(NSString *)content {
    ACTextMessage *instance = [[ACTextMessage alloc] init];
    instance.content = content;
    return instance;
}

- (NSDictionary *)encode {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super encode]];
    [dict ac_setSafeObject:self.content forKey:@"content"];
    return [dict copy];
}

- (void)decodeWithData:(NSDictionary *)data {
    [super decodeWithData:data];
    self.content = data[@"content"];
}

+ (NSString *)getObjectName {
    return ACTextMessageTypeIdentifier;
}

- (NSArray<NSString *> *)getSearchableWords {
    if (self.content.length)  return @[self.content];
    return nil;
}

+ (ACMessagePersistent)persistentFlag {
    return MessagePersistent_ISCOUNTED;
}


@end
