//
//  ACMessageContent.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/16.
//

#import <Foundation/Foundation.h>
#import "ACUserInfo.h"
#import "ACStatusDefine.h"
#import "ACMentionedInfo.h"

NS_ASSUME_NONNULL_BEGIN


/*!
 消息内容的编解码协议

 @discussion 用于标示消息内容的类型，进行消息的编码和解码。
 所有自定义消息必须实现此协议，否则将无法正常传输和使用。
 
 *  \~english
 Codec protocol for message content.

 @ discussion It is used to identify the type of message content and to encode and decode the message.
  All custom messages must implement this protocol, otherwise they will not be transmitted and used properly.
 */
@protocol ACMessageCoding <NSObject>
@required

/*!
 将消息内容序列化，编码成为可传输的json数据

 @discussion
 消息内容通过此方法，将消息中的所有数据，编码成为json数据，返回的json数据将用于网络传输。
 
 *  \~english
 Serialize the message content and encode it into transportable json data.

 @ discussion
 Through this method, the message content encodes all the data in the message into json data, and the returned json data will be used for network transmission.
 */
- (NSDictionary *)encode;

/*!
 将json数据的内容反序列化，解码生成可用的消息内容

 @param data    消息中的原始json数据

 @discussion
 网络传输的json数据，会通过此方法解码，获取消息内容中的所有数据，生成有效的消息内容。
 
 */
- (void)decodeWithData:(NSDictionary *)data;

/*!
 返回消息的类型名

 @return 消息的类型名

 @discussion 您定义的消息类型名，需要在各个平台上保持一致，以保证消息互通。

 @warning 请勿使用@"AC:"开头的类型名，以免和SDK默认的消息名称冲突
 
 */
+ (NSString *)getObjectName;

@optional
/*!
 返回可搜索的关键内容列表

 @return 返回可搜索的关键内容列表

 @discussion 这里返回的关键内容列表将用于消息搜索，自定义消息必须要实现此接口才能进行搜索。
 
 */
- (NSArray<NSString *> *)getSearchableWords;

@end

/*!
 消息内容的存储协议

 @discussion 用于确定消息内容的存储策略。
 所有自定义消息必须实现此协议，否则将无法正常存储和使用。
 
 *  \~english
 Storage protocol for message content.

 @ discussion It  is used to determine the storage policy for the content of the message.
  All custom messages must implement this protocol, otherwise they will not be stored and used properly.
 */
@protocol ACMessagePersistentCompatible <NSObject>
@required

/*!
 返回消息的存储策略

 @return 消息的存储策略

 @discussion 指明此消息类型在本地是否存储、是否计入未读消息数。
 
 *  \~english
 Return the storage policy of the message.

 @ return Storage policy for messages.

 @ discussion It indicates whether this message type is stored locally and counted as unread messages.
 */
+ (ACMessagePersistent)persistentFlag;
@end

/*!
 消息内容的基类

 @discussion 此类为消息实体类 ACMessage 中的消息内容 content 的基类。
 所有的消息内容均为此类的子类，包括 SDK 自带的消息（如 ACTextMessage、ACImageMessage 等）
 
 *  \~english
 The base class of the message content.

 @ discussion This class is the base class for the message content in the message entity class RCMessage.
  All message contents are subclasses of this class, including messages that come with SDK (such as ACTextMessage, ACImageMessage, etc.)
 */
@interface ACMessageContent : NSObject <ACMessageCoding,ACMessagePersistentCompatible>

/*!
 消息内容中携带的发送者的用户信息
 
 *  \~english
 User information of the sender carried in the message content.

 */
@property (nonatomic, strong) ACUserInfo *senderUserInfo;

/*!
 消息中的 @ 提醒信息
 */
@property (nonatomic, strong) ACMentionedInfo *mentionedInfo;

/*!
 消息的附加信息
 
 *  \~english
 Additional information for messages.
 */
@property (nonatomic, copy) NSString *extra;


/**
 将用户信息编码到字典中

 @param userInfo 要编码的用户信息
 @return 存有用户信息的 Dictionary
 */
- (NSDictionary *)encodeUserInfo:(ACUserInfo *)userInfo;

/*!
 将消息内容中携带的用户信息解码

 @param dictionary 用户信息的Dictionary
 */
- (void)decodeUserInfo:(NSDictionary *)dictionary;

/*!
 消息内容的原始json数据

 @discussion 此字段存放消息内容中未编码的json数据。
 SDK内置的消息，如果消息解码失败，默认会将消息的内容存放到此字段；如果编码和解码正常，此字段会置为nil。
 */
@property (nonatomic, strong, nullable, setter=setRawJSONData:) NSData *rawJSONData;

@end

NS_ASSUME_NONNULL_END
