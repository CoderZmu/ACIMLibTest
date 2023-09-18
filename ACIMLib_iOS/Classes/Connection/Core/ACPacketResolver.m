//
//  ACPackageResolver.m
//  ACConnection
//
//  Created by 子木 on 2022/6/9.
//

#import "ACPacketResolver.h"
#import "ACSocketHeader.h"
#import "ACInputStream.h"


@interface ACPacketResolver()
@property (nonatomic, strong) NSMutableData  *buffer;
@end

@implementation ACPacketResolver


- (instancetype)init {
    self = [super init];
    _buffer = [[NSMutableData alloc] init];
    return self;
}

- (void)receive:(NSData *)data {
     [_buffer appendData:data];

    
     while (1)  {
         if (_buffer.length < 6) {
             break;
         }
         ACInputStream *is = [[ACInputStream alloc] initWithData:_buffer];
         int8_t ctx = [is readInt8]; // STX
         int8_t padding = [is readInt8]; // padding
 
         NSAssert(ctx == ACMessage_Response_PROTOCOL_START_FLAG, @"********************包头解析错误********************");
         NSAssert(padding == '\xff', @"********************包头解析错误********************");
  
         int length = [is readInt32]; // length//获取内容长度
         
         
         if (length > 10*1024*1024 || length <= 0) {
            //数据异常
             if ([self.delegate respondsToSelector:@selector(packetResolverFailed:)]) {
                 [self.delegate packetResolverFailed:self];
             }
             break;
         }
    
         if (_buffer.length < length) {
             //如果buf长度小于包长度，需要继续接收数据
             break;
         } else  {
             int cmdId = [is readInt32];
             int bodyLength = length - 11;
             NSData *body = [is readData:bodyLength];
            
             [_buffer replaceBytesInRange:NSMakeRange(0, length) withBytes:NULL length:0];
             
             if ([self.delegate respondsToSelector:@selector(packetResolver:didResolveAPackage:payload:)]) {
                 [self.delegate packetResolver:self didResolveAPackage:cmdId payload:body];
             }
             
             if (_buffer.length == 0) {
                 break;
             }

         }}
}

- (void)clear {
    [self.buffer setLength:0];
}

@end
