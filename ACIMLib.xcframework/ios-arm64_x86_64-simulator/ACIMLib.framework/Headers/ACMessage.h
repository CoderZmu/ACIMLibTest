//
//  ACMessage.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/16.
//

#import <Foundation/Foundation.h>
#import "ACStatusDefine.h"
#import "ACMessageContent.h"
#import "ACMessagePushConfig.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 消息实体类

 @discussion 消息实体类，包含消息的所有属性。
 */
@interface ACMessage : NSObject

/*!
 会话类型
 */
@property (nonatomic, assign) ACConversationType conversationType;

/*!
 会话 ID
 */
@property (nonatomic, copy) NSString *targetId;

/*!
 超级群频道Id
 */
@property (nonatomic, copy) NSString *channelId;

/*!
 消息的 ID

 @discussion 本地存储的消息的唯一值（数据库索引唯一值）
 */
@property (nonatomic, assign) long messageId;

/*!
 消息的方向
 */
@property (nonatomic, assign) ACMessageDirection messageDirection;

/*!
 消息的发送者 ID
 
 */
@property (nonatomic, assign) long senderUserId;

/*!
 消息的接收状态

 */
@property (nonatomic, assign) ACReceivedStatus receivedStatus;

/*!
 消息的发送状态
 */
@property (nonatomic, assign) ACSentStatus sentStatus;

/*!
 消息的接收时间（Unix 时间戳、毫秒）
 */
@property (nonatomic, assign) long long receivedTime;

/*!
 消息的发送时间（Unix 时间戳、毫秒）
 */
@property (nonatomic, assign) long long sentTime;


/*!
 消息的类型名
 */
@property (nonatomic, copy) NSString *objectName;

/*!
 消息的内容
 */
@property (nonatomic, strong) ACMessageContent *content;

/*!
 消息的附加字段
 */
@property (nonatomic, copy) NSString *extra;


/*!
 全局唯一 ID

 @discussion 服务器消息唯一 ID（在同一个 Appkey 下全局唯一）
 */
@property (nonatomic, assign) long messageUId;

/*!
 消息推送配置
 */
@property (nonatomic, strong) ACMessagePushConfig *messagePushConfig;

/*!
 是否是离线消息，只在接收消息的回调方法中有效，如果消息为离线消息，则为 YES ，其他情况均为 NO
 */
@property (nonatomic, assign) BOOL isOffLine;

/*!
 消息扩展信息列表
 
 @discussion 扩展信息只支持单聊和群组，其它会话类型不能设置扩展信息
 @discussion 默认消息扩展字典 key 长度不超过 32 ，value 长度不超过 4096 ，单次设置扩展数量最大为 20，消息的扩展总数不能超过 300
*/
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *expansionDic;


/*!
 ACMessage初始化方法

 @param  conversationType    会话类型
 @param  targetId            会话 ID
 @param  messageDirection    消息的方向
 @param  content             消息的内容
 
 */
- (instancetype)initWithType:(ACConversationType)conversationType
                    targetId:(NSString *)targetId
                   direction:(ACMessageDirection)messageDirection
                     content:(ACMessageContent *)content;
@end

NS_ASSUME_NONNULL_END
