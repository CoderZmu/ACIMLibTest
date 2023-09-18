//
//  ACStatusDefine.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/16.
//

#ifndef ACStatusDefine_h
#define ACStatusDefine_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark ACConnectErrorCode
/*!
 *  \~chinese
 建立连接返回的错误码
 
 *  \~english
 Error code returned by establishing a connection
 */
typedef NS_ENUM(NSInteger, ACConnectErrorCode) {

    /*!
     *  \~chinese
     AppKey 错误

     @discussion 请检查您使用的 AppKey 是否正确。
     
     *  \~english
     AppKey error.

     @ discussion Please check that you are using the correct AppKey.
     */
    AC_CONN_ID_REJECT = 31002,

    /*!
     *  \~chinese
     Token 无效

     @discussion 请检查客户端初始化使用的 AppKey 和您服务器获取 token 使用的 AppKey 是否一致。
     @discussion 您可能需要请求您的服务器重新获取 token，并使用新的 token 建立连接。
     
     *  \~english
     Invalid Token.

     @ discussion Token is generally invalid for two reasons.
          The first is the token error. Please check whether the AppKey used by the client initialization is consistent with the AppKey used by your server to obtain the token.
     Second, the token expires because you set the token expiration time in the developer background. You shall request your server to retrieve the token and use the new token again to establish a connection.
     */
    AC_CONN_TOKEN_INCORRECT = 31004,

    /*!
     *  \~chinese
     用户被封禁

     @discussion 请检查您使用的 Token 是否正确，以及对应的 UserId 是否被封禁。
     
     *  \~english
     Users are blocked.

     @ discussion Please check whether the Token you are using is correct and whether the corresponding UserId is blocked.
     */
    AC_CONN_USER_BLOCKED = 31009,

    /*!
     *  \~chinese
     用户被踢下线

      @discussion 当前用户在其他设备上登录，此设备被踢下线
     
     *  \~english
     The user is kicked offline.

     @ discussion The current user logs in on another device, and this device is kicked offline.
     */
    AC_DISCONN_KICK = 31010,
    
    /*!
     *  \~chinese
     token 已过期
     
     @discussion 您可能需要请求您的服务器重新获取 token，并使用新的 token 建立连接。
    
    *  \~english
     The token has expired

     @Discussion you may need to request your server to retrieve the token and establish a connection with the new token.
     */
    AC_CONN_TOKEN_EXPIRE = 31020,

    /*!
     *  \~chinese
     用户在其它设备上登录

      @discussion 重连过程中当前用户在其它设备上登录
     
     *  \~english
     The user logs in on another device.

     @ discussion The current user logs in on another device during the reconnection process.
     */
    AC_CONN_OTHER_DEVICE_LOGIN = 31023,

    /*!
     *  \~chinese
     SDK 没有初始化

     @discussion 在使用 SDK 任何功能之前，必须先 Init。
     
     *  \~english
     SDK is not initialized.

     @ discussion It must Init before using any SDK functionality.
     */
    AC_CLIENT_NOT_INIT = 33001,
    
    /*!
     *  \~chinese
     数据库错误
     
     
     *  \~english
     Database error.
     */
    AC_DATABASE_ERROR = 33002,

    /*!
     *  \~chinese
     开发者接口调用时传入的参数错误

     @discussion 请检查接口调用时传入的参数类型和值。
     
     *  \~english
     The parameter passed in when the developer interface is called is incorrect.

     @ discussion Please check the parameter types and values passed in when the interface is called.
     */
    AC_INVALID_PARAMETER = 33003,

    /*!
     *  \~chinese
     Connection 已经存在

     @discussion
     调用过connect之后，只有在 token 错误或者被踢下线或者用户 logout 的情况下才需要再次调用 connect。其它情况下 SDK
     会自动重连，不需要应用多次调用 connect 来保持连接。
     
     *  \~english
     Connection already exists.

     @ discussion
     After calling connect, connect is called again only if there is a token error, or the user is kicked off, or the user logs out. In other cases, SDK will automatically reconnect, and an application need not call connect multiple times to maintain the connection.
     */
    AC_CONNECTION_EXIST = 34001,

    /*!
     *  \~chinese
     连接超时。

    @discussion 当调用 connectWithToken:timeLimit:dbOpened:success:error:  接口，timeLimit 为有效值时，SDK 在 timeLimit 时间内还没连接成功返回此错误。
     
     *  \~english
     The connection timed out.

         @ discussion When  connectWithToken:timeLimit:dbOpened:success:error:  Interface is called, if timeLimit is a valid value and SDK has not been connected successfully within timeLimit time. This error is returned.
    */
    AC_CONNECT_TIMEOUT = 34006,
  
};

