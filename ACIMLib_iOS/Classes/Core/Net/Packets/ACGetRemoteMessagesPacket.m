//
//  ACGetRemoteMessagesPacket.m
//  ACIMLib
//
//  Created by 子木 on 2022/11/23.
//

#import "ACGetRemoteMessagesPacket.h"
#import "ACUrlConstants.h"

@interface ACGetRemoteMessagesPacket()

@property (nonatomic, assign) BOOL isSuperGroup;

@property (nonatomic, strong) NSData *data;

@end

@implementation ACGetRemoteMessagesPacket

- (instancetype)initWithDialogId:(NSString *)dialogId isSuperGroup:(BOOL)isSuperGroup oldOffset:(long)oldOffset newOffset:(long)newOffset rows:(int)rows isFromNewToOld:(BOOL)fromNewToOld {
    self = [super init];
    _isSuperGroup = isSuperGroup;
    ACPBGetHistoryMessageReq *req = [[ACPBGetHistoryMessageReq alloc] init];
    req.dialogKeys = dialogId;
    req.oldOffset = oldOffset;
    req.offset = newOffset;
    req.rows = rows;
    req.newToOld = fromNewToOld;
    _data = [req data];
    return self;
}

- (int32_t)packetUrl {
    return self.isSuperGroup ? AC_API_NAME_GetSuperGroupHistoryMessage : AC_API_NAME_GetHistoryMessage;
}

- (NSData *)packetBody {
    return self.data;
}



- (void)sendWithSuccessBlockIdParameter:(nullable void(^)(ACPBGetHistoryMessageResp * response))successBlock failure:(nullable ACSendPacketFailureBlock)failureBlock {
    [super sendWithSuccessBlockIdParameter:successBlock failure:failureBlock modelClassType:ACPBGetHistoryMessageResp.class];
}

@end
