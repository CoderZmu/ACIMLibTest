//
//  ACCoreClient.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/16.
//


#import <Foundation/Foundation.h>
#import "ACIMClientProtocol.h"
#import "ACMessageHeader.h"
#import "ACMessagePushConfig.h"
#import "ACPushProfile.h"
#import "ACSendMessageConfig.h"
#import "ACStatusDefine.h"
#import "ACHistoryMessageOption.h"

@class ACMessage, ACConversation;

NS_ASSUME_NONNULL_BEGIN

typedef void (^ACConnectDbOpenedBlock)(ACDBErrorCode code);
typedef void (^ACConnectSuccessBlock)(NSString *userId);
typedef void (^ACConnectErrorBlock)(ACConnectErrorCode errorCode);

@interface ACCoreClient : NSObject

@property (nonatomic, assign, readonly) BOOL isUserDataInitialized;
/**
   远程推送相关设置

   @remarks 功能设置

 *  \~english
   Remote push of related settings

   @ remarks Function setting
 */
@property (nonatomic, strong, readonly) ACPushProfile *pushProfile;

+ (ACCoreClient *)sharedCoreClient;

#pragma mark - SDK init

/*!
   初始化 SDK

   @param appKey  应用后唯一标识 App Key
   @discussion 初始化后，SDK 会监听 app 生命周期， 用于判断应用处于前台、后台，根据前后台状态调整链接心跳
   @discussion
   您在使用 SDK 所有功能（ 包括显示 SDK 中或者继承于 SDK 的 View ）之前，您必须先调用此方法初始化 SDK。
   在 App 整个生命周期中，您只需要执行一次初始化。

 */
- (void)initWithAppKey:(NSString *)appKey;

/**
   设置IM Server服务地址
 */
- (void)setServerInfo:(NSString *)imServer;

/*!
   设置 deviceToken（已兼容 iOS 13），用于远程推送

   @param deviceTokenData     从系统获取到的设备号 deviceTokenData  (不需要处理)

   @discussion
   deviceToken 是系统提供的，从苹果服务器获取的，用于 APNs 远程推送必须使用的设备唯一值。
   您需要将 -application:didRegisterForRemoteNotificationsWithDeviceToken: 获取到的 deviceToken 作为参数传入此方法。

   如:

   - (void)application:(UIApplication *)application
   didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
       [[ACCoreClient sharedCoreClient] setDeviceTokenData:deviceToken];
   }
   @remarks 功能设置

 */
- (void)setDeviceTokenData:(NSData *)deviceTokenData;


/*!
   设置 deviceToken，用于远程推送

   @param deviceToken     从系统获取到的设备号 deviceToken

   @discussion
   deviceToken 是系统提供的，从苹果服务器获取的，用于 APNs 远程推送必须使用的设备唯一值。
   您需要将 -application:didRegisterForRemoteNotificationsWithDeviceToken: 获取到的
   deviceToken，转换成十六进制字符串，作为参数传入此方法。

   如:

    - (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
        NSString *token = [self getHexStringForData:deviceToken];
        [[ACCoreClient sharedCoreClient] setDeviceToken:token];
    }

    - (NSString *)getHexStringForData:(NSData *)data {
        NSUInteger len = [data length];
        char *chars = (char *)[data bytes];
        NSMutableString *hexString = [[NSMutableString alloc] init];
        for (NSUInteger i = 0; i < len; i ++) {
            [hexString appendString:[NSString stringWithFormat:@"%0.2hhx", chars[i]]];
        }
        return hexString;
     }

   @remarks 功能设置
 */
- (void)setDeviceToken:(NSString *)deviceToken;

/*!
   与SDK服务器建立连接

   @param token                   从您服务器端获取的 token (用户身份令牌)
   @param successBlock            连接建立成功的回调 [ userId: 当前连接成功所用的用户 ID]
   @param errorBlock              连接建立失败的回调，触发该回调代表 SDK 无法继续重连 [errorCode: 连接失败的错误码]

   @discussion 调用该接口，SDK 会在连接失败之后尝试重连，直到连接成功或者出现 SDK 无法处理的错误（如 token 非法）。
   如果您不想一直进行重连，可以使用 connectWithToken:timeLimit:dbOpened:success:error: 接口并设置连接超时时间 timeLimit。

   @discussion 连接成功后，SDK 将接管所有的重连处理。当因为网络原因断线的情况下，SDK 会不停重连直到连接成功为止，不需要您做额外的连接操作。

   对于 errorBlock 需要特定关心 tokenIncorrect 的情况：
   一是 token 错误，请您检查客户端初始化使用的 AppKey 和您服务器获取 token 使用的 AppKey 是否一致；
   二是 token 过期，是因为您在开发者后台设置了 token 过期时间，您需要请求您的服务器重新获取 token 并再次用新的 token 建立连接。
   在此种情况下，您需要请求您的服务器重新获取 token 并建立连接，但是注意避免无限循环，以免影响 App 用户体验。

 此方法的回调并非为原调用线程，您如果需要进行 UI 操作，请注意切换到主线程。
 */
- (void)connectWithToken:(NSString *)token
                 success:(ACConnectSuccessBlock)successBlock
                   error:(ACConnectErrorBlock)errorBlock;


