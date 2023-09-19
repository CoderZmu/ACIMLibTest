//
//  ACChannelClient.h
//  ACIMLib
//
//  Created by 子木 on 2022/8/3.
//

#import <Foundation/Foundation.h>
#import "ACConversationChannelProtocol.h"
#import "ACStatusDefine.h"
#import "ACHistoryMessageOption.h"
#import "ACMessage.h"
#import "ACMessagePushConfig.h"
#import "ACSendMessageConfig.h"

NS_ASSUME_NONNULL_BEGIN

/*!
  ConversationChannel 核心类ACHistoryMessageOption
 
 @discussion 您需要通过 sharedCoreClient 方法，获取单例对象。
 */
@interface ACChannelClient : NSObject

/*!
 获取核心类单例

 @return 核心单例类
 */
+ (instancetype)sharedChannelManager;

/*!
 拉取超级群列表后回调功能
 
 超级群会话同步状态监听,要在初始化之后, 连接之前设置代理
 @param delegate 代理

 @remarks 超级群消息操作
 */

- (void)setUltraGroupConversationDelegate:(id<ACUltraGroupConversationDelegate>)delegate;

#pragma mark - 会话列表

/*!
 设置会话的置顶状态

 @param conversationType    会话类型
 @param targetId            会话 ID
 @param channelId          所属会话的业务标识
 @param isTop               是否置顶
 @return                    设置是否成功
 
 @remarks 会话
 
 */
- (BOOL)setConversationToTop:(ACConversationType)conversationType targetId:(NSString *)targetId channelId:(nullable NSString *)channelId isTop:(BOOL)isTop;


#pragma mark - 发送消息

/*!
 发送消息

 @param conversationType    发送消息的会话类型
 @param targetId            发送消息的会话 ID
 @param channelId            超级群频道ID
 @param content             消息的内容
 @param pushConfig        接收方离线时的远程推送内容
 @param successBlock        消息发送成功的回调 [messageId: 消息的 ID]
 @param errorBlock          消息发送失败的回调 [nErrorCode: 发送失败的错误码,
 messageId:消息的ID]
 @return                    发送的消息实体

 @discussion 当接收方离线并允许远程推送时，会收到远程推送。
 远程推送中包含两部分内容，一是 pushContent ，用于显示；二是 pushData ，用于携带不显示的数据。

 SDK 内置的消息类型，如果您将 pushContent 和 pushData 置为 nil ，会使用默认的推送格式进行远程推送。
 自定义类型的消息，需要您自己设置 pushContent 和 pushData 来定义推送内容，否则将不会进行远程推送。

 如果您使用此方法发送图片消息，需要您自己实现图片的上传，构建一个 ACImageMessage 对象，
 并将 ACImageMessage 中的 imageUrl 字段设置为上传成功的 URL 地址，然后使用此方法发送。

 如果您使用此方法发送文件消息，需要您自己实现文件的上传，构建一个 ACFileMessage 对象，
 并将 ACFileMessage 中的 fileUrl 字段设置为上传成功的 URL 地址，然后使用此方法发送。


 @remarks 消息操作
 
 */
- (ACMessage *)sendMessage:(ACConversationType)conversationType
                  targetId:(NSString *)targetId
                 channelId:(nullable NSString *)channelId
                   content:(ACMessageContent *)content
                pushConfig:(nullable ACMessagePushConfig *)pushConfig
                sendConfig:(ACSendMessageConfig *)sendConfig
                   success:(void (^)(long messageId))successBlock
                     error:(void (^)(ACErrorCode nErrorCode, long messageId))errorBlock;