#pragma mark - ACDBErrorCode
typedef NS_ENUM(NSInteger, ACDBErrorCode) {
    ACDBOpenSuccess = 0,
    ACDBOpenFailed = 33002,
};

#pragma mark - ACConnectionStatus
/*!
 *  \~chinese
 网络连接状态码
 
 *  \~english
 Network connection status code.
 */
typedef NS_ENUM(NSInteger, ACConnectionStatus) {
    /*!
     *  \~chinese
     未知状态

     @discussion 建立连接中出现异常的临时状态，SDK 会做好自动重连，开发者无须处理。
     
     *  \~english
     Unknown state.

     @ discussion If an abnormal temporary state occurs during the connection establishment, SDK will reconnect automatically and developers need not deal with it.
     */
    ConnectionStatus_UNKNOWN = -1,

    /*!
     *  \~chinese
     连接成功
     
     *  \~english
     Connected successfully
     */
    ConnectionStatus_Connected = 0,

    /*!
     *  \~chinese
     连接过程中，当前设备网络不可用

     @discussion 当网络恢复可用时，SDK 会做好自动重连，开发者无须处理。
     
     *  \~english
     The current device network is not available during connection.

     @ discussion When the network is available, SDK will reconnect automatically, so developers don't have to deal with it.
     */
    ConnectionStatus_NETWORK_UNAVAILABLE = 1,

    /*!
     *  \~chinese
     当前用户在其他设备上登录，此设备被踢下线
     
     *  \~english
     The current user is logged in on another device, and this device is kicked off the line.
     */
    ConnectionStatus_KICKED_OFFLINE_BY_OTHER_CLIENT = 6,

    /*!
     *  \~chinese
     连接中
     
     *  \~english
     Connecting
     */
    ConnectionStatus_Connecting = 10,

    /*!
     *  \~chinese
     连接失败或未连接
     
     *  \~english
     Connection failed or not connected.
     */
    ConnectionStatus_Unconnected = 11,

    /*!
     *  \~chinese
     已登出
     
     *  \~english
     Logged out.
     */
    ConnectionStatus_SignOut = 12,

    /*!
     *  \~chinese
     连接暂时挂起（多是由于网络问题导致），SDK 会在合适时机进行自动重连
     
     *  \~english
     Connection is temporarily suspended (mostly due to network problems that cause) and SDK will reconnect automatically at the appropriate time.
    */
    ConnectionStatus_Suspend = 13,

    /*!
     *  \~chinese
     自动连接超时，SDK 将不会继续连接，用户需要做超时处理，再自行调用 connectWithToken 接口进行连接
     
     *  \~english
     Automatic connection timeout, SDK will not continue to connect, users shall do timeout handling, and the connectWithToken interface is called to connect.
    */
    ConnectionStatus_Timeout = 14,

    /*!
     *  \~chinese
     Token无效

     @discussion
     Token 无效一般有两种原因。一是 token 错误，请您检查客户端初始化使用的 AppKey 和您服务器获取 token 使用的 AppKey
     是否一致；二是 token 过期，是因为您在开发者后台设置了 token 过期时间，您需要请求您的服务器重新获取 token
     并再次用新的 token 建立连接。
     
     *  \~english
     Invalid Token.

     @ discussion
     Generally there are two reasons why Token is invalid. One is the token error. Please check the AppKey used by the client initialization and the AppKey used by your server to obtain the token.
     Whether it is consistent; Second, the token expires because you set the token expiration time in the developer background, and you shall request your server to retrieve the token and establish a connection with the new token again.
     */
    ConnectionStatus_TOKEN_INCORRECT = 15,

    /*!
     *  \~chinese
     与服务器的连接已断开,用户被封禁
     
     *  \~english
     The connection to the server has been disconnected and the user is blocked.
     */
    ConnectionStatus_DISCONN_EXCEPTION = 16
};


