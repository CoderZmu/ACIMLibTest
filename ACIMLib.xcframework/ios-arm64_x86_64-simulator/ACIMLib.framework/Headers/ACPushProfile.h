//
//  ACPushProfile.h
//  ACIMLib
//
//  Created by 子木 on 2022/7/21.
//

#import <Foundation/Foundation.h>
#import "ACStatusDefine.h"

@interface ACPushProfile : NSObject

/**
 是否显示远程推送的内容

 */
@property (nonatomic, assign, readonly) BOOL isShowPushContent;

/**
 远程推送的语言

 */
@property (nonatomic, assign, readonly) ACPushLanguage pushLanguage;


/**
 设置是否显示远程推送的内容

 @param isShowPushContent 是否显示推送的具体内容（ YES 显示 NO 不显示）
 @param successBlock      成功回调
 @param errorBlock        失败回调
 
 */
- (void)updateShowPushContentStatus:(BOOL)isShowPushContent
                            success:(void (^)(void))successBlock
                              error:(void (^)(ACErrorCode status))errorBlock;

/**
 设置推送内容的自然语言
 
 @param lauguage             通过 SDK 设置的语言环境，语言缩写内容格式为 (ISO-639 Language Code)_(ISO-3166 Country Codes)，如：zh_CN。目前支持的内置推送语言为 zh_CN、en_US
 @param successBlock    成功回调
 @param errorBlock        失败回调
 

 */
- (void)setPushLanguageCode:(NSString *)language
                    success:(void (^)(void))successBlock
                      error:(void (^)(ACErrorCode status))errorBlock;

@end
