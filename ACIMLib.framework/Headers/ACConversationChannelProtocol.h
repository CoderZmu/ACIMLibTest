//
//  ACConversationChannelProtocol.h
//  ACIMLib
//
//  Created by 子木 on 2022/8/5.
//

#ifndef ACConversationChannelProtocol_h
#define ACConversationChannelProtocol_h

#pragma mark - 超级群会话代理

@protocol ACUltraGroupConversationDelegate<NSObject>

//超级群会话列表与会话最后一条消息同步完成
- (void)ultraGroupConversationListDidSync;
@end

#endif /* ACConversationChannelProtocol_h */
