//
//  ACIMClientProtocol.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/23.
//

#ifndef ACIMClientProtocol_h
#define ACIMClientProtocol_h

@class ACMessage;
#import "ACStatusDefine.h"

#pragma mark - ACIMClientReceiveMessageDelegate

/*!
 *  \~chinese
 IMlib消息接收的监听器

 @discussion
 设置IMLib的消息接收监听器请参考ACIMClient的setReceiveMessageDelegate:object:方法。

 
 *  \~english
 Listeners for IMlib message reception.

 @ discussion
 To set the message receiving listener for IMLib, please refer to the setReceiveMessageDelegate:object: method of ACIMClient.

 */
@protocol ACIMClientReceiveMessageDelegate <NSObject>

@optional
/*!
 *  \~chinese
 接收消息的回调方法

 @param message     当前接收到的消息
 @param nLeft       还剩余的未接收的消息数，left>=0
 @param object      消息监听设置的key值

 @discussion 如果您设置了IMlib消息监听之后，SDK在接收到消息时候会执行此方法。
 其中，left为还剩余的、还未接收的消息数量。比如刚上线一口气收到多条消息时，通过此方法，您可以获取到每条消息，left会依次递减直到0。
 您可以根据left数量来优化您的App体验和性能，比如收到大量消息时等待left为0再刷新UI。
 object为您在设置消息接收监听时的key值。
 * 
 
 此方法的回调并非为原调用线程，您如果需要进行 UI 操作，请注意切换到主线程。
 */
- (void)onReceived:(ACMessage *)message left:(int)nLeft object:(id)object;

/**
 接收消息的回调方法

 @param message 当前接收到的消息
 @param nLeft 还剩余的未接收的消息数，left>=0
 @param object 消息监听设置的key值
 @param offline 是否是离线消息
 @param hasPackage SDK 拉取服务器的消息以包(package)的形式批量拉取，有 package 存在就意味着远端服务器还有消息尚未被 SDK
 拉取
 @discussion 和上面的 - (void)onReceived:(RCMessage *)message left:(int)nLeft object:(id)object 功能完全一致，额外把
 offline 和 hasPackage 参数暴露，开发者可以根据 nLeft、offline、hasPackage 来决定何时的时机刷新 UI ；建议当 hasPackage=0
 并且 nLeft=0 时刷新 UI
 @warning 如果使用此方法，那么就不能再使用 RCIM 中 - (void)onReceived:(RCMessage *)message left:(int)nLeft
 object:(id)object 的使用，否则会出现重复操作的情形
 
 此方法的回调并非为原调用线程，您如果需要进行 UI 操作，请注意切换到主线程。
 */
- (void)onReceived:(ACMessage *)message
              left:(int)nLeft
            object:(nullable id)object
           offline:(BOOL)offline
        hasPackage:(BOOL)hasPackage;

/*!
 离线消息接收完成
*/
- (void)onOfflineMessageSyncCompleted;

/*!
 消息被撤回的回调方法

 @param message 被撤回的消息

 @discussion 被撤回的消息会变更为ACRecallNotificationMessage，App需要在UI上刷新这条消息。
 
 此方法的回调并非为原调用线程，您如果需要进行 UI 操作，请注意切换到主线程。
 */
- (void)messageDidRecall:(ACMessage *)message;


@end


#pragma mark - ACConnectionStatusChangeDelegate

/*!
 *  \~chinese
 IMLib连接状态的的监听器

 @warning 如果您使用IMLib，可以设置并实现此Delegate监听连接状态变化；
 
 */
@protocol ACConnectionStatusChangeDelegate <NSObject>

/*!
 *  \~chinese
 IMLib连接状态的的监听器

 @param status  SDK与服务器的连接状态

 @discussion 如果您设置了IMLib消息监听之后，当SDK与服务器的连接状态发生变化时，会回调此方法。

 */
- (void)onConnectionStatusChanged:(ACConnectionStatus)status;


@end

#endif /* ACIMClientProtocol_h */