#pragma mark ACConversationType
/*!
 *  \~chinese
 会话类型
 
 *  \~english
 Conversation type
 */
typedef NS_ENUM(NSUInteger, ACConversationType) {
    /*!
     *  \~chinese
     单聊
     
     *  \~english
     Chat alone
     */
    ConversationType_PRIVATE = 1,
    
    /*!
     *  \~chinese
     讨论组
     
     *  \~english
     Discussion group
     */
    ConversationType_DISCUSSION = 2,

    /*!
     *  \~chinese
     群组
     
     *  \~english
     Group
     */
    ConversationType_GROUP = 3,
    
    /*!
     超级群
     */
    ConversationType_ULTRAGROUP = 10,
};


#pragma mark ACConversationNotificationStatus
/*!
 *  \~chinese
 会话提醒状态
 
 *  \~english
 Conversation reminder status
 */
typedef NS_ENUM(NSUInteger, ACConversationNotificationStatus) {
    /*!
     *  \~chinese
     免打扰
     
     *  \~english
     Do not disturb
     */
    DO_NOT_DISTURB = 0,

    /*!
     *  \~chinese
     新消息提醒
     
     *  \~english
     New message reminder
     */
    NOTIFY = 1,
};


#pragma mark ACMessagePersistent
/*!
 *  \~chinese
 消息的存储策略
 
 *  \~english
 Storage strategy of messages
 */
typedef NS_ENUM(NSUInteger, ACMessagePersistent) {
    /*!
     *  \~chinese
     在本地不存储，不计入未读数
     
     *  \~english
     It is not stored locally and is not counted as unread number
     */
    MessagePersistent_NONE = 0,

    /*!
     *  \~chinese
     在本地只存储，但不计入未读数
     
     *  \~english
     Only stored locally, but not counted as unread number
     */
    MessagePersistent_ISPERSISTED = 1,

    /*!
     *  \~chinese
     在本地进行存储并计入未读数
     
     *  \~english
     Store locally and count as unread number
     */
    MessagePersistent_ISCOUNTED = 3,

    /*!
     *  \~chinese
     在本地不存储，不计入未读数，并且如果对方不在线，服务器会直接丢弃该消息，对方如果之后再上线也不会再收到此消息。

     @discussion 一般用于发送输入状态之类的消息，该类型消息的messageUId为nil。
     
     *  \~english
     It is not stored locally and is not counted into unread number. If the other party is not online, the server will directly discard the message, and the other party will not receive the message if it goes online later.

          @ discussion It is typically used to send messages such as input status, and the messageUId for this type of message is nil.
     */
    MessagePersistent_STATUS = 16
};


#pragma mark ACMessageDirection
/*!
 *  \~chinese
 消息的方向
 
 *  \~english
 The direction of the message.
 */
typedef NS_ENUM(NSUInteger, ACMessageDirection) {
    /*!
     *  \~chinese
     发送
     
     *  \~english
     Send
     */
    MessageDirection_SEND = 1,

    /*!
     *  \~chinese
     接收
     
     *  \~english
     Receive
     */
    MessageDirection_RECEIVE = 2
};



