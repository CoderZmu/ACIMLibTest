//
//  ACMentionedInfo.h
//  ACIMLib
//
//  Created by 子木 on 2022/8/5.


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACMessagePushConfig : NSObject

/*!
 推送标题
 如果没有设置，会使用下面的默认标题显示规则
 默认标题显示规则：
    内置消息：单聊通知标题显示为发送者名称，群聊通知标题显示为群名称。
    自定义消息：默认不显示标题。
 
 *  \~english
 Push title.
 If it is not set, the following default title is used to display the rule.
 The default title display rules:
     Built-in message: The single chat notification title is displayed as the sender name, and the group chat notification title is displayed as the group name.
     Custom message: the title is not displayed by default.
 */
@property (nonatomic, copy) NSString *pushTitle;

/*!
 推送内容
 
 *  \~english
 Push content
 */
@property (nonatomic, copy) NSString *pushContent;

/*!
 远程推送附加信息
 
 *  \~english
 Remotely push additional information.
 */
@property (nonatomic, copy) NSString *pushData;

/*!
 是否强制显示通知详情
 当目标用户通过 ACPushProfile 中的 updateShowPushContentStatus 设置推送不显示消息详情时，可通过此参数，强制设置该条消息显示推送详情。
 
 *  \~english
 Whether to force the display of notification details.
 When the target user does not display the message details through the updateShowPushContentStatus setting in ACPushProfile, you can use this parameter to force the message to display the push details.
 */
@property (nonatomic, assign) BOOL forceShowDetailContent;

/*!
 推送模板 ID，设置后根据目标用户通过 SDK RCPushProfile 中的 setPushLauguageCode 设置的语言环境，匹配模板中设置的语言内容进行推送，未匹配成功时使用默认内容进行推送，模板内容在“开发者后台-自定义推送文案”中进行设置。
 注：ACMessagePushConfig 中的 Title 和 PushContent 优先级高于模板 ID（templateId）中对应的标题和推送内容。
 
 *  \~english
 After the ID of the push template is set, the language content set in the template is matched according to the locale set by the target user through the setPushLauguageCode in SDK RCPushProfile. If the match is not successful, the default content is pushed. The template content is set in "developer backend-Custom push copy".
  Note: The Title and PushContent in ACMessagePushConfig take precedence over the corresponding title and push content in the template ID (templateId).
 */
@property (nonatomic, copy) NSString *templateId;


- (NSString *)encodePushConfig;

@end

NS_ASSUME_NONNULL_END

