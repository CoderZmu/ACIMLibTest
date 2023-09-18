//
//  ACConnectionListenerProtocol.h
//  ACIMLib
//
//  Created by 子木 on 2022/7/1.
//

#ifndef ACConnectionListenerProtocol_h
#define ACConnectionListenerProtocol_h

#import "ACStatusDefine.h"

@protocol ACConnectionListenerProtocol <NSObject>
@optional
// 用户数据已加载(如果用户已成功登录，此时因用户已有历史数据，所以触发时机会在加载数据库成功之后，在socket连接前。)
- (void)userDataDidLoad;
// socket服务已连接
- (void)onConnected;
// socket服务已关闭
- (void)onClosed;
// 连接状态改变
- (void)onConnectStatusChanged:(ACConnectionStatus)status;

@end


#endif /* ACConnectionListenerProtocol_h */