/*!
   与SDK服务器建立连接

   @param token                   从您服务器端获取的 token (用户身份令牌)
   @param dbOpenedBlock                本地消息数据库打开的回调
   @param successBlock            连接建立成功的回调 [ userId: 当前连接成功所用的用户 ID]
   @param errorBlock              连接建立失败的回调，触发该回调代表 SDK 无法继续重连 [errorCode: 连接失败的错误码]

   @discussion 调用该接口，SDK 会在连接失败之后尝试重连，直到连接成功或者出现 SDK 无法处理的错误（如 token 非法）。
   如果您不想一直进行重连，可以使用 connectWithToken:timeLimit:dbOpened:success:error: 接口并设置连接超时时间 timeLimit。

   @discussion 连接成功后，SDK 将接管所有的重连处理。当因为网络原因断线的情况下，SDK 会不停重连直到连接成功为止，不需要您做额外的连接操作。

   对于 errorBlock 需要特定关心 tokenIncorrect 的情况：
   一是 token 错误，请您检查客户端初始化使用的 AppKey 和您服务器获取 token 使用的 AppKey 是否一致；
   二是 token 过期，是因为您在开发者后台设置了 token 过期时间，您需要请求您的服务器重新获取 token 并再次用新的 token 建立连接。
   在此种情况下，您需要请求您的服务器重新获取 token 并建立连接，但是注意避免无限循环，以免影响 App 用户体验。

 此方法的回调并非为原调用线程，您如果需要进行 UI 操作，请注意切换到主线程。
 */
- (void)connectWithToken:(NSString *)token
                dbOpened:(nullable ACConnectDbOpenedBlock)dbOpenedBlock
                 success:(nullable ACConnectSuccessBlock)successBlock
                   error:(nullable ACConnectErrorBlock)errorBlock;

/*!
   与SDK服务器建立连接

   @param token                   从您服务器端获取的 token (用户身份令牌)
   @param timeLimit               SDK 连接的超时时间，单位: 秒
                        timeLimit <= 0，SDK 会一直连接，直到连接成功或者出现 SDK 无法处理的错误（如 token 非法）。
                        timeLimit > 0，SDK 最多连接 timeLimit 秒，超时时返回 AC_CONNECT_TIMEOUT 错误，并不再重连。
   @param dbOpenedBlock                本地消息数据库打开的回调
   @param successBlock            连接建立成功的回调 [ userId: 当前连接成功所用的用户 ID]
   @param errorBlock              连接建立失败的回调，触发该回调代表 SDK 无法继续重连 [errorCode: 连接失败的错误码]

   @discussion 调用该接口，SDK 会在 timeLimit 秒内尝试重连，直到出现下面三种情况之一：
   第一、连接成功，回调 successBlock(userId)。
   第二、超时，回调 errorBlock(RC_CONNECT_TIMEOUT)。
   第三、出现 SDK 无法处理的错误，回调 errorBlock(errorCode)（如 token 非法）。

   @discussion 连接成功后，SDK 将接管所有的重连处理。当因为网络原因断线的情况下，SDK 会不停重连直到连接成功为止，不需要您做额外的连接操作。

   对于 errorBlock 需要特定关心 tokenIncorrect 的情况：
   一是 token 错误，请您检查客户端初始化使用的 AppKey 和您服务器获取 token 使用的 AppKey 是否一致；
   二是 token 过期，是因为您在开发者后台设置了 token 过期时间，您需要请求您的服务器重新获取 token 并再次用新的 token 建立连接。
   在此种情况下，您需要请求您的服务器重新获取 token 并建立连接，但是注意避免无限循环，以免影响 App 用户体验。

 此方法的回调并非为原调用线程，您如果需要进行 UI 操作，请注意切换到主线程。
 */
- (void)connectWithToken:(NSString *)token
               timeLimit:(int)timeLimit
                dbOpened:(nullable ACConnectDbOpenedBlock)dbOpenedBlock
                 success:(nullable ACConnectSuccessBlock)successBlock
                   error:(nullable ACConnectErrorBlock)errorBlock;

/*!
   断开与SDK服务器的连接

   @param isReceivePush   App 在断开连接之后，是否还接收远程推送

   @discussion
   因为 SDK 在前后台切换或者网络出现异常都会自动重连，会保证连接的可靠性。
   所以除非您的 App 逻辑需要登出，否则一般不需要调用此方法进行手动断开。

   isReceivePush 指断开与融云服务器的连接之后，是否还接收远程推送。
 *
   @remarks 连接

 */
- (void)disconnect:(BOOL)isReceivePush;

/*!
 断开与SDK服务器的连接，但仍然接收远程推送

 @discussion
 因为 SDK 在前后台切换或者网络出现异常都会自动重连，会保证连接的可靠性。
 所以除非您的 App 逻辑需要登出，否则一般不需要调用此方法进行手动断开。

 @warning 如果您使用 IMLib，请使用此方法断开与融云服务器的连接；
 如果您使用 IMKit，请使用 RCIM 中的同名方法断开与融云服务器的连接，而不要使用此方法。

 [[ACIMClient shared] disconnect:YES] 与 [[ACIMClient shared]
 disconnect] 完全一致；
 [[ACIMClient shared] disconnect:NO] 与 [[ACIMClient shared]
 logout] 完全一致。
 您只需要按照您的需求，使用 disconnect: 与 disconnect 以及 logout 三个接口其中一个即可。

 @remarks 连接
 */
