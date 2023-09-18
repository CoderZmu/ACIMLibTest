//
//  ACGetNewMessagesPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACGetNewMessagesPacket.h"
#import "ACUrlConstants.h"

@interface ACGetNewMessagesPacket()

@property (nonatomic, strong) NSData *data;

@end

@implementation ACGetNewMessagesPacket

- (instancetype)initWithOffset:(long)offset rows:(int)rows {
    self = [super init];
    ACPBGetNewMessageReq *newMessage = [[ACPBGetNewMessageReq alloc] init];
    newMessage.offset = offset;
    newMessage.rows = rows;
    _data = [newMessage data];
    return self;
}

- (int32_t)packetUrl {
    return AC_API_NAME_GetNewAllMessage;
}

- (NSData *)packetBody {
    return self.data;
}


- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBGetNewMessageResp * response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock {
    [super sendWithSuccessBlockIdParameter:successBlock failure:failureBlock modelClassType:ACPBGetNewMessageResp.class];
}

@end
