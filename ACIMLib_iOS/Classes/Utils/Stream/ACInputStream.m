

#import <Foundation/Foundation.h>
#import "ACLogger.h"
#import "ACInputStream.h"

#if TARGET_OS_IPHONE
#   import <endian.h>
#endif

static inline int roundUpInput(int numToRound, int multiple)
{
    if (multiple == 0)
    {
        return numToRound;
    }
    
    int remainder = numToRound % multiple;
    if (remainder == 0)
    {
        return numToRound;
    }
    
    return numToRound + multiple - remainder;
}

@interface ACInputStream ()
{
    NSInputStream *_wrappedInputStream;
}

@end

@implementation ACInputStream

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (self != nil)
    {
        _wrappedInputStream = [[NSInputStream alloc] initWithData:data];
        [_wrappedInputStream open];
    }
    return self;
}

- (void)dealloc
{
    [_wrappedInputStream close];
}

- (NSInputStream *)wrappedInputStream
{
    return _wrappedInputStream;
}

- (BOOL)readBool
{
    int32_t value = 0;
    
    if ([_wrappedInputStream read:(uint8_t *)&value maxLength:4] != 4)
    {
        [ACLogger debug:@"***** Couldn't read int32"];
    }
    
    
    return value == (int32_t)0x997275b5;
}


- (int8_t)readInt8
{
    int8_t value = 0;
    
    if ([_wrappedInputStream read:(uint8_t *)&value maxLength:1] != 1)
    {
      
         [ACLogger debug:@"***** Couldn't read int8"];
            
            @throw [[NSException alloc] initWithName:@"MTInputStreamException" reason:@"readInt8 end of stream" userInfo:@{}];
     
    }
    
    
#if __BYTE_ORDER == __LITTLE_ENDIAN
#elif __BYTE_ORDER == __BIG_ENDIAN
#   error "Big endian is not implemented"
#else
#   error "Unknown byte order"
#endif
    
    return value;
}

- (int16_t)readInt16
{
    int16_t value = 0;
    
    if ([_wrappedInputStream read:(uint8_t *)&value maxLength:2] != 2)
    {

        [ACLogger debug:@"***** Couldn't read int16"];
            
            @throw [[NSException alloc] initWithName:@"MTInputStreamException" reason:@"readInt16 end of stream" userInfo:@{}];
        
    }

#if __BYTE_ORDER == __LITTLE_ENDIAN
#elif __BYTE_ORDER == __BIG_ENDIAN
#   error "Big endian is not implemented"
#else
#   error "Unknown byte order"
#endif
    
    return value;
}


- (int32_t)readInt32
{
    int32_t value = 0;
    
    if ([_wrappedInputStream read:(uint8_t *)&value maxLength:4] != 4)
    {
      
        [ACLogger debug:@"***** Couldn't read int32"];
            
            @throw [[NSException alloc] initWithName:@"MTInputStreamException" reason:@"readInt32 end of stream" userInfo:@{}];
        
    }
    
#if __BYTE_ORDER == __LITTLE_ENDIAN
#elif __BYTE_ORDER == __BIG_ENDIAN
#   error "Big endian is not implemented"
#else
#   error "Unknown byte order"
#endif
    
    return value;
}

- (int32_t)readInt32:(bool *)failed
{
    int32_t value = 0;
    
    if ([_wrappedInputStream read:(uint8_t *)&value maxLength:4] != 4)
    {
        *failed = true;
        return 0;
    }
    
#if __BYTE_ORDER == __LITTLE_ENDIAN
#elif __BYTE_ORDER == __BIG_ENDIAN
#   error "Big endian is not implemented"
#else
#   error "Unknown byte order"
#endif
    
    return value;
}

- (int64_t)readInt64
{
    int64_t value = 0;
    
    if ([_wrappedInputStream read:(uint8_t *)&value maxLength:8] != 8)
    {

        [ACLogger debug:@"***** Couldn't read int64"];

    }
    
#if __BYTE_ORDER == __LITTLE_ENDIAN
#elif __BYTE_ORDER == __BIG_ENDIAN
#   error "Big endian is not implemented"
#else
#   error "Unknown byte order"
#endif
    
    return value;
}