- (void)disconnect;

/*!
 断开与SDK服务器的连接，并不再接收远程推送

 @discussion
 因为 SDK 在前后台切换或者网络出现异常都会自动重连，会保证连接的可靠性。
 所以除非您的 App 逻辑需要登出，否则一般不需要调用此方法进行手动断开。

 [[ACIMClient shared] disconnect:YES] 与 [[ACIMClient shared]
 disconnect] 完全一致；
 [[ACIMClient shared] disconnect:NO] 与 [[ACIMClient shared]
 logout] 完全一致。
 您只需要按照您的需求，使用 disconnect: 与 disconnect 以及 logout 三个接口其中一个即可。

 @remarks 连接
 */
- (void)logout;


#pragma mark - ACConnectionStatusChangeDelegate

/*!
   设置 IMLibClient 的连接状态监听器

   @param delegate    IMLibClient 连接状态监听器

   @remarks 功能设置

 */
- (void)setACConnectionStatusChangeDelegate:(id<ACConnectionStatusChangeDelegate>)delegate;

/*!
 添加 IMLib 连接状态监听

 @param delegate 代理
 */
- (void)addConnectionStatusChangeDelegate:(id<ACConnectionStatusChangeDelegate>)delegate;

/*!
 移除 IMLib 连接状态监听

 @param delegate 代理
 */
- (void)removeConnectionStatusChangeDelegate:(id<ACConnectionStatusChangeDelegate>)delegate;

/*!
   获取当前 SDK 的连接状态

   @return 当前 SDK 的连接状态

   @remarks 数据获取

 */
- (ACConnectionStatus)getConnectionStatus;

#pragma mark - Conversation List

/*!
   获取会话列表

   @param conversationTypeList   会话类型的数组(需要将 ACConversationType 转为 NSNumber 构建 NSArray)
   @return                        会话 ACConversation 的列表

   @discussion 此方法会从本地数据库中，读取会话列表。
   返回的会话列表按照时间从前往后排列，如果有置顶的会话，则置顶的会话会排列在前面。
   @discussion 当您的会话较多且没有清理机制的时候，强烈建议您使用 getConversationList: count: startTime:
   分页拉取会话列表,否则有可能造成内存过大。

   @remarks 会话列表

 */
- (NSArray *)getConversationList:(NSArray *)conversationTypeList;


/*!
   分页获取会话列表

   @param conversationTypeList 会话类型的数组(需要将 RCConversationType 转为 NSNumber 构建 NSArray)
   @param count                获取的数量（当实际取回的会话数量小于 count 值时，表明已取完数据）
   @param startTime            会话的时间戳（获取这个时间戳之前的会话列表，0表示从最新开始获取）
   @return                     会话 RCConversation 的列表

   @discussion 此方法会从本地数据库中，读取会话列表。
   返回的会话列表按照时间从前往后排列，如果有置顶的会话，则置顶的会话会排列在前面。
   @discussion 传递的startTime > 0，忽略置顶的会话

   @remarks 会话列表

 */
- (NSArray *)getConversationList:(NSArray *)conversationTypeList count:(int)count startTime:(long long)startTime;

/*!
   获取单个会话数据

   @param conversationType    会话类型
   @param targetId            会话 ID
   @return                    会话的对象

   @remarks 会话

 */
- (ACConversation *)getConversation:(ACConversationType)conversationType targetId:(NSString *)targetId;


/*!
   从本地存储中删除会话

   @param conversationType    会话类型
   @param targetId            会话 ID
   @return                    是否删除成功

   @discussion
   此方法会从本地存储中删除该会话，但是不会删除会话中的消息。如果此会话中有新的消息，该会话将重新在会话列表中显示，并显示最近的历史消息。

   @remarks 会话

 */
- (BOOL)removeConversation:(ACConversationType)conversationType targetId:(NSString *)targetId;

/*!
   设置会话的置顶状态

   @param conversationType    会话类型
   @param targetId            会话 ID
   @param isTop               是否置顶
   @return                    设置是否成功

   @remarks 会话

 */
- (BOOL)setConversationToTop:(ACConversationType)conversationType targetId:(NSString *)targetId isTop:(BOOL)isTop;

/*!
   获取置顶的会话列表

   @param conversationTypeList 会话类型的数组(需要将 ACConversationType 转为 NSNumber 构建 NSArray)
   @return                     置顶的会话 ACConversation 的列表

   @discussion 此方法会从本地数据库中，读取置顶的会话列表。

   @remarks 会话列表

 */
- (NSArray<ACConversation *> *)getTopConversationList:(NSArray *)conversationTypeList;


#pragma mark - 会话中的草稿操作
/*!
 获取会话中的草稿信息（用户输入但未发送的暂存消息）

 @param conversationType    会话类型
 @param targetId            会话目标 ID
 @return                    该会话中的草稿

 @remarks 会话
 */
- (nullable NSString *)getTextMessageDraft:(ACConversationType)conversationType targetId:(NSString *)targetId;

