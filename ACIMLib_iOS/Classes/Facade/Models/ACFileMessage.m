//
//  ACFileMessage.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/28.
//

#import "ACFileMessage.h"
#import "ACBase.h"

@implementation ACFileMessage

+ (instancetype)messageWithFile:(NSString *)localPath {
    ACFileMessage *instance = [[self alloc] init];
    instance.localPath = localPath;
    return instance;
}

- (NSDictionary *)encode {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[super encode]];
    [dictionary ac_setSafeObject:self.name forKey:@"title"];
    [dictionary ac_setSafeObject:self.type forKey:@"extension"];
    [dictionary ac_setSafeObject:@(self.size) forKey:@"size"];
    [dictionary ac_setSafeObject:self.remoteUrl forKey:@"originalObjectKey"];
    [dictionary ac_setSafeObject:self.encryptKey forKey:@"encryptKey"];
    return [dictionary copy];
}

- (void)decodeWithData:(NSDictionary *)data {
    [super decodeWithData:data];
    self.name = data[@"title"];
    self.type = data[@"extension"];
    self.size = [data[@"size"] longLongValue];
    self.remoteUrl = data[@"originalObjectKey"];
    self.encryptKey = data[@"encryptKey"];
}

- (NSArray<NSString *> *)getSearchableWords {
    if (self.name.length) return @[self.name];
    return nil;
}

+ (NSString *)getObjectName {
    return ACFileMessageTypeIdentifier;
}

- (NSString *)fileUrl {
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.localPath]) {
        return self.localPath;
    }
    return self.remoteUrl;
}


@end
