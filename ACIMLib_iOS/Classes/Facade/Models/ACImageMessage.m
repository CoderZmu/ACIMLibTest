//
//  ACImageMessage.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/17.
//

#import "ACImageMessage.h"
#import "ACBase.h"
#import "ACImageMessage+Private.h"


@implementation ACImageMessage

+ (instancetype)messageWithImage:(UIImage *)image {
    ACImageMessage *msg = [[self alloc] init];;
    msg.originalImage = image;
    return msg;
}

+ (instancetype)messageWithImageURI:(NSString *)imageURI {
    ACImageMessage *msg = [[self alloc] init];;
    msg.originalImageData = [NSData dataWithContentsOfFile:imageURI];
    return msg;
}

+ (instancetype)messageWithImageData:(NSData *)imageData {
    ACImageMessage *msg = [[self alloc] init];;
    msg.originalImageData = imageData;
    return msg;
}

- (NSDictionary *)encode {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[super encode]];
    [dictionary ac_setSafeObject:[self.thumbnailData ac_base64EncodedString] forKey:@"thumbnailObjectKey"];
    [dictionary ac_setSafeObject:self.remoteUrl forKey:@"originalObjectKey"];
    [dictionary ac_setSafeObject:@((int)self.width) forKey:@"width"];
    [dictionary ac_setSafeObject:@((int)self.height) forKey:@"height"];
    [dictionary ac_setSafeObject:@(self.isFull) forKey:@"full"];
    [dictionary ac_setSafeObject:self.encryptKey forKey:@"encryptKey"];
    return [dictionary copy];
}


- (void)decodeWithData:(NSDictionary *)data {
    [super decodeWithData:data];
    self.thumbnailData = [NSData ac_dataWithBase64EncodedString:data[@"thumbnailObjectKey"]];
    self.remoteUrl = data[@"originalObjectKey"];
    self.width = [data[@"width"] longLongValue];
    self.height = [data[@"height"] longLongValue];
    self.full = [data[@"full"] boolValue];
    self.encryptKey = data[@"encryptKey"];
}

+ (NSString *)getObjectName {
    return ACImageMessageTypeIdentifier;
}

- (NSString *)imageUrl {
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.localPath]) {
        return self.localPath;
    }
    return self.remoteUrl;
}

@end