#pragma mark ACReceivedStatus
/*!
 *  \~chinese
 消息的接收状态
 
 *  \~english
 The receiving status of the message
 */
typedef NS_ENUM(NSUInteger, ACReceivedStatus) {
    /*!
     *  \~chinese
     未读
     
     *  \~english
     Unread
     */
    ReceivedStatus_UNREAD = 0,

    /*!
     *  \~chinese
     已读
     
     *  \~english
     Read
     */
    ReceivedStatus_READ = 1,
    
    /*!
     已听

     @discussion 仅用于语音消息
     */
    ReceivedStatus_LISTENED = 2,
};


#pragma mark ACSentStatus
/*!
 *  \~chinese
 消息的发送状态
 
 *  \~english
 The sending status of the message
 */
typedef NS_ENUM(NSUInteger, ACSentStatus) {
    /*!
     *  \~chinese
     发送中
     
     *  \~english
     Sending
     */
    SentStatus_SENDING = 10,

    /*!
     *  \~chinese
     发送失败
     
     *  \~english
     Failed to send
     */
    SentStatus_FAILED = 20,

    /*!
     *  \~chinese
     已发送成功
     
     *  \~english
     Sent successfully
     */
    SentStatus_SENT = 30,

    /*!
     *  \~chinese
     对方已接收
     
     *  \~english
     The other party has received
     */
    SentStatus_RECEIVED = 40,

    /*!
     *  \~chinese
     对方已阅读
     
     *  \~english
     The other party has read
     */
    SentStatus_READ = 50,

    /*!
     *  \~chinese
     对方已销毁
     
     *  \~english
     The other party has been destroyed
     */
    SentStatus_DESTROYED = 60,

    /*!
     *  \~chinese
     发送已取消
     
     *  \~english
     Sending is canceled
     */
    SentStatus_CANCELED = 70,

    /*!
     *  \~chinese
     无效类型
     
     *  \~english
     Invalid type
     */
    SentStatus_INVALID
};

#pragma mark ACMentionedType - 消息中@提醒的类型
/*!
 @提醒的类型
 */
typedef NS_ENUM(NSUInteger, ACMentionedType) {
    /*!
     @ 所有人
     */
    AC_Mentioned_All = 1,

    /*!
     @ 部分指定用户
     */
    AC_Mentioned_Users = 2,
};

#pragma mark ACErrorCode
/*!
 具体业务错误码
 */
