//
//  SGTcpUrlHelper.h
//  Sugram-debug
//
//  Created by gnutech003 on 2017/2/16.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    // 服务器推送
    AC_API_NAME_NewMessagePush = 0x60018000,//新消息提醒  edit by mark
    AC_API_NAME_SignOutPish = 0x10001007,//退出登录提醒  edit by mark
    AC_API_NAME_SignOutPish2 = 0x10008007,//退出登录提醒
    AC_API_NAME_SessionKilledPush = 0x10008005,//多客户端下线提醒 edit by mark
	AC_API_NAME_UserFrozenToLogin = 0x30018FFF,//封号
	AC_API_NAME_GroupFrozenToMember = 0x60028FFC,//封群
    AC_API_NAME_DialogChangedPush = 0x60018038,//会话信息发生变化
    AC_API_NAME_SuperGroupNewMessage = 0x6002819c, // 收到超级群聊新消息

    AC_API_NAME_Heartbeat = 0x10001001,//心跳  edit by mark
    AC_API_NAME_GetServerTime = 0x10001006,//获取系统时间  edit by mark
    AC_API_NAME_GetSysConfig = 0x40021007, // 获取系统配置
    AC_API_NAME_UpdateApnsToken = 0x3011100D,//更新token  edit by mark
    AC_API_NAME_GetDialogKey = 0x60011015,//获取会话 edit by mark
    AC_API_NAME_DeleteChatMessage = 0x6001100D,//删除会话消息  edit by mark

    AC_API_NAME_UpdatePrivateChatMuteConfig = 0x6001100B,//单聊静音配置    finish__by__gongcheng
    AC_API_NAME_UpdateGroupChatMuteConfig = 0x6002100B,//群聊静音配置   finish__by__gongcheng
    AC_API_NAME_UpdateGroupChatNotificationLevelConfig = 0x60018034, // 群聊免干扰等级配置
    AC_API_NAME_UpdatePrivateChatStickyConfig = 0x6001100A,//修改单聊消息置顶    finish__by__gongcheng
    AC_API_NAME_UpdateGroupChatStickyConfig = 0x6002100A,//修改群聊消息置顶     finish__by__gongcheng
    AC_API_NAME_SendPrivateChatMessage = 0x60011001,//发送个人消息  finish__by__gongcheng
    AC_API_NAME_GetNewAllMessage = 0x60011027,//获取新消息  1.8.0 替换 AC_API_NAME_GetNewMessage
    AC_API_NAME_GetBriefDialogList = 0x6001101F,//获取列表  finish__by__gongcheng
    AC_API_NAME_SendGroupChatMessage = 0x60021001,//发送群消息   finish__by__gongcheng
    AC_API_NAME_DeleteDialog = 0x60011004,//删除单聊
    AC_API_NAME_DeleteGroupDialog = 0x60021004,//删除群聊
	AC_API_NAME_RecallGroupMessage = 0x6002102B,//撤回群聊消息
    AC_API_NAME_ClearPrivateChat = 0x6001100E,//删除单聊记录 done
    AC_API_NAME_ClearGroupChat = 0x6002100E,//删除群聊记录 done
    AC_API_NAME_ClearChat = 0x6002824c, // 删除历史消息
	AC_API_NAME_RecallPrivateMessage  = 0x60011022,//撤回单聊消息
    AC_API_NAME_UpdatePushConfig = 0x30111045, //更新push config
    AC_API_NAME_GetPushConfig = 0x30111046, // 获取push config
    AC_API_NAME_GetSuperGroupNewMessage = 0x6002815c, // 获取超级群离线消息
    AC_API_NAME_GetSuperGroupHistoryMessage = 0x6002817c, // 获取超级群历史消息
    AC_API_NAME_ClearSuperGroupUnreadStatus = 0x6002822c, // 清空超级群未读消息状态
    AC_API_NAME_GetHistoryMessage = 0x60011030, // 获取私聊或普通群聊历史消息
    AC_API_NAME_GetDialogChangedData = 0x60018036 // 查询会话变化状态
} AC_API_NAME;

