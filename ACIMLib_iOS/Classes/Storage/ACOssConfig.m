//
//  ACOssConfig.m
//  Sugram
//
//  Created by 子木 on 2023/1/5.
//  Copyright © 2023 Sugram. All rights reserved.
//

#import "ACOssConfig.h"


@interface ACOssConfig()
@end

@implementation ACOssConfig

+ (BOOL)supportsSecureCoding {
    return YES;
}

+ (instancetype)createOssConfigWithServerConfDict:(NSDictionary *)confDict {
    ACOssConfig *instance = [ACOssConfig new];
    instance.accessKey = confDict[@"ak"];
    instance.secretKey = confDict[@"as"];
    instance.chatBucket = confDict[@"bk"];
    instance.endPoint = confDict[@"ed"];
    return instance;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:_accessKey forKey:NSStringFromSelector(@selector(accessKey))];
    [coder encodeObject:_secretKey forKey:NSStringFromSelector(@selector(secretKey))];
    [coder encodeObject:_endPoint forKey:NSStringFromSelector(@selector(endPoint))];
    [coder encodeObject:_chatBucket forKey:NSStringFromSelector(@selector(chatBucket))];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    self = [super init];
    if (self) {
        _accessKey = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(accessKey))];
        _secretKey =[coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(secretKey))];
        _endPoint = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(endPoint))];
        _chatBucket = [coder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(chatBucket))];
    }
     return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if ([self class] != [object class]) return NO;
    
    ACOssConfig *otherOssMo = (ACOssConfig *)object;
    return [_accessKey isEqualToString:otherOssMo.accessKey] &&
    [_secretKey isEqualToString:otherOssMo.secretKey] &&
    [_endPoint isEqualToString:otherOssMo.endPoint] &
    [_chatBucket isEqualToString:otherOssMo.chatBucket];
}

- (NSUInteger)hash {
    NSUInteger value = [_accessKey hash];
    value ^= [_secretKey hash];
    value ^= [_endPoint hash];
    value ^= [_chatBucket hash];;
    return value;
}


@end