/*!
 保存草稿信息（用户输入但未发送的暂存消息）

 @param conversationType    会话类型
 @param targetId            会话目标 ID
 @param content             草稿信息
 @return                    是否保存成功

 @remarks 会话
 */
- (BOOL)saveTextMessageDraft:(ACConversationType)conversationType
                    targetId:(NSString *)targetId
                     content:(NSString *)content;

/*!
 删除会话中的草稿信息（用户输入但未发送的暂存消息）

 @param conversationType    会话类型
 @param targetId            会话目标 ID
 @return                    是否删除成功

 @remarks 会话
 */
- (BOOL)clearTextMessageDraft:(ACConversationType)conversationType targetId:(NSString *)targetId;


#pragma mark - Unread Count

/*!
   获取所有的未读消息数

   @return    所有的未读消息数

   @remarks 会话

 */
- (int)getTotalUnreadCount;

/*!
   获取某个会话内的未读消息数

   @param conversationType    会话类型
   @param targetId            会话目标 ID
   @return                    该会话内的未读消息数

   @remarks 会话

 */
- (int)getUnreadCount:(ACConversationType)conversationType targetId:(NSString *)targetId;

/*!
   获取某个类型的会话中所有的未读消息数

   @param conversationTypes   会话类型的数组
   @return                    该类型的会话中所有的未读消息数

   @remarks 会话

 */
- (int)getUnreadCountWithConTypes:(NSArray *)conversationTypes;


/*!
   清除某个会话中的未读消息数

   @param conversationType    会话类型，不支持聊天室
   @param targetId            会话 ID
   @return                    是否清除成功

   @discussion 此方法不支持超级群的会话类型。
 *
   @remarks 会话

 */
- (BOOL)clearAllMessagesUnreadStatus:(ACConversationType)conversationType
                            targetId:(NSString *)targetId;

/*!
   清除某个会话中的未读消息数（该会话在时间戳 timestamp 之前的消息将被置成已读。）

   @param conversationType    会话类型，不支持聊天室
   @param targetId            会话 ID
   @param timestamp           该会话已阅读的最后一条消息的发送时间戳
   @return                    是否清除成功

   @discussion 此方法不支持超级群的会话类型。
 *
   @remarks 会话

 */
- (BOOL)clearMessagesUnreadStatus:(ACConversationType)conversationType
                         targetId:(NSString *)targetId
                             time:(long long)timestamp;


#pragma mark - Message Send

/*!
 注册自定义的消息类型

 @param messageClass    自定义消息的类，该自定义消息需要继承于 ACMessageContent

 @discussion
 如果您需要自定义消息，必须调用此方法注册该自定义消息的消息类型，否则 SDK 将无法识别和解析该类型消息。
 @discussion 请在初始化 appkey 之后，token 连接之前调用该方法注册自定义消息


 @remarks 消息操作
 */
- (void)registerMessageType:(Class)messageClass;

/*!
   发送消息

   @param conversationType    发送消息的会话类型
   @param targetId            发送消息的会话 ID
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
                   content:(ACMessageContent *)content
                pushConfig:(nullable ACMessagePushConfig *)pushConfig
                sendConfig:(nullable ACSendMessageConfig *)sendConfig
                   success:(void (^)(long messageId))successBlock
                     error:(void (^)(ACErrorCode nErrorCode, long messageId))errorBlock;

/*!
   发送媒体消息（图片消息或文件消息）

   @param conversationType    发送消息的会话类型
   @param targetId            发送消息的会话 ID
   @param content             消息的内容
   @param pushConfig        接收方离线时的远程推送内容
   @param progressBlock       消息发送进度更新的回调 [progress:当前的发送进度, 0
   <= progress <= 100, messageId:消息的 ID]
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
                        content:(ACMessageContent *)content
                     pushConfig:(nullable ACMessagePushConfig *)pushConfig
                     sendConfig:(nullable ACSendMessageConfig *)sendConfig
                       progress:(void (^)(int progress, long messageId))progressBlock
                        success:(void (^)(long messageId))successBlock
                          error:(void (^)(ACErrorCode errorCode, long messageId))errorBlock
                         cancel:(void (^)(long messageId))cancelBlock;

/*!
 发送消息
 
 @param message             将要发送的消息实体（需要保证 message 中的 conversationType，targetId，messageContent 是有效值)
 @param successBlock        消息发送成功的回调 [successMessage: 消息实体]
 @param errorBlock          消息发送失败的回调 [nErrorCode: 发送失败的错误码, errorMessage:消息实体]
 @return                    发送的消息实体
 
 如果您使用此方法发送图片消息，需要您自己实现图片的上传，构建一个 ACImageMessage 对象，
 并将 ACImageMessage 中的 remoteUrl 字段设置为上传成功的 URL 地址，然后使用此方法发送。
 
 如果您使用此方法发送文件消息，需要您自己实现文件的上传，构建一个 ACFileMessage 对象，
 并将 ACFileMessage 中的 remoteUrl 字段设置为上传成功的 URL 地址，然后使用此方法发送。
 
 
 @remarks 消息操作
 */
- (ACMessage *)sendMessage:(ACMessage *)message
              successBlock:(void (^)(ACMessage *successMessage))successBlock
                errorBlock:(void (^)(ACErrorCode nErrorCode, ACMessage *errorMessage))errorBlock;


