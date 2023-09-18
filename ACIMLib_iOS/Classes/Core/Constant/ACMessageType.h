//
//  MessageType.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/13.
//

#ifndef ACMessageType_h
#define ACMessageType_h

//#define ACMessageTextType 0x00000000
//#define ACMessagePhotoType 0x10001000
//#define ACMessageFileType 0x1000100A
//#define ACMessageGIFType 0x1000100B
//#define ACMessageAudioType 0x10001001
//#define ACMessageVideoType 0x10001006
//#define ACMessageIWCommand 0x1000101D
//#define ACMessageIWStorage 0x1000102D
//#define ACMessageIWNormal 0x1000103D
//#define ACMessageIWStatus 0x1000104D
//#define ACMessageRecall 0x6001001D
//#define ACMessageCommandNoti 0x1000105D
//#define ACMessageContactNoti 0x1000106D

#define PrivateChatRecallMessage @"RC:PRcNtf" //撤回单聊消息
#define GroupChatRecallMessage @"RC:GRcNtf" //撤回群聊消息


//#define SGSendPrivateChatArrivalAck 0x6001000C //已到达对方手机回执 通知
//#define SGSendPrivateChatReadAck  0x6001000D//消息已读回执 通知:
//#define SGSendGroupChatArrivalAck 0x60020024 //群有人收到消息 返回已送达通知
//#define SGSendGroupChatReadAck   0x60020025 //群有人读取消息 返回消息已读通知
//#define GroupChatAckNotification 0x6002002E //群有人读取消息 返回消息已读通知
//#define ACReportLogNotification 0x60010008 // 提交日志通知

//#define StartTypingPrivateChatNotification 0x6001000A //单聊正在输入的通知
//#define EndTypingPrivateChatNotification 0x6001000B //单聊停止输入的通知
//#define StartTypingGroupChatNotification 0x60020022 //群聊正在输入的通知
//#define EndTypingGroupChatNotification 0x60020023 //群聊停止输入的通知
//
//#define UploadAppLogNotification 0x70020010  //app上传日志通知

#endif /* MessageType_h */