typedef NS_ENUM(NSInteger, ACErrorCode) {
    /*!
     成功
     */
    AC_SUCCESS = 0,
    
    /*!
     未知错误（预留）
     */
    ERRORCODE_UNKNOWN = -1,

    /*!
     已被对方加入黑名单，消息发送失败。
     */
    REJECTED_BY_BLACKLIST = 405,
    

    /*!
     超时
     */
    ERROACODE_TIMEOUT = 5004,

    /*!
    消息加密失败
     */
    MSG_ENCRYPT_ERROR = 6001,
    
    /*!
     发送消息频率过高，1 秒钟最多只允许发送 5 条消息
     */
    SEND_MSG_FREQUENCY_OVERRUN = 20604,
    
    /*!
     发送的消息中包含敏感词 （发送方发送失败，接收方不会收到消息）
     */
    AC_MSG_BLOCKED_SENSITIVE_WORD = 21501,

    /*!
     消息中敏感词已经被替换 （接收方可以收到被替换之后的消息）
     */
    AC_MSG_REPLACED_SENSITIVE_WORD = 21502,

    /*!
     当前用户不在该群组中
     */
    NOT_IN_GROUP = 22406,

    /*!
     当前用户在群组中已被禁言
     */
    FORBIDDEN_IN_GROUP = 22408,

    
    /*!
    撤回消息参数无效。请确认撤回消息参数是否正确的填写。
     */
    AC_RECALLMESSAGE_PARAMETER_INVALID = 25101,
    
    /*!
     当前连接不可用（连接已经被释放）
     */
    AC_CHANNEL_INVALID = 30001,

    /*!
     当前连接不可用
     */
    AC_NETWORK_UNAVAILABLE = 30002,

    /*!
     客户端发送消息请求，融云服务端响应超时。
     */
    AC_MSG_RESPONSE_TIMEOUT = 30003,
    
    /*!
      消息大小超限，消息体（序列化成 json 格式之后的内容）最大 128k bytes。
     */
    AC_MSG_SIZE_OUT_OF_LIMIT = 30016,
    
    /*!
    将消息存储到本地数据时失败。
    发送或插入消息时，消息需要存储到本地数据库，当存库失败时，会回调此错误码。
    
    可能由以下几种原因引起：
    * 1. 消息内包含非法参数。请检查消息的 targetId 或 senderId 是否为空或超过最大长度 64 字节。
    * 2. SDK 没有初始化。在使用 SDK 任何功能之前，请确保先初始化。
    * 3. SDK 没有连接。请确保调用 SDK 连接方法并回调数据库打开后再调用消息相关 API。
    */
    
    BIZ_SAVE_MESSAGE_ERROR = 33000,

    /*!
     SDK 没有初始化

     @discussion 在使用 SDK 任何功能之前，必须先 Init。
     */
    CLIENT_NOT_INIT = 33001,

    /*!
     数据库错误
     
     @discussion 连接融云的时候 SDK 会打开数据库，如果没有连接融云就调用了业务接口，因为数据库尚未打开，有可能出现该错误。
     @discussion 数据库路径中包含 userId，如果您获取 token 时传入的 userId 包含特殊字符，有可能导致该错误。userId
     支持大小写英文字母、数字、部分特殊符号 + = - _ 的组合方式，最大长度 64 字节。
     */
    DATABASE_ERROR = 33002,

    /*!
     开发者接口调用时传入的参数错误

     @discussion 请检查接口调用时传入的参数类型和值。
     */
    INVALID_PARAMETER = 33003,
    

    /*!
     小视频时间长度超出限制，默认小视频时长上限为 2 分钟
     */
    AC_SIGHT_MSG_DURATION_LIMIT_EXCEED = 34002,

    /*!
     GIF 消息文件大小超出限制， 默认 GIF 文件大小上限是 2 MB
     */
    AC_GIF_MSG_SIZE_LIMIT_EXCEED = 34003,
    
    /*!
     文件 消息文件大小超出限制， 默认 文件大小上限是 100 MB
     */
    AC_FILE_MSG_SIZE_LIMIT_EXCEED = 34004,
    /*!
     媒体消息媒体文件 http  上传失败
     */
    AC_FILE_UPLOAD_FAILED = 34011,

    /*!
     视频消息压缩失败
     */
    AC_SIGHT_COMPRESS_FAILED = 34015,
    
    /*!
     媒体文件上传异常，媒体文件不存在或文件大小为 0
     */
    AC_MEDIA_EXCEPTION = 34018,
    
    /*!
     上传媒体文件格式不支持
     */
    AC_MEDIA_FILETYPE_INVALID = 34019,
    
    /*
     发送消息被取消
     */
    AC_MSG_CANCELED = 34020,

    
    /*!
     描述：开发者调用的接口不支持传入的会话类型。
     可能原因：此接口不支持传入的会话类型。
     处理建议：请查看相关接口介绍，检查会话类型是否有效。
     */
    INVALID_PARAMETER_CONVERSATIONTYPENOTSUPPORT = 34201,

    
    /*!
     描述：开发者接口调用时传入的 ACMessage.messageId 非法或者找不到对应的 ACMessage。
     可能原因：传入的参数 ACMessage.messageId <= 0， 或者消息ID找不到对应消息。
     处理建议：请检查消息的messageId是否合法，或者消息是否存在。
    */
    INVALID_PARAMETER_MESSAGEID = 34204,

    
    /*!
     描述：开发者接口调用时传入的 ConversationType 非法。
     可能原因：开发者接口调用时传入的 ConversationType 不是 SDK提供的枚举值。
     处理建议：请检查参数是否合法。
     */
    INVALID_PARAMETER_CONVERSATIONTYPE = 34209,

    
    /*!
     描述：开发者接口调用时传入的 ACHistoryMessageOption 非法。
     可能原因： ACHistoryMessageOption.count  为 0，或者ACHistoryMessageOption 为 nil。
     处理建议：请检查参数是否合法。
    */
    INVALID_PARAMETER_ACHISTORYMESSAGEOPTION_COUNT = 34219,
    
    /**
     * 文件已过期或被清理
     */
    AC_FILE_EXPIRED = 34220,
    
    /*!
     * 消息未被注册
     * 发送或者插入自定义消息之前，请确保注册了该类型的消息{ACIMClient  的 registerMessageType}
     * added from 5.1.7
     */
    AC_MESSAGE_NOT_REGISTERED = 34021,
    
    /**
     初始化oss服务失败
     */
    AC_OssServer_InitializeFailed = 34221,
    /**
     上传文件因网络原因失败
     */
    AC_FILE_Download_NetworkError = 34222,
    /**
     访问oss文件被拒
     */
    AC_Oss_AccessDenied = 34223,
    /**
     下载任务被取消
     */
    AC_FILE_Download_Cancelled = 34224,
};