/*!
 发送媒体消息（图片消息或文件消息）
 
 @param message             将要发送的消息实体（需要保证 message 中的 conversationType，targetId，messageContent 是有效值)
 @param progressBlock       消息发送进度更新的回调 [progress:当前的发送进度, 0 <= progress <= 100, progressMessage:消息实体]
 @param successBlock        消息发送成功的回调 [successMessage:消息实体]
 @param errorBlock          消息发送失败的回调 [nErrorCode:发送失败的错误码, errorMessage:消息实体]
 @param cancelBlock         用户取消了消息发送的回调 [cancelMessage:消息实体]
 @return                    发送的消息实体

 
 如果您需要上传图片到自己的服务器，需要构建一个 ACImageMessage 对象，
 并将 ACImageMessage 中的 remoteUrl 字段设置为上传成功的 URL 地址，然后使用 ACIMClient 的
 sendMessage:targetId:content:pushContent:pushData:success:error:方法
 或 sendMessage:targetId:content:pushContent:success:error:方法进行发送，不要使用此方法。
 
 如果您需要上传文件到自己的服务器，构建一个 ACFileMessage 对象，
 并将 ACFileMessage 中的 remoteUrl 字段设置为上传成功的 URL 地址，然后使用 ACIMClient 的
 sendMessage:targetId:content:pushContent:pushData:success:error:方法
 或 sendMessage:targetId:content:pushContent:success:error:方法进行发送，不要使用此方法。
 
 
 @remarks 消息操作
 */
- (ACMessage *)sendMediaMessage:(ACMessage *)message
                       progress:(void (^)(int progress, ACMessage *progressMessage))progressBlock
                   successBlock:(void (^)(ACMessage *successMessage))successBlock
                     errorBlock:(void (^)(ACErrorCode nErrorCode, ACMessage *errorMessage))errorBlock
                         cancel:(void (^)(ACMessage *cancelMessage))cancelBlock;

/*!
 取消发送中的媒体信息

 @param messageId           媒体消息的 messageId

 @return YES 表示取消成功，NO 表示取消失败，即已经发送成功或者消息不存在。

 @remarks 消息操作
 */
- (BOOL)cancelSendMediaMessage:(long)messageId;

/*!
   发送定向消息

   @param conversationType 发送消息的会话类型
   @param targetId         发送消息的会话 ID
   @param userIdList       接收消息的用户 ID 列表
   @param content          消息的内容
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
                         toUserIdList:(NSArray *)userIdList
                              content:(ACMessageContent *)content
                           pushConfig:(ACMessagePushConfig *)pushConfig
                           sendConfig:(ACSendMessageConfig *)sendConfig
                              success:(void (^)(long messageId))successBlock
                                error:(void (^)(ACErrorCode nErrorCode, long messageId))errorBlock;

/*!
 发送定向消息

 @param message 消息实体
 @param userIdList       接收消息的用户 ID 列表
 @param successBlock     消息发送成功的回调 [successMessage:发送成功的消息]
 @param errorBlock       消息发送失败的回调 [nErrorCode:发送失败的错误码,errorMessage:发送失败的消息]

 @return 发送的消息实体

 @discussion 此方法用于在群组和讨论组中发送消息给其中的部分用户，其它用户不会收到这条消息。

 @warning 此方法目前仅支持普通群组和讨论组。

 @remarks 消息操作
 */
- (ACMessage *)sendDirectionalMessage:(ACMessage *)message
                         toUserIdList:(NSArray *)userIdList
                         successBlock:(void (^)(ACMessage *successMessage))successBlock
                           errorBlock:(void (^)(ACErrorCode nErrorCode, ACMessage *errorMessage))errorBlock;


/*!
   插入向外发送的、指定时间的消息（此方法如果 sentTime 有问题会影响消息排序，慎用！！）
   （该消息只插入本地数据库，实际不会发送给服务器和对方）

   @param conversationType    会话类型
   @param targetId            会话 ID
   @param sentStatus          发送状态
   @param content             消息的内容
   @param sentTime            消息发送的 Unix 时间戳，单位为毫秒（传 0 会按照本地时间插入）
   @return                    插入的消息实体

   @discussion 此方法不支持聊天室的会话类型。如果 sentTime<=0，则被忽略，会以插入时的时间为准。

   @remarks 消息操作

 */
- (ACMessage *)insertOutgoingMessage:(ACConversationType)conversationType
                            targetId:(NSString *)targetId
                          sentStatus:(ACSentStatus)sentStatus
                             content:(ACMessageContent *)content
                            sentTime:(long long)sentTime;

/*!
   下载消息内容中的媒体信息

   @param messageId           媒体消息的 messageId
   @param progressBlock       消息下载进度更新的回调 [progress:当前的下载进度, 0 <= progress <= 100]
   @param successBlock        下载成功的回调[mediaPath:下载成功后本地存放的文件路径]
   @param errorBlock          下载失败的回调[errorCode:下载失败的错误码]
   @param cancelBlock         用户取消了下载的回调

   @discussion 用来获取媒体原文件时调用。如果本地缓存中包含此文件，则从本地缓存中直接获取，否则将从服务器端下载。

   @remarks 多媒体下载
 */
