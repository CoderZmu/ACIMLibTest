//
//  ACPackageBuilder.m
//  ACConnection
//
//  Created by 子木 on 2022/6/9.
//

#import "ACPacketBuilder.h"
#import "ACOutputStream.h"
#import "ACSocketHeader.h"

@implementation ACPacketBuilder


+ (NSData *)buildProtocolPackageWithCommandId:(int32_t)commandId payload:(NSData *)body {
    ACOutputStream *os = [[ACOutputStream alloc] init];
    [os writeInt8:ACMessage_PROTOCOL_START_FLAG];
    [os writeInt8:0xFF];
    [os writeInt32:(int)body.length +11];  // length 小端
    [os writeInt32:commandId];
    [os writeData:body];
    [os writeInt8:ACMessage_PROTOCOL_END_FLAG];
    return [os currentBytes];
}

@end