#pragma mark - ACPushNotificationLevel
/**
 免打扰等级
 */
typedef NS_ENUM(NSInteger, ACPushNotificationLevel) {
    /*!
     全部消息通知（接收全部消息通知 -- 显示指定关闭免打扰功能）
     */
    ACPushNotificationLevelAllMessage = -1,
    /*!
     未设置（向上查询群或者APP级别设置）,存量数据中0表示未设置
     */
    ACPushNotificationLevelDefault = 0,
    /*!
     群聊，超级群 @所有人 或者 @成员列表有自己 时通知；单聊代表消息不通知
     */
    ACPushNotificationLevelMention = 1,
    /*!
     群聊，超级群 @成员列表有自己时通知，@所有人不通知；单聊代表消息不通知
     */
    ACPushNotificationLevelMentionUsers = 2,
    /*!
     群聊，超级群 @所有人通知，其他情况都不通知；单聊代表消息不通知
     */
    ACPushNotificationLevelMentionAll = 4,
    /*!
     消息通知被屏蔽，即不接收消息通知
     */
    ACPushNotificationLevelBlocked = 5,
};


#pragma mark ACPushLauguageType
/*!
 *  \~chinese
 push 语言设置
 
 *  \~english
 Push language Settings
 */
typedef NS_ENUM(NSUInteger, ACPushLanguage) {
    /*!
     *  \~chinese
     英文
     
     *  \~english
     English
     */
    ACPushLanguage_EN_US = 1,
    /*!
     *  \~chinese
     中文
     
     *  \~english
     Chinese
     */
    ACPushLanguage_ZH_CN = 2,
};

/*!
 日志级别
 */
typedef NS_ENUM(NSUInteger, ACLogLevel) {

    /*!
     *  不输出任何日志
     */
    AC_Log_Level_None = 0,

    /*!
     *  只输出错误的日志
     */
    AC_Log_Level_Error = 1,

    /*!
     *  输出错误和警告的日志
     */
    AC_Log_Level_Warn = 2,

    /*!
     *  输出错误、警告和一般的日志
     */
    AC_Log_Level_Info = 3,

    /*!
     *  输出输出错误、警告和一般的日志以及 debug 日志
     */
    AC_Log_Level_Debug = 4,

    /*!
     *  输出所有日志
     */
    AC_Log_Level_Verbose = 5,
};

NS_ASSUME_NONNULL_END

#endif