- (void)downloadMediaMessage:(long)messageId
                    progress:(void (^)(int progress))progressBlock
                     success:(void (^)(NSString *mediaPath))successBlock
                       error:(void (^)(ACErrorCode errorCode))errorBlock
                      cancel:(void (^)(void))cancelBlock;

/*!
   取消下载中的媒体信息

   @param messageId 媒体消息的messageId

   @return YES 表示取消成功，NO表示取消失败，即已经下载完成或者消息不存在。

   @remarks 多媒体下载
 */
- (BOOL)cancelDownloadMediaMessage:(long)messageId;


#pragma mark - Conversation Notification

/*!
   设置会话的消息提醒状态

   @param conversationType            会话类型
   @param targetId                    会话 ID
   @param isBlocked                   是否屏蔽消息提醒
   @param successBlock                设置成功的回调
   [nStatus:会话设置的消息提醒状态]
   @param errorBlock                  设置失败的回调 [status:设置失败的错误码]


   @remarks 会话

 */
- (void)setConversationNotificationStatus:(ACConversationType)conversationType
                                 targetId:(NSString *)targetId
                                isBlocked:(BOOL)isBlocked
                                  success:(void (^)(ACConversationNotificationStatus nStatus))successBlock
                                    error:(void (^)(ACErrorCode status))errorBlock;

/*!
   查询会话的消息提醒状态

   @param conversationType    会话类型（不支持聊天室，聊天室是不接受会话消息提醒的）
   @param targetId            会话 ID
   @param successBlock        查询成功的回调 [nStatus:会话设置的消息提醒状态]
   @param errorBlock          查询失败的回调 [status:设置失败的错误码]

   @remarks 会话

 */
- (void)getConversationNotificationStatus:(ACConversationType)conversationType
                                 targetId:(NSString *)targetId
                                  success:(void (^)(ACConversationNotificationStatus nStatus))successBlock
                                    error:(void (^)(ACErrorCode status))errorBlock;

/*!
   获取消息免打扰会话列表

   @param conversationTypeList 会话类型的数组(需要将 ACConversationType 转为 NSNumber 构建 NSArray)
   @return                     消息免打扰会话 RCConversation 的列表

   @discussion 此方法会从本地数据库中，读取消息免打扰会话列表。

   @remarks 会话列表

 */
- (NSArray<ACConversation *> *)getBlockedConversationList:(NSArray *)conversationTypeList;

#pragma mark - ACIMClientReceiveMessageDelegate

/*!
 设置 IMLib 的消息接收监听器

 @param delegate    IMLibCore 消息接收监听器
 @param userData    用户自定义的监听器 Key 值，可以为 nil


 @remarks 功能设置
 */
- (void)setReceiveMessageDelegate:(id<ACIMClientReceiveMessageDelegate>)delegate object:(nullable id)userData;

/*!
 添加 IMLib 接收消息监听

 @param delegate 代理
 */
- (void)addReceiveMessageDelegate:(id<ACIMClientReceiveMessageDelegate>)delegate;

/*!
 移除 IMLib 接收消息监听

 @param delegate 代理
 */
- (void)removeReceiveMessageDelegate:(id<ACIMClientReceiveMessageDelegate>)delegate;


#pragma mark - Message Recall

/*!
   撤回消息

   @param message      需要撤回的消息
   @param pushContent 当下发 push 消息时，在通知栏里会显示这个字段，不设置将使用默认推送内容
   @param successBlock 撤回成功的回调 [messageId:撤回的消息 ID，该消息已经变更为新的消息]
   @param errorBlock   撤回失败的回调 [errorCode:撤回失败错误码]

 */
- (void)recallMessage:(ACMessage *)message
          pushContent:(NSString *)pushContent
              success:(void (^)(long messageId))successBlock
                error:(void (^)(ACErrorCode errorcode))errorBlock;


#pragma mark - Message Operation

/*!
 获取会话中，从指定消息之前、指定数量的最新消息实体

 @param conversationType    会话类型
 @param targetId            会话 ID
 @param oldestMessageId     截止的消息 ID [0或-1 代表从最近的发送时间查起]
 @param count               需要获取的消息数量
 @return                    消息实体 RCMessage 对象列表

 @discussion
 此方法会获取该会话中，oldestMessageId 之前的、指定数量的最新消息实体，返回的消息实体按照时间从新到旧排列。
 返回的消息中不包含 oldestMessageId 对应那条消息，如果会话中的消息数量小于参数 count 的值，会将该会话中的所有消息返回。
 如：
 oldestMessageId 为 10，count 为 2，会返回 messageId 为 9 和 8 的 ACMessage 对象列表。

 @discussion 此方法不支持超级群的会话类型。
 
 @remarks 消息操作
 */
- (NSArray<ACMessage *> *)getHistoryMessages:(ACConversationType)conversationType
                                    targetId:(NSString *)targetId
                             oldestMessageId:(long)oldestMessageId
                                       count:(int)count;

