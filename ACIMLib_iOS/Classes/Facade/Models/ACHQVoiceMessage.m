//
//  ACHQVoiceMessage.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/29.
//

#import "ACHQVoiceMessage.h"
#import "ACBase.h"

@implementation ACHQVoiceMessage

+ (instancetype)messageWithPath:(NSString *)localPath duration:(long)duration {
    ACHQVoiceMessage *instance = [[self alloc] init];
    instance.localPath = localPath;
    instance.duration = duration;
    return instance;
}


- (NSDictionary *)encode {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[super encode]];
    [dictionary ac_setSafeObject:@(self.duration) forKey:@"length"];
    [dictionary ac_setSafeObject:self.remoteUrl forKey:@"audioObjectKey"];
    [dictionary ac_setSafeObject:self.type forKey:@"extension"];
    [dictionary ac_setSafeObject:self.encryptKey forKey:@"encryptKey"];
    return [dictionary copy];
}


- (void)decodeWithData:(NSDictionary *)data {
    [super decodeWithData:data];
    self.duration = [data[@"length"] longLongValue];
    self.remoteUrl = data[@"audioObjectKey"];
    self.type = data[@"extension"];
    self.encryptKey = data[@"encryptKey"];
}

+ (NSString *)getObjectName {
    return ACHQVoiceMessageTypeIdentifier;
}

@end