/*!
 发送媒体消息（图片消息或文件消息）

 @param conversationType    发送消息的会话类型
 @param targetId            发送消息的会话 ID
 @param channelId            超级群频道ID
 @param content             消息的内容
 @param pushConfig        接收方离线时的远程推送内容
 @param progressBlock       消息发送进度更新的回调 [progress:当前的发送进度, 0
 <= progress <= 100, messageId:消息的 ID]f
 @param successBlock        消息发送成功的回调 [messageId:消息的 ID]
 @param errorBlock          消息发送失败的回调 [errorCode:发送失败的错误码,
 messageId:消息的 ID]
 @param cancelBlock         用户取消了消息发送的回调 [messageId:消息的 ID]
 @return                    发送的消息实体

 @discussion 当接收方离线并允许远程推送时，会收到远程推送。
 远程推送中包含两部分内容，一是 pushContent，用于显示；二是 pushData，用于携带不显示的数据。

 SDK 内置的消息类型，如果您将 pushContent 和 pushData 置为 nil，会使用默认的推送格式进行远程推送。
 自定义类型的消息，需要您自己设置 pushContent 和 pushData 来定义推送内容，否则将不会进行远程推送。

 如果您需要上传图片到自己的服务器，需要构建一个 ACImageMessage 对象，
 并将 ACImageMessage 中的 imageUrl 字段设置为上传成功的 URL 地址，然后使用 ACIMLibClient 的
 sendMessage:targetId:content:pushContent:pushData:success:error:方法
 或 sendMessage:targetId:content:pushContent:success:error:方法进行发送，不要使用此方法。

 如果您需要上传文件到自己的服务器，构建一个 ACFileMessage 对象，
 并将 ACFileMessage 中的 fileUrl 字段设置为上传成功的 URL 地址，然后使用 ACIMLibClient 的
 sendMessage:targetId:content:pushContent:pushData:success:error:方法
 或 sendMessage:targetId:content:pushContent:success:error:方法进行发送，不要使用此方法。


 @remarks 消息操作
 
 */
- (ACMessage *)sendMediaMessage:(ACConversationType)conversationType
                       targetId:(NSString *)targetId
                      channelId:(nullable NSString *)channelId
                        content:(ACMessageContent *)content
                     pushConfig:(nullable ACMessagePushConfig *)pushConfig
                     sendConfig:(ACSendMessageConfig *)sendConfig
                       progress:(void (^)(int progress, long messageId))progressBlock
                        success:(void (^)(long messageId))successBlock
                          error:(void (^)(ACErrorCode errorCode, long messageId))errorBlock
                         cancel:(void (^)(long messageId))cancelBlock;


/*!
 插入向外发送的、指定时间的消息（此方法如果 sentTime 有问题会影响消息排序，慎用！！）
（该消息只插入本地数据库，实际不会发送给服务器和对方）

 @param conversationType    会话类型
 @param targetId            会话 ID
 @param channelId            超级群频道ID
 @param sentStatus          发送状态
 @param content             消息的内容
 @param sentTime            消息发送的 Unix 时间戳，单位为毫秒（传 0 会按照本地时间插入）
 @return                    插入的消息实体

 @discussion 此方法不支持聊天室的会话类型。如果 sentTime<=0，则被忽略，会以插入时的时间为准。

 @remarks 消息操作
 
 */
- (ACMessage *)insertOutgoingMessage:(ACConversationType)conversationType
                            targetId:(NSString *)targetId
                           channelId:(nullable NSString *)channelId
                          sentStatus:(ACSentStatus)sentStatus
                             content:(ACMessageContent *)content
                            sentTime:(long long)sentTime;

/*!
 发送定向消息

 @param conversationType 发送消息的会话类型
 @param targetId         发送消息的会话 ID
 @param channelId            超级群频道ID
 @param userIdList       接收消息的用户 ID 列表
 @param content             消息的内容
 @param pushConfig        接收方离线时的远程推送内容
 @param successBlock     消息发送成功的回调 [messageId:消息的 ID]
 @param errorBlock       消息发送失败的回调 [errorCode:发送失败的错误码,
 messageId:消息的 ID]

 @return 发送的消息实体

 @discussion 此方法用于在群组和讨论组中发送消息给其中的部分用户，其它用户不会收到这条消息。

 @warning 此方法目前仅支持群组和讨论组。

 @remarks 消息操作
 
 */
- (ACMessage *)sendDirectionalMessage:(ACConversationType)conversationType
                             targetId:(NSString *)targetId
                            channelId:(nullable NSString *)channelId
                         toUserIdList:(NSArray *)userIdList
                              content:(ACMessageContent *)content
                           pushConfig:(nullable ACMessagePushConfig *)pushConfig
                           sendConfig:(ACSendMessageConfig *)sendConfig
                              success:(void (^)(long messageId))successBlock
                                error:(void (^)(ACErrorCode nErrorCode, long messageId))errorBlock;


#pragma mark - 消息操作
/*!
 * \~chinese
 获取历史消息

 @param conversationType    会话类型
 @param targetId            会话 ID
 @param channelId          所属会话的业务标识
 @param option              可配置的参数
 @param complete        获取成功的回调 [messages：获取到的历史消息数组； code : 获取是否成功，0表示成功，非 0 表示失败]
 
 @discussion count 传入 1~100 之间的数值。
 @discussion option.order == ACHistoryMessageOrderDesc && option.recordTime == 0 可以获取最新的消息
 @discussion 此方法先从本地获取历史消息，本地有缺失的情况下会从服务端同步缺失的部分。当本地没有更多消息的时候，会从服务器拉取
 @discussion 从服务端同步失败的时候会返回非 0 的 errorCode，同时把本地能取到的消息回调上去。

 @remarks 消息操作
 */