/*!
 获取会话中，从指定消息之前、指定数量的、指定消息类型的最新消息实体

 @param conversationType    会话类型
 @param targetId            会话 ID
 @param objectName          消息内容的类型名，如果想取全部类型的消息请传 nil
 @param oldestMessageId     截止的消息 ID [0或-1 代表从最近的发送时间查起]
 @param count               需要获取的消息数量
 @return                    消息实体 RCMessage 对象列表

 @discussion
 此方法会获取该会话中，oldestMessageId 之前的、指定数量和消息类型的最新消息实体，返回的消息实体按照时间从新到旧排列。
 返回的消息中不包含 oldestMessageId 对应的那条消息，如果会话中的消息数量小于参数 count
 的值，会将该会话中的所有消息返回。
 如：oldestMessageId 为 10，count 为 2，会返回 messageId 为 9 和 8 的 RCMessage 对象列表。

 @discussion 此方法不支持超级群的会话类型。
 
 @remarks 消息操作
 */
- (NSArray<ACMessage *> *)getHistoryMessages:(ACConversationType)conversationType
                                    targetId:(NSString *)targetId
                                  objectName:(nullable NSString *)objectName
                             oldestMessageId:(long)oldestMessageId
                                       count:(int)count;

/*!
   获取会话中，指定消息、指定数量、指定消息类型、向前或向后查找的消息实体列表

   @param conversationType    会话类型
   @param targetId            会话 ID
   @param objectName          消息内容的类型名，如果想取全部类型的消息请传 nil
   @param baseMessageId       当前的消息 ID
   @param isForward           查询方向 true 为向前，false 为向后
   @param count               需要获取的消息数量
   @return                    消息实体 ACMessage 对象列表

   @discussion
   isForward:true 获取该会话中，oldestMessageId 之前的、指定数量的最新消息实体，返回的消息实体按照时间从新到旧排列。
   isForward:false 获取该会话中，oldestMessageId 之后的、指定数量的最新消息实体，返回的消息实体按照时间从旧到新排列。
   返回的消息中不包含 oldestMessageId 对应那条消息，如果会话中的消息数量小于参数 count 的值，会将该会话中的所有消息返回。

   @discussion 此方法不支持超级群的会话类型。

   @remarks 消息操作

 */
- (NSArray<ACMessage *> *)getHistoryMessages:(ACConversationType)conversationType
                       targetId:(NSString *)targetId
                     objectName:(nullable NSString *)objectName
                  baseMessageId:(long)baseMessageId
                      isForward:(BOOL)isForward
                          count:(int)count;



/*!
   获取会话中，指定时间、指定数量、指定消息类型（多个）、向前或向后查找的消息实体列表
 * 返回的消息列表中会包含指定的消息。消息列表时间顺序从新到旧。

   @param conversationType    会话类型
   @param targetId            会话 ID
   @param objectNames         消息内容的类型名称列表
   @param sentTime             当前的消息时间戳
   @param isForward           查询方向 true 为向前，false 为向后
   @param count               需要获取的消息数量
   @return                    消息实体 ACMessage 对象列表

   @discussion
   此方法会获取该会话中，sentTime
   之前或之后的、指定数量、指定消息类型（多个）的消息实体列表
   isForward：true, 向前查询老消息 返回的消息按照sentTime降序排序，如果sentTime对象的消息不存在，则返回最新的消息;  false 往后查询新消息，返回的消息按照sentTime升序排序
   查询老消息如果传递过来的recordTime对应的message不存在，返回最新的消息
   返回的消息中包含 sentTime 对应的那条消息，如果会话中的消息数量小于参数 count 的值，会将该会话中的所有消息返回。

   @discussion 超级群不会接收离线消息，超级群调用该接口会出现消息断档的情况，请使用断档消息接口获取超级群消息。

   @remarks 消息操作

 */
- (NSArray<ACMessage *> *)getHistoryMessages:(ACConversationType)conversationType
                       targetId:(NSString *)targetId
                    objectNames:(NSArray<NSString *> *)objectNames
                       sentTime:(long long)sentTime
                      isForward:(BOOL)isForward
                          count:(int)count;


/*!
   清除历史消息

   @param conversationType    会话类型
   @param targetId            会话 ID
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
                  recordTime:(long long)recordTime
                 clearRemote:(BOOL)clearRemote
                     success:(void (^)(void))successBlock
                       error:(void (^)(ACErrorCode status))errorBlock;

/*!
   从服务器端获取之前的历史消息

   @param conversationType    会话类型
   @param targetId            会话 ID
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
                      recordTime:(long long)recordTime
                           count:(int)count
                        complete:(void (^)(NSArray<ACMessage *> *messages, ACErrorCode code))complete;

/*!
 获取历史消息

 @param conversationType    会话类型
 @param targetId            会话 ID
 @param option              可配置的参数
 @param complete        获取成功的回调 [messages：获取到的历史消息数组； code : 获取是否成功，0表示成功，非 0 表示失败

 @discussion 必须开通历史消息云存储功能。
 @discussion count 传入 2~20 之间的数值。
 @discussion 此方法先从本地获取历史消息，本地有缺失的情况下会从服务端同步缺失的部分。
 @discussion 从服务端同步失败的时候会返回非 0 的 errorCode，同时把本地能取到的消息回调上去。

 @remarks 消息操作
 */
- (void)getMessages:(ACConversationType)conversationType
           targetId:(NSString *)targetId
             option:(ACHistoryMessageOption *)option
           complete:(nullable void (^)(NSArray<ACMessage *> * _Nullable messages, ACErrorCode code))complete;

