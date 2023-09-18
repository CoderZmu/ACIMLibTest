//
//  ACSightMessage.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/28.
//

#import "ACSightMessage.h"
#import "ACBase.h"


@implementation ACSightMessage

+ (instancetype)messageWithLocalPath:(NSString *)path thumbnail:(NSData *)thunmnailData duration:(NSUInteger)duration {
    ACSightMessage *instance = [[self alloc] init];
    instance.localPath = path;
    instance.thumbnailData = thunmnailData;
    instance.duration = duration;
    return instance;
}


- (NSDictionary *)encode {
 
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[super encode]];
    [dictionary ac_setSafeObject:[self.thumbnailData ac_base64EncodedString] forKey:@"thumbnailObjectKey"];
    [dictionary ac_setSafeObject:@(self.duration) forKey:@"during"];
    [dictionary ac_setSafeObject:self.name forKey:@"originalName"];
    [dictionary ac_setSafeObject:self.remoteUrl forKey:@"videoObjectKey"];
    [dictionary ac_setSafeObject:@(self.size) forKey:@"size"];
    [dictionary ac_setSafeObject:self.encryptKey forKey:@"encryptKey"];
    return [dictionary copy];
}


- (void)decodeWithData:(NSDictionary *)data {
    [super decodeWithData:data];
    self.thumbnailData = [NSData ac_dataWithBase64EncodedString:data[@"thumbnailObjectKey"]];
    self.remoteUrl = data[@"videoObjectKey"];
    self.duration = [data[@"during"] longLongValue];
    self.name = data[@"originalName"];
    self.size = [data[@"size"] longLongValue];
    self.encryptKey = data[@"encryptKey"];
}

+ (NSString *)getObjectName {
    return ACSightMessageTypeIdentifier;
}



@end
