//
//  ACGIFMessage.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/29.
//

#import "ACGIFMessage.h"
#import "ACBase.h"

@interface ACGIFMessage()

@property (nonatomic, strong, readwrite) NSData *gifData;
@end

@implementation ACGIFMessage

+ (instancetype)messageWithGIFImageData:(NSData *)gifImageData width:(long)width height:(long)height {
    ACGIFMessage *instance = [[self alloc] init];
    instance.gifData = gifImageData;
    instance.width = width;
    instance.height = height;
    return instance;
}

+ (instancetype)messageWithGIFURI:(NSString *)gifURI width:(long)width height:(long)height {
    ACGIFMessage *instance = [[self alloc] init];
    instance.width = width;
    instance.height = height;
    instance.gifData = [NSData dataWithContentsOfFile:gifURI];
    return instance;
}

- (NSDictionary *)encode {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[super encode]];
    [dictionary ac_setSafeObject:[self.thumbnailData ac_base64EncodedString] forKey:@"thumbnailObjectKey"];
    [dictionary ac_setSafeObject:@"gif" forKey:@"extension"];
    [dictionary ac_setSafeObject:@(self.gifDataSize) forKey:@"size"];
    [dictionary ac_setSafeObject:@((int)self.width) forKey:@"width"];
    [dictionary ac_setSafeObject:@((int)self.height) forKey:@"height"];
    [dictionary ac_setSafeObject:self.remoteUrl forKey:@"originalObjectKey"];
    [dictionary ac_setSafeObject:self.encryptKey forKey:@"encryptKey"];
    return [dictionary copy];
}

- (void)decodeWithData:(NSDictionary *)data {
    [super decodeWithData:data];
    self.thumbnailData = [NSData ac_dataWithBase64EncodedString:data[@"thumbnailObjectKey"]];
    self.remoteUrl = data[@"originalObjectKey"];
    self.gifDataSize = [data[@"size"] longLongValue];
    self.width = [data[@"width"] longLongValue];
    self.height = [data[@"height"] longLongValue];
    self.encryptKey = data[@"encryptKey"];
}

+ (NSString *)getObjectName {
    return ACGIFMessageTypeIdentifier;
}

@end