/*!
   获取会话中@提醒自己的消息

   @param conversationType    会话类型
   @param targetId            会话 ID

   @discussion
   此方法从本地获取被@提醒的消息(最多返回 10 条信息)

   @remarks 高级功能
 */
- (NSArray<ACMessage *> *)getUnreadMentionedMessages:(ACConversationType)conversationType targetId:(NSString *)targetId;

/*!
   通过 messageId 获取消息实体

   @param messageId   消息 ID（数据库索引唯一值）
   @return            通过消息 ID 获取到的消息实体，当获取失败的时候，会返回 nil。

   @remarks 消息操作

 */
- (ACMessage *)getMessage:(long)messageId;

/*!
   通过全局唯一 ID 获取消息实体

   @param messageUId   全局唯一 ID（服务器消息唯一 ID）
   @return 通过全局唯一ID获取到的消息实体，当获取失败的时候，会返回 nil。

   @remarks 消息操作
 */
- (ACMessage *)getMessageByUId:(long)messageUId;

/**
 * 获取会话里第一条未读消息。
 *
 * @param conversationType 会话类型
 * @param targetId   会话 ID
 * @return 第一条未读消息的实体。
 * @remarks 消息操作
 * @discussion 前提：超级群会话不接收离线消息。
 *  用户在线接收的超级群未读消息已经保存到本地数据库，可以通过此接口获取到
 *  用户离线的超级群未读消息，用户在线之后不收离线未读消息，通过此接口获取第一条未读消息为空
 */
- (ACMessage *)getFirstUnreadMessage:(ACConversationType)conversationType targetId:(NSString *)targetId;

/*!
   删除消息

   @param messageIds  消息 ID 的列表，元素需要为 NSNumber 类型
   @return            是否删除成功

   @remarks 消息操作

 */
- (BOOL)deleteMessages:(NSArray<NSNumber *> *)messageIds;

/*!
   删除某个会话中的所有消息

   @param conversationType    会话类型，不支持聊天室
   @param targetId            会话 ID
   @param successBlock        成功的回调
   @param errorBlock          失败的回调

   @discussion 此方法删除数据库中该会话的消息记录，同时会整理压缩数据库，减少占用空间

   @remarks 消息操作

 */
- (void)deleteMessages:(ACConversationType)conversationType
              targetId:(NSString *)targetId
               success:(void (^)(void))successBlock
                 error:(void (^)(ACErrorCode status))errorBlock;



/*!
   设置消息的发送状态

   @param messageId       消息 ID
   @param sentStatus      消息的发送状态
   @return                是否设置成功

   @discussion 用于 UI 展示消息为正在发送，对方已接收等状态。

   @remarks 消息操作

 */
- (BOOL)setMessageSentStatus:(long)messageId sentStatus:(ACSentStatus)sentStatus;


/*!
   设置消息的接收状态

   @param messageId       消息 ID
   @param receivedStatus  消息的接收状态
   @return                是否设置成功

   @discussion 用于 UI 展示消息为已读，已下载等状态。

   @remarks 消息操作
 */
- (BOOL)setMessageReceivedStatus:(long)messageId receivedStatus:(ACReceivedStatus)receivedStatus;

#pragma mark - Search

/*!
   根据关键字搜索指定会话中的消息

   @param conversationType 会话类型
   @param targetId         会话 ID
   @param keyword          关键字
   @param count            最大的查询数量
   @param startTime        查询 startTime 之前的消息（传 0 表示不限时间）

   @return 匹配的消息列表

   @remarks 消息操作

 */
- (NSArray<ACMessage *> *)searchMessages:(ACConversationType)conversationType
                                targetId:(NSString *)targetId
                                 keyword:(NSString *)keyword
                                   count:(int)count
                               startTime:(long long)startTime;

#pragma mark - 消息扩展
/**
   更新消息扩展信息

   @param expansionDic 要更新的消息扩展信息键值对
   @param messageId 消息 messageId
   @param successBlock 成功的回调
   @param errorBlock 失败的回调

   @discussion 消息扩展信息是以字典形式存在。设置的时候从 expansionDic 中读取 key，如果原有的扩展信息中 key 不存在则添加新的 KV 对，如果 key 存在则替换成新的 value。
   @discussion 扩展信息只支持单聊和群组，其它会话类型不能设置扩展信息
   @discussion 扩展信息字典中的 Key 支持大小写英文字母、数字、部分特殊符号 + = - _ 的组合方式，最大长度 32；Value 最长长度，单次设置扩展数量最大为 20，消息的扩展总数不能超过 300

   @remarks 高级功能
 */
- (void)updateMessageExpansion:(NSDictionary<NSString *, NSString *> *)expansionDic
                     messageId:(long)messageId
                       success:(void (^)(void))successBlock
                         error:(void (^)(ACErrorCode status))errorBlock;

#pragma mark - 日志
- (void)reportLogs;


#pragma mark - 工具类方法
/*!
   获取当前 IMLibClient SDK的版本号

   @return 当前 IMLibClient SDK 的版本号，如: @"2.0.0"

   @remarks 数据获取
 */
+ (NSString *)getVersion;


@end

NS_ASSUME_NONNULL_END

