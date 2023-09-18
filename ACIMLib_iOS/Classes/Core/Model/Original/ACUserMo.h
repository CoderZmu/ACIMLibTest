//
//  SGUser.h
//  Sugram-debug
//
//  Created by gnutech004 on 2017/2/21.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ACInputStream.h"
#import "AcpbGlobalStructure.pbobjc.h"

@class ACGroupMemberMo;
@class ACDialogMo,ACPBUser;


@interface ACUserMo : NSObject <NSCoding,NSCopying>

// 服务器定义
@property (nonatomic) int64_t Property_SGUser_uin NS_SWIFT_NAME(swift_SGUser_uin); // 用户唯一标识
@property (nonatomic, retain) NSString *Property_SGUser_nickName NS_SWIFT_NAME(swift_SGUser_nickName);//用户名，唯一标识，用于这个用户的查询
@property (nonatomic, copy) NSString *Property_SGUser_token; // sdk token
@property (nonatomic, retain) NSString *Property_SGUser_langCode ;//国家手机代码
@property (nonatomic, retain) NSString *Property_SGUser_phone NS_SWIFT_NAME(swift_SGUser_phone);//手机号码
@property (nonatomic, retain) NSString *Property_SGUser_smallAvatarUrl NS_SWIFT_NAME(swift_SGUser_smallAvatarUrl);//头像缩略图
@property (nonatomic, retain) NSString *Property_SGUser_orginAvatarUrl NS_SWIFT_NAME(swift_SGUser_orginAvatarUrl);//头像原图
@property (nonatomic, retain) NSString *Property_SGUser_email NS_SWIFT_NAME(swift_SGUser_email);
@property (nonatomic, retain) NSString *Property_SGUser_qrCode NS_SWIFT_NAME(swift_SGUser_qrCode);
@property (nonatomic) int8_t Property_SGUser_gender;
@property (nonatomic) int8_t Property_SGUser_userStatus; //用户状态， 1:未添加 5:添加
@property (nonatomic, retain)NSString *Property_SGUser_alias NS_SWIFT_NAME(swift_SGUser_alias);//用户别名
// 服务器定义
@property (nonatomic) long Property_SGUser_locationId;//只是标记
//Should only use that for displaying, when alias enable return alias first, then nickName;
@property (nonatomic, copy, readonly) NSString *Property_SGUser_displayName;
@property (nonatomic) BOOL Property_SGUser_active;
@property (nonatomic, strong) NSNumber *Property_SGUser_isAdmin;
@property (nonatomic) long Property_SGUser_joinTime;
//密钥
@property (nonatomic,strong)NSString* Property_SGUser_cert;
@property (nonatomic,strong)ACPBAesKeyAndIV* Property_SGUser_bodyAes;
@property (nonatomic,strong)NSString* Property_SGUser_contentPrivateKey;
@property (nonatomic,strong)NSString* Property_SGUser_contentPublicKey;

@property (nonatomic)long Property_SGUser_deviceID;
@property (nonatomic)long Property_SGUser_sessionID;


@property(nonatomic)BOOL Property_SGUser_isDelete;
@property(nonatomic)BOOL Property_SGUser_isBlock;
@property(nonatomic,assign)long Property_SGUser_referenceUid;
@property (nonatomic, retain) NSString *Property_SGUser_groupAlias; //群名称


//手机通讯录匹配
@property(nonatomic,strong)NSString *Property_SGUser_userSectionLetters;
@property(nonatomic,strong)NSString* Property_SGUser_fullEnglishName;
@property(nonatomic,strong)NSString* Property_SGUser_originalAvatarUrl;
@property(nonatomic,assign)Byte Property_SGUser_contactStatus; /** 通讯录状态，1:未添加, 5:已添加 100:已屏蔽过 */

@property(nonatomic, strong) NSNumber *Property_SGUser_retCode; /** 0:可正常帮忙验证 1:加为好友时间过短 2:验证次数太多 3:该朋友的申请已过期 */


//帮助好友验证
@property(nonatomic) Boolean Property_SGUser_timesUseUpFlag;
@property(nonatomic,strong)NSString* Property_SGUser_tmpAlias;//在手机里面的备注

//本地通讯录的名字
@property(nonatomic, copy) NSString *Property_SGUser_loaclName;
@property (nonatomic, retain)NSString *Property_SGUser_telephoneMobile;//上传的本地电话号码

//备注 的电话 和描述
@property(nonatomic,strong) NSMutableArray<NSString*> *Property_SGUser_aliasMobileArray; // 备注电话号码列表
@property(nonatomic,copy) NSString *Property_SGUser_aliasDesp; // 备注描述

@property (nonatomic, copy) NSAttributedString *Property_SGUser_titleAttributeString; //用于搜索的时候，昵称或者备注匹配过后的字符串
@property (nonatomic, copy) NSAttributedString *Property_SGUser_contentAttributeString; //用于用户的手机号或者描述匹配成功后的字符串

@property (nonatomic) int64_t Property_ACDialogs_topMessageSendTime;


//判断是否删除
@property(nonatomic)bool Property_SGUser_isDel;

//- (NSDictionary *)properties_aps;

- (NSString *)activeName;

- (ACUserMo *)serviceUserCopy:(ACPBUser*)user;

- (instancetype)initWithPBUser:(ACPBUser *)pbUser;

+ (NSString *)loadProperty_SGUser_nickNameKey;
+ (NSString *)loadProperty_SGUser_phoneKey;
+ (NSString *)loadProperty_SGUser_aliasKey;
+ (NSString *)loadProperty_SGUser_loaclNameKey;
+ (NSString *)loadProperty_SGUser_uinKey;
+ (NSString *)loadProperty_ACDialogs_topMessageSendTimeKey;


@end
