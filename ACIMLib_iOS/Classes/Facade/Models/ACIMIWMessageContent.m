//
//  ACIMIWMessageContent.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/30.
//

#import "ACIMIWMessageContent.h"
#import "ACBase.h"

@implementation ACIMIWMessageContent

+ (instancetype)messageWithType:(NSString *)messageType fields:(NSDictionary<NSString*, NSString*> *)fields {
    ACIMIWMessageContent *instance = [[self alloc] init];
    instance.messageType = messageType;
    instance.mFields = fields;
    return instance;
}


- (NSDictionary *)encode {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[super encode]];
    [dictionary ac_setSafeObject:self.messageType forKey:@"messageType"];
    [dictionary ac_setSafeObject:self.mFields forKey:@"fields"];
    return dictionary;
}


- (void)decodeWithData:(NSDictionary *)data {
    [super decodeWithData:data];
    self.mFields = data[@"fields"];
    self.messageType = data[@"messageType"];
}


@end