- (void)getMessages:(ACConversationType)conversationType
           targetId:(NSString *)targetId
          channelId:(nullable NSString *)channelId
             option:(ACHistoryMessageOption *)option
           complete:(void (^)(NSArray<ACMessage *> *messages, ACErrorCode code))complete;

/*!
 清除历史消息

 @param conversationType    会话类型
 @param targetId            会话 ID
 @param channelId          所属会话的业务标识
 @param recordTime          清除消息时间戳，【0 <= recordTime <= 当前会话最后一条消息的 sentTime,0
 清除所有消息，其他值清除小于等于 recordTime 的消息】
 @param clearRemote         是否同时删除服务端消息
 @param successBlock        获取成功的回调
 @param errorBlock          获取失败的回调 [ status:清除失败的错误码]

 @discussion
 此方法可以清除服务器端历史消息和本地消息，如果清除服务器端消息必须先开通历史消息云存储功能。
 例如，您不想从服务器上获取更多的历史消息，通过指定 recordTime 并设置 clearRemote 为 YES
 清除消息，成功后只能获取该时间戳之后的历史消息。如果 clearRemote 传 NO，
 只会清除本地消息。

 @remarks 消息操作
 
 */
- (void)clearHistoryMessages:(ACConversationType)conversationType
                    targetId:(NSString *)targetId
                   channelId:(nullable NSString *)channelId
                  recordTime:(long long)recordTime
                 clearRemote:(BOOL)clearRemote
                     success:(void (^)(void))successBlock
                       error:(void (^)(ACErrorCode status))errorBlock;

/*!
 从服务器端获取之前的历史消息

 @param conversationType    会话类型
 @param targetId            会话 ID
 @param channelId          所属会话的业务标识
 @param recordTime          截止的消息发送时间戳，毫秒
 @param count               需要获取的消息数量， 0 < count <= 20
 @param complete        获取成功的回调 [messages：获取到的历史消息数组； code : 获取是否成功，0表示成功，非 0 表示失败]

 @discussion
 例如，本地会话中有10条消息，您想拉取更多保存在服务器的消息的话，recordTime 应传入最早的消息的发送时间戳，count 传入
 2~20 之间的数值。


 @remarks 消息操作
 */
- (void)getRemoteHistoryMessages:(ACConversationType)conversationType
                        targetId:(NSString *)targetId
                       channelId:(nullable NSString *)channelId
                      recordTime:(long long)recordTime
                           count:(int)count
                         complete:(void (^)(NSArray<ACMessage *> *messages, ACErrorCode code))complete;

/*!
 获取会话中@提醒自己的消息

 @param conversationType    会话类型
 @param targetId            会话 ID
 @param channelId          所属会话的业务标识

 @discussion
 此方法从本地获取被@提醒的消息(最多返回 10 条信息)

 @remarks 高级功能
 */
- (NSArray<ACMessage *> *)getUnreadMentionedMessages:(ACConversationType)conversationType targetId:(NSString *)targetId channelId:(nullable NSString *)channelId;

/**
 * 异步去获取会话里第一条未读消息。
 *
 * @param conversationType 会话类型
 * @param targetId   会话 ID
 * @param channelId          所属会话的业务标识
 * @param complete        获取完成的回调
 *
 * @remarks 消息操作
 */
- (void)getFirstUnreadMessageAsynchronously:(ACConversationType)conversationType targetId:(NSString *)targetId channelId:(nullable NSString *)channelId complete:(void (^)(ACMessage *message, ACErrorCode code))complete;

/*!
 删除某个会话中的所有消息

 @param conversationType    会话类型，不支持聊天室
 @param targetId            会话 ID
 @param channelId          所属会话的业务标识
 @param successBlock        成功的回调
 @param errorBlock          失败的回调

 @discussion 此方法删除数据库中该会话的消息记录，同时会整理压缩数据库，减少占用空间

 @remarks 消息操作
 */
- (void)deleteMessages:(ACConversationType)conversationType
              targetId:(NSString *)targetId
             channelId:(nullable NSString *)channelId
               success:(void (^)(void))successBlock
                 error:(void (^)(ACErrorCode status))errorBlock;


