//
//  ACMessageMo.m
//  Sugram-debug
//
//  Created by gnutech004 on 2017/2/24.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import "ACMessageMo.h"
#import "ACBase.h"
#import "AcpbGlobalStructure.pbobjc.h"
#import "ACHelper.h"
#import "ACSecretKey.h"
#import "ACMessageType.h"
#import "ACMessageSerializeSupport.h"
#import "ACDialogSecretKeyMo.h"

@implementation ACMessageMo

- (instancetype)init {
    if (self = [super init]) {
		_Property_ACMessage_readType = ACMessageReadTypeSended;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)__unused zone
{
    ACMessageMo *copyMessage = [[ACMessageMo alloc] init];
    copyMessage->_Property_ACMessage_remoteId = _Property_ACMessage_remoteId;
    copyMessage->_Property_ACMessage_localId = _Property_ACMessage_localId;
    copyMessage->_Property_ACMessage_msgId = _Property_ACMessage_msgId;
   
    copyMessage->_Property_ACMessage_srcUin = _Property_ACMessage_srcUin;
    copyMessage->_Property_ACMessage_isOut = _Property_ACMessage_isOut;
    copyMessage->_Property_ACMessage_mediaFlag = _Property_ACMessage_mediaFlag;
    copyMessage->_Property_ACMessage_objectName = _Property_ACMessage_objectName;
    copyMessage->_Property_ACMessage_mediaAttribute = _Property_ACMessage_mediaAttribute;
    copyMessage->_Property_ACMessage_msgSendTime = _Property_ACMessage_msgSendTime;
    copyMessage->_Property_ACMessage_msgReceiveTime = _Property_ACMessage_msgReceiveTime;
    copyMessage->_Property_ACMessage_atFlag = _Property_ACMessage_atFlag;
    
    copyMessage->_Property_ACMessage_deliveryState = _Property_ACMessage_deliveryState;
    copyMessage->_Property_ACMessage_readType = _Property_ACMessage_readType;
    
    copyMessage->_Property_ACMessage_dialogIdStr = _Property_ACMessage_dialogIdStr;
    copyMessage->_Property_ACMessage_groupFlag = _Property_ACMessage_groupFlag;
    copyMessage->_Property_ACMessage_decode = _Property_ACMessage_decode;
    
	return copyMessage;

}



- (void)setProperty_ACMessage_ReadType:(ACMessageReadType)readType {
	if (_Property_ACMessage_readType == ACMessageReadTypeReaded) {
		return;
	}
	_Property_ACMessage_readType = readType;
}


+ (instancetype)messageCopyWithDialogMessage:(ACPBDialogMessage *)dialogMessage {
	ACMessageMo *message = [[[self class] alloc] init];
	message.Property_ACMessage_remoteId = dialogMessage.msgId;
	message.Property_ACMessage_localId = dialogMessage.localId;
	message.Property_ACMessage_srcUin = dialogMessage.srcId;
	message.Property_ACMessage_isOut = dialogMessage.isOut;
	message.Property_ACMessage_mediaFlag = dialogMessage.mediaFlag;
	message.Property_ACMessage_objectName = dialogMessage.objectName;
	message.Property_ACMessage_atFlag = dialogMessage.atFlag;
    message.Property_ACMessage_msgSendTime = dialogMessage.seqno;
    message.Property_ACMessage_extra = dialogMessage.extra;
    if (dialogMessage.msgContent.length) {
        message.Property_ACMessage_originalMediaData = dialogMessage.msgContent;
    } else {
        message.Property_ACMessage_decode = YES;
        message.Property_ACMessage_mediaAttribute = dialogMessage.msgPreContent;
    }
	return message;
}



- (void)decryptWithAesKey:(ACDialogSecretKeyMo *)aesKey {
    if (self.Property_ACMessage_decode) return;
    if (!self.Property_ACMessage_originalMediaData.length) return;

    if (aesKey) {
        NSString* decodeMediaAttribute = [NSString ac_aes128_decrypted_stringFromData:self.Property_ACMessage_originalMediaData withKey:aesKey.aesKey withIV:aesKey.aesIv];
        self.Property_ACMessage_mediaAttribute = decodeMediaAttribute? decodeMediaAttribute:self.Property_ACMessage_mediaAttribute;
        
        if ([ACHelper isEmptyString:decodeMediaAttribute]){
            self.Property_ACMessage_decode = NO;
        } else {
            self.Property_ACMessage_decode = YES;
            self.Property_ACMessage_originalMediaData = nil;
        }
    } else {
        self.Property_ACMessage_decode = NO;
    }
}

- (BOOL)isCounted {
    return [[ACMessageSerializeSupport shared] messageShouldCounted:self.Property_ACMessage_objectName];
}

- (NSString *)messageType {
    return [[ACMessageSerializeSupport shared] getMessageType:self];
}

- (NSString *)searchableWords {
    NSArray *arr = [[ACMessageSerializeSupport shared] getSearchableWords:self];
    if (!arr.count) return nil;
    return [arr componentsJoinedByString:[NSString stringWithFormat:@"%c",31]]; // 31 单元分隔符
}


+ (NSString *)loadMsgProperty_ACMessage_remoteIdKey {
    return @"Property_ACMessage_remoteId";
}

+ (NSString *)loadMsgProperty_ACMessage_decodeKey {
    return @"Property_ACMessage_decode";
}


- (NSString *)description {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    [info ac_setSafeObject:@(self.Property_ACMessage_remoteId) forKey:@"remoteId"];
    [info ac_setSafeObject:@(self.Property_ACMessage_msgId) forKey:@"msgId"];
    [info ac_setSafeObject:@(self.Property_ACMessage_localId) forKey:@"localId"];
    [info ac_setSafeObject:@(self.Property_ACMessage_isOut) forKey:@"isOut"];
    [info ac_setSafeObject:@(self.Property_ACMessage_decode) forKey:@"decode"];
    [info ac_setSafeObject:@(self.Property_ACMessage_deliveryState) forKey:@"deliveryState"];
    [info ac_setSafeObject:@(self.Property_ACMessage_mediaFlag) forKey:@"mediaFlag"];
    [info ac_setSafeObject:@(self.Property_ACMessage_srcUin) forKey:@"srcUin"];
    [info ac_setSafeObject:self.Property_ACMessage_objectName forKey:@"mediaConstructor"];
    [info ac_setSafeObject:self.Property_ACMessage_mediaAttribute forKey:@"mediaAttribute"];
    [info ac_setSafeObject:@(self.Property_ACMessage_msgSendTime) forKey:@"msgSendTime"];
    [info ac_setSafeObject:self.Property_ACMessage_dialogIdStr forKey:@"dialogId"];
    [info ac_setSafeObject:@(self.Property_ACMessage_groupFlag) forKey:@"groupFlag"];
    [info ac_setSafeObject:self.Property_ACMessage_extra forKey:@"extra"];
    return [NSString stringWithFormat:@"<%@: %p, %@>",self.class, self,info];
}
@end