- (int64_t)readInt64:(bool *)failed
{
    int64_t value = 0;
    
    if ([_wrappedInputStream read:(uint8_t *)&value maxLength:8] != 8)
    {
        *failed = true;
        return 0;
    }
    
#if __BYTE_ORDER == __LITTLE_ENDIAN
#elif __BYTE_ORDER == __BIG_ENDIAN
#   error "Big endian is not implemented"
#else
#   error "Unknown byte order"
#endif
    
    return value;
}

- (double)readDouble
{
    double value = 0.0;
    
    if ([_wrappedInputStream read:(uint8_t *)&value maxLength:8] != 8)
    {

        [ACLogger debug:@"***** Couldn't read double"];
      
    }
    
#if __BYTE_ORDER == __LITTLE_ENDIAN
#elif __BYTE_ORDER == __BIG_ENDIAN
#   error "Big endian is not implemented"
#else
#   error "Unknown byte order"
#endif
    
    return value;
}

- (double)readDouble:(bool *)failed
{
    double value = 0.0;
    
    if ([_wrappedInputStream read:(uint8_t *)&value maxLength:8] != 8)
    {
        *failed = true;
        return 0.0;
    }
    
#if __BYTE_ORDER == __LITTLE_ENDIAN
#elif __BYTE_ORDER == __BIG_ENDIAN
#   error "Big endian is not implemented"
#else
#   error "Unknown byte order"
#endif
    
    return value;
}

- (NSData *)readData:(int)length
{
    uint8_t *bytes = (uint8_t *)malloc(length);
    NSInteger readLen = [_wrappedInputStream read:bytes maxLength:length];
    if (readLen != length)
    {

        [ACLogger debug:[NSString stringWithFormat:@"***** Couldn't read %d bytes", length]];
        
    }
    NSData *data = [[NSData alloc] initWithBytesNoCopy:bytes length:length freeWhenDone:true];
    return data;
}

- (NSData *)readData:(int)length failed:(bool *)failed
{
    uint8_t *bytes = (uint8_t *)malloc(length);
    NSInteger readLen = [_wrappedInputStream read:bytes maxLength:length];
    if (readLen != length)
    {
        free(bytes);
        *failed = true;
        return nil;
    }
    NSData *data = [[NSData alloc] initWithBytesNoCopy:bytes length:length freeWhenDone:true];
    return data;
}

- (NSMutableData *)readMutableData:(NSUInteger)length
{
    uint8_t *bytes = (uint8_t *)malloc(length);
    NSInteger readLen = [_wrappedInputStream read:bytes maxLength:length];
    if (readLen != length)
    {

        [ACLogger debug: [NSString stringWithFormat:@"***** Couldn't read %lu bytes", (unsigned long)length]];
  
    }
    NSMutableData *data = [[NSMutableData alloc] initWithBytesNoCopy:bytes length:length freeWhenDone:true];
    return data;
}

- (NSMutableData *)readMutableData:(NSUInteger)length failed:(bool *)failed
{
    uint8_t *bytes = (uint8_t *)malloc(length);
    NSInteger readLen = [_wrappedInputStream read:bytes maxLength:length];
    if (readLen != length)
    {
        free(bytes);
        *failed = true;
        return nil;
    }
    NSMutableData *data = [[NSMutableData alloc] initWithBytesNoCopy:bytes length:length freeWhenDone:true];
    return data;
}

- (NSString *)readString
{
    uint8_t tmp = 0;
    [_wrappedInputStream read:&tmp maxLength:1];
    
    int paddingBytes = 0;
    
    int32_t length = tmp;
    if (length == 254)
    {
        length = 0;
        [_wrappedInputStream read:((uint8_t *)&length) + 1 maxLength:3];
        length >>= 8;
        
#if __BYTE_ORDER == __LITTLE_ENDIAN
#elif __BYTE_ORDER == __BIG_ENDIAN
#   error "Big endian is not implemented"
#else
#   error "Unknown byte order"
#endif
        
        paddingBytes = roundUpInput(length, 4) - length;
    }
    else
    {
        paddingBytes = roundUpInput(length + 1, 4) - (length + 1);
    }
    
    NSString *string = nil;
    
    if (length > 0)
    {
        uint8_t *bytes = (uint8_t *)malloc(length);
        NSInteger readLen = [_wrappedInputStream read:bytes maxLength:length];
        if (readLen != length)
        {
            
            [ACLogger debug: [NSString stringWithFormat:@"***** Couldn't read %lu bytes", (unsigned long)length]];
            
        }
        
        string = [[NSString alloc] initWithBytesNoCopy:bytes length:length encoding:NSUTF8StringEncoding freeWhenDone:true];
    }
    else
    {
        string = @"";
    }
    
    for (int i = 0; i < paddingBytes; i++)
        [_wrappedInputStream read:&tmp maxLength:1];
    
    return string;
}

