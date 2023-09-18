//
//  ACMessageMo.h
//  Sugram-debug
//
//  Created by gnutech004 on 2017/2/24.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ACDialogSecretKeyMo;
@class ACPBDialogMessage;


// 消息发送状态
typedef enum {
    ACMessagePending = 0,  // 待发送
    ACMessageDelivering,   // 正在发送
    ACMessageSuccessed,    // 已发送，成功
    ACMessageFailure,      // 发送失败
    ACMessageCancel,   // 取消发送
	ACMessageNormal = 1000       // 默认状态
}ACMessageDeliveryState;


//标识消息状态，标识已接收，已读
//如果是接收的消息：接收到的状态就是已接收，并且发给请求给后台表明已接收，进入会话页就是已读，发个请求给后台表明已读。
//如果是发送的消息：发送完是一发送，对方接受了，收到通知是已接收，对方已读了收到通知是已读。
typedef enum : NSUInteger {
    ACMessageReadTypeSended = 1,//发送完
    ACMessageReadTypeReceived,//已接收
    ACMessageReadTypeReaded = 100,//已读
    ACMessageReadTypeListened = 200,//已听
    ACMessageReadTypeDestroyed = 1000,// 已销毁
} ACMessageReadType;

@class ACReferenceMessageMo;

@interface ACMessageMo : NSObject<NSCopying>

@property (nonatomic) long Property_ACMessage_remoteId; //消息在服务器端的序号
@property (nonatomic) long Property_ACMessage_localId; // 本地Id(仅仅用于发送信息与服务端匹配)
@property (nonatomic) long Property_ACMessage_msgId; //app端分配的ID(唯一本地标识ID)
@property (nonatomic) long Property_ACMessage_srcUin NS_SWIFT_NAME(swift_ACMessageMo_srcUin);//消息发件人uin
@property (nonatomic) BOOL Property_ACMessage_isOut NS_SWIFT_NAME(swift_ACMessageMo_isOut);//true表示发送出去的消息，false表示接收进来的消息
@property (nonatomic) bool Property_ACMessage_mediaFlag;//是否有多媒体内容
@property (nonatomic, copy) NSString *Property_ACMessage_objectName; // 消息类型
@property (nonatomic, copy) NSString *Property_ACMessage_mediaAttribute NS_SWIFT_NAME(swift_ACMessageMo_mediaAttribute);//多媒体属性的JSON格式
@property (nonatomic) long Property_ACMessage_msgSendTime NS_SWIFT_NAME(swift_ACMessageMo_msgSendTime);//消息发送的时间
@property (nonatomic) long Property_ACMessage_msgReceiveTime NS_SWIFT_NAME(swift_ACMessageMo_msgSendTime);//消息接收的时间
@property (nonatomic) BOOL Property_ACMessage_atFlag;
@property (nonatomic, assign) ACMessageDeliveryState Property_ACMessage_deliveryState; // 消息发送状态
@property (nonatomic, assign) ACMessageReadType Property_ACMessage_readType;//标识已接收，已读
@property (nonatomic, assign) BOOL Property_ACMessage_groupFlag;
@property (nonatomic, copy) NSString *Property_ACMessage_dialogIdStr;
@property (nonatomic, copy) NSString *Property_ACMessage_extra; // 消息的附加信息
@property (nonatomic, copy) NSString *Property_ACMessage_expansionStr; // 消息的拓展信息
@property (nonatomic) BOOL Property_ACMessage_decode;
@property (nonatomic) NSData *Property_ACMessage_originalMediaData; // 未解密的媒体数据
@property (nonatomic) BOOL Property_ACMessage_isLocal; // 是否本地消息，指未成功发送到服务器或者直接插入到数据库的消息
@property (nonatomic, assign) BOOL Property_ACMessage_isOffline;

+ (instancetype)messageCopyWithDialogMessage:(ACPBDialogMessage *)dialogMessage;

- (void)decryptWithAesKey:(ACDialogSecretKeyMo *)aesKey;

- (BOOL)isCounted;
- (NSString *)messageType;
- (NSString *)searchableWords;

+ (NSString *)loadMsgProperty_ACMessage_remoteIdKey;
+ (NSString *)loadMsgProperty_ACMessage_decodeKey;

@end