#pragma mark - 未读消息数
/*!
 获取某个会话内的未读消息数（聊天室会话除外）

 @param conversationType    会话类型
 @param targetId            会话目标 ID
 @param channelId          所属会话的业务标识
 @return                    该会话内的未读消息数

 @remarks 会话
 */
- (int)getUnreadCount:(ACConversationType)conversationType targetId:(NSString *)targetId channelId:(nullable NSString *)channelId;


/*!
 清除某个会话中的所有未读消息数

 @param conversationType    会话类型，不支持聊天室
 @param targetId            会话 ID
 @param channelId          所属会话的业务标识
 @return                    是否清除成功

 @discussion 此方法不支持超级群的会话类型。
 *
 @remarks 会话

 */
- (BOOL)clearAllMessagesUnreadStatus:(ACConversationType)conversationType
                         targetId:(NSString *)targetId channelId:(nullable NSString *)channelId;

/*!
 清除某个会话中的未读消息数（该会话在时间戳 timestamp 之前的消息将被置成已读。）

 @param conversationType    会话类型，不支持聊天室
 @param targetId            会话 ID
 @param channelId          所属会话的业务标识
 @param timestamp           该会话已阅读的最后一条消息的发送时间戳
 @return                    是否清除成功

 @discussion 此方法不支持超级群的会话类型。
 *
 @remarks 会话

 */
- (BOOL)clearMessagesUnreadStatus:(ACConversationType)conversationType
                         targetId:(NSString *)targetId
                        channelId:(nullable NSString *)channelId
                             time:(long long)timestamp;



#pragma mark - 会话的消息提醒

/*!
 设置会话的消息提醒状态

 @param conversationType            会话类型
 @param targetId                    会话 ID
 @param channelId                   所属会话的业务标识
 @param level                       消息通知级别
 @param successBlock                设置成功的回调
 @param errorBlock                  设置失败的回调 [status:设置失败的错误码]

 @discussion
 如果您需要移除消息通知，level参数传入RCPushNotificationLevelDefault即可
  
 @remarks 会话
 */
- (void)setConversationChannelNotificationLevel:(ACConversationType)conversationType
                                       targetId:(NSString *)targetId
                                      channelId:(NSString *)channelId
                                          level:(ACPushNotificationLevel)level
                                        success:(void (^)(void))successBlock
                                          error:(void (^)(ACErrorCode status))errorBlock;

/*!
 设置一组会话的消息提醒状态

 @param conversationType            会话类型
 @param targetIdList                    会话 ID列表
 @param level                       消息通知级别
 @param successBlock                设置成功的回调
 @param errorBlock                  设置失败的回调 [status:设置失败的错误码]

 @discussion
 如果您需要移除消息通知，level参数传入RCPushNotificationLevelDefault即可
  
 @remarks 会话
 */
- (void)setConversationListNotificationLevel:(ACConversationType)conversationType
                                       targetIdList:(NSArray *)targetIdList
                                          level:(ACPushNotificationLevel)level
                                        success:(void (^)(void))successBlock
                                          error:(void (^)(ACErrorCode status))errorBlock;


/*!
  查询消息通知级别

 @param conversationType    会话类型
 @param targetId            会话 ID
 @param channelId           所属会话的业务标识
 @param successBlock        设置成功的回调 [level:消息通知级别]
 @param errorBlock          查询失败的回调 [status:设置失败的错误码]

 @remarks 会话
 */
- (void)getConversationChannelNotificationLevel:(ACConversationType)conversationType
                                       targetId:(NSString *)targetId
                                      channelId:(NSString *)channelId
                                        success:(void (^)(ACPushNotificationLevel level))successBlock
                                          error:(void (^)(ACErrorCode status))errorBlock;

#pragma mark - 搜索

/*!
 根据关键字搜索指定会话中的本地消息

 @param conversationType 会话类型
 @param targetId         会话 ID
 @param channelId          所属会话的业务标识
 @param keyword          关键字
 @param count            最大的查询数量
 @param startTime        查询 startTime 之前的消息（传 0 表示不限时间）

 @return 匹配的消息列表
 *
 @discussion 此方法搜索超级群拿到的数据会断层

 @remarks 消息操作
 
 */
- (NSArray<ACMessage *> *)searchMessages:(ACConversationType)conversationType
                                targetId:(NSString *)targetId
                               channelId:(nullable NSString *)channelId
                                 keyword:(NSString *)keyword
                                   count:(int)count
                               startTime:(long long)startTime;

@end

NS_ASSUME_NONNULL_END