- (NSString *)readString:(bool *)failed
{
    uint8_t tmp = 0;
    [_wrappedInputStream read:&tmp maxLength:1];
    
    int paddingBytes = 0;
    
    int32_t length = tmp;
    if (length == 254)
    {
        length = 0;
        [_wrappedInputStream read:((uint8_t *)&length) + 1 maxLength:3];
        length >>= 8;
        
#if __BYTE_ORDER == __LITTLE_ENDIAN
#elif __BYTE_ORDER == __BIG_ENDIAN
#   error "Big endian is not implemented"
#else
#   error "Unknown byte order"
#endif
        
        paddingBytes = roundUpInput(length, 4) - length;
    }
    else
    {
        paddingBytes = roundUpInput(length + 1, 4) - (length + 1);
    }
    
    NSString *string = nil;
    
    if (length > 0)
    {
        uint8_t *bytes = (uint8_t *)malloc(length);
        NSInteger readLen = [_wrappedInputStream read:bytes maxLength:length];
        if (readLen != length)
        {
            free(bytes);
            *failed = true;
            return nil;
        }
        
        string = [[NSString alloc] initWithBytesNoCopy:bytes length:length encoding:NSUTF8StringEncoding freeWhenDone:true];
    }
    else
    {
        string = @"";
    }
    
    for (int i = 0; i < paddingBytes; i++)
        [_wrappedInputStream read:&tmp maxLength:1];
    
    return string;
}

- (int8_t)readByte
{
    uint8_t tmp = 0;
    [_wrappedInputStream read:&tmp maxLength:1];

    return tmp;
}


- (NSData *)readBytes
{
    uint8_t tmp = 0;
    [_wrappedInputStream read:&tmp maxLength:1];
    
    int paddingBytes = 0;
    
    int32_t length = tmp;
    if (length == 254)
    {
        length = 0;
        [_wrappedInputStream read:((uint8_t *)&length) + 1 maxLength:3];
        length >>= 8;
        
        paddingBytes = roundUpInput(length, 4) - length;
    }
    else
    {
        paddingBytes = roundUpInput(length + 1, 4) - (length + 1);
    }
    
    uint8_t *bytes = (uint8_t *)malloc(length);
    NSInteger readLen = [_wrappedInputStream read:bytes maxLength:length];
    if (readLen != length)
    {
        [ACLogger debug: [NSString stringWithFormat:@"***** Couldn't read %lu bytes", (unsigned long)length]];
    }
    
    NSData *result = [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:true];
    
    for (int i = 0; i < paddingBytes; i++)
        [_wrappedInputStream read:&tmp maxLength:1];
    
    return result;
}

- (NSData *)readBytes:(bool *)failed
{
    uint8_t tmp = 0;
    [_wrappedInputStream read:&tmp maxLength:1];
    
    int paddingBytes = 0;
    
    int32_t length = tmp;
    if (length == 254)
    {
        length = 0;
        [_wrappedInputStream read:((uint8_t *)&length) + 1 maxLength:3];
        length >>= 8;
        
#if __BYTE_ORDER == __LITTLE_ENDIAN
#elif __BYTE_ORDER == __BIG_ENDIAN
#   error "Big endian is not implemented"
#else
#   error "Unknown byte order"
#endif
        
        paddingBytes = roundUpInput(length, 4) - length;
    }
    else
    {
        paddingBytes = roundUpInput(length + 1, 4) - (length + 1);
    }
    
    uint8_t *bytes = (uint8_t *)malloc(length);
    NSInteger readLen = [_wrappedInputStream read:bytes maxLength:length];
    if (readLen != length)
    {
        free(bytes);
        *failed = true;
        return nil;
    }
    
    NSData *result = [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:true];
    
    for (int i = 0; i < paddingBytes; i++)
        [_wrappedInputStream read:&tmp maxLength:1];
    
    return result;
}

@end
