//
//  SGUser.m
//  Sugram-debug
//
//  Created by gnutech004 on 2017/2/21.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import "ACUserMo.h"
#import "ACDialogMo.h"
#import "ACBase.h"
#import "AcpbBase.pbobjc.h"


@implementation ACUserMo

- (NSString *)Property_SGUser_displayName {
    if (self.Property_SGUser_alias&&self.Property_SGUser_alias.length) {
        return self.Property_SGUser_alias;
    }

    if (self.Property_SGUser_nickName&&self.Property_SGUser_nickName.length) {
        return self.Property_SGUser_nickName;
    }
    return  @"Unknown";
}


- (NSString *)activeName {
    return self.Property_SGUser_alias.length != 0 ?  self.Property_SGUser_alias : self.Property_SGUser_nickName;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_gender"] forKey:@"_gender"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_active"] forKey:@"_active"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_isDelete"] forKey:@"_isDelete"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_isBlock"] forKey:@"_isBlock"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_timesUseUpFlag"] forKey:@"_timesUseUpFlag"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_isDel"] forKey:@"_isDel"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_userStatus"] forKey:@"_userStatus"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_contactStatus"] forKey:@"_contactStatus"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_uin"] forKey:@"_uin"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_nickName"] forKey:@"_nickName"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_langCode"] forKey:@"_langCode"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_phone"] forKey:@"_phone"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_smallAvatarUrl"] forKey:@"_smallAvatarUrl"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_orginAvatarUrl"] forKey:@"_orginAvatarUrl"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_email"] forKey:@"_email"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_qrCode"] forKey:@"_qrCode"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_groupAlias"] forKey:@"_groupAlias"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_isAdmin"] forKey:@"_isAdmin"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_alias"] forKey:@"_alias"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_locationId"] forKey:@"_locationId"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_joinTime"] forKey:@"_joinTime"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_cert"] forKey:@"_cert"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_bodyAes"] forKey:@"_bodyAes"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_contentPrivateKey"] forKey:@"_contentPrivateKey"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_contentPublicKey"] forKey:@"_contentPublicKey"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_deviceID"] forKey:@"_deviceID"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_sessionID"] forKey:@"_sessionID"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_referenceUid"] forKey:@"_referenceUid"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_userSectionLetters"] forKey:@"_userSectionLetters"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_fullEnglishName"] forKey:@"_fullEnglishName"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_originalAvatarUrl"] forKey:@"_originalAvatarUrl"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_tmpAlias"] forKey:@"_tmpAlias"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_loaclName"] forKey:@"_loaclName"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_telephoneMobile"] forKey:@"_telephoneMobile"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_retCode"] forKey:@"_retCode"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_aliasMobileArray"] forKey:@"_aliasMobileArray"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_aliasDesp"] forKey:@"_aliasDesp"];
    [aCoder encodeObject:[self valueForKey:@"Property_SGUser_token"] forKey:@"_token"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_uin"] forkey:@"Property_SGUser_uin"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_nickName"] forkey:@"Property_SGUser_nickName"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_langCode"] forkey:@"Property_SGUser_langCode"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_phone"] forkey:@"Property_SGUser_phone"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_smallAvatarUrl"] forkey:@"Property_SGUser_smallAvatarUrl"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_orginAvatarUrl"] forkey:@"Property_SGUser_orginAvatarUrl"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_email"] forkey:@"Property_SGUser_email"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_qrCode"] forkey:@"Property_SGUser_qrCode"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_gender"] forkey:@"Property_SGUser_gender"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_userStatus"] forkey:@"Property_SGUser_userStatus"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_alias"] forkey:@"Property_SGUser_alias"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_locationId"] forkey:@"Property_SGUser_locationId"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_active"] forkey:@"Property_SGUser_active"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_isAdmin"] forkey:@"Property_SGUser_isAdmin"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_joinTime"] forkey:@"Property_SGUser_joinTime"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_cert"] forkey:@"Property_SGUser_cert"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_bodyAes"] forkey:@"Property_SGUser_bodyAes"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_contentPrivateKey"] forkey:@"Property_SGUser_contentPrivateKey"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_contentPublicKey"] forkey:@"Property_SGUser_contentPublicKey"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_deviceID"] forkey:@"Property_SGUser_deviceID"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_sessionID"] forkey:@"Property_SGUser_sessionID"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_isDel"] forkey:@"Property_SGUser_isDel"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_isBlock"] forkey:@"Property_SGUser_isBlock"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_referenceUid"] forkey:@"Property_SGUser_referenceUid"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_groupAlias"] forkey:@"Property_SGUser_groupAlias"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_userSectionLetters"] forkey:@"Property_SGUser_userSectionLetters"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_fullEnglishName"] forkey:@"Property_SGUser_fullEnglishName"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_originalAvatarUrl"] forkey:@"Property_SGUser_originalAvatarUrl"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_contactStatus"] forkey:@"Property_SGUser_contactStatus"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_retCode"] forkey:@"Property_SGUser_retCode"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_timesUseUpFlag"] forkey:@"Property_SGUser_timesUseUpFlag"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_tmpAlias"] forkey:@"Property_SGUser_tmpAlias"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_loaclName"] forkey:@"Property_SGUser_loaclName"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_telephoneMobile"] forkey:@"Property_SGUser_telephoneMobile"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_aliasMobileArray"] forkey:@"Property_SGUser_aliasMobileArray"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_aliasDesp"] forkey:@"Property_SGUser_aliasDesp"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_isDelete"] forkey:@"Property_SGUser_isDelete"];
        [self sgUser_setValue:[aDecoder decodeObjectForKey:@"_token"] forkey:@"Property_SGUser_token"];
    }
    return self;
}

- (void)sgUser_setValue:(id)value forkey:(NSString *)key {
    if (value) {  //新加_vipLevel
        [self setValue:value forKey:key];
    }
}


- (id)copyWithZone:(NSZone *)zone {
    ACUserMo *user = [[ACUserMo alloc] init];
    user.Property_SGUser_gender = self.Property_SGUser_gender;
    user.Property_SGUser_active = self.Property_SGUser_active;
    user.Property_SGUser_isDelete = self.Property_SGUser_isDelete;
    user.Property_SGUser_isBlock = self.Property_SGUser_isBlock;
    user.Property_SGUser_timesUseUpFlag = self.Property_SGUser_timesUseUpFlag;
    user.Property_SGUser_isDel = self.Property_SGUser_isDel;
    user.Property_SGUser_userStatus = self.Property_SGUser_userStatus;
    user.Property_SGUser_contactStatus = self.Property_SGUser_contactStatus;
    user.Property_SGUser_uin = self.Property_SGUser_uin;
    user.Property_SGUser_langCode = self.Property_SGUser_langCode;
    user.Property_SGUser_phone = self.Property_SGUser_phone;
    user.Property_SGUser_smallAvatarUrl = self.Property_SGUser_smallAvatarUrl;
    user.Property_SGUser_orginAvatarUrl = self.Property_SGUser_orginAvatarUrl;
    user.Property_SGUser_email = self.Property_SGUser_email;
    user.Property_SGUser_qrCode = self.Property_SGUser_qrCode;
    user.Property_SGUser_groupAlias = self.Property_SGUser_groupAlias;
    user.Property_SGUser_isAdmin = self.Property_SGUser_isAdmin;
    user.Property_SGUser_locationId = self.Property_SGUser_locationId;
    user.Property_SGUser_joinTime = self.Property_SGUser_joinTime;
    user.Property_SGUser_cert = self.Property_SGUser_cert;
    user.Property_SGUser_bodyAes = self.Property_SGUser_bodyAes;
    user.Property_SGUser_contentPrivateKey = self.Property_SGUser_contentPrivateKey;
    user.Property_SGUser_contentPublicKey = self.Property_SGUser_contentPublicKey;
    user.Property_SGUser_deviceID = self.Property_SGUser_deviceID;
    user.Property_SGUser_sessionID = self.Property_SGUser_sessionID;
    user.Property_SGUser_referenceUid = self.Property_SGUser_referenceUid;
    user.Property_SGUser_userSectionLetters = self.Property_SGUser_userSectionLetters;
    user.Property_SGUser_fullEnglishName = self.Property_SGUser_fullEnglishName;
    user.Property_SGUser_originalAvatarUrl = self.Property_SGUser_originalAvatarUrl;
    user.Property_SGUser_tmpAlias = self.Property_SGUser_tmpAlias;
    user.Property_SGUser_loaclName = self.Property_SGUser_loaclName;
    user.Property_SGUser_telephoneMobile = self.Property_SGUser_telephoneMobile;
    user.Property_SGUser_retCode = self.Property_SGUser_retCode;
    user.Property_SGUser_aliasMobileArray = self.Property_SGUser_aliasMobileArray;
    user.Property_SGUser_aliasDesp = self.Property_SGUser_aliasDesp;
    user.Property_SGUser_token = self.Property_SGUser_token;
    return user;
}


- (ACUserMo*)serviceUserCopy:(ACPBUser *)user {
    if ([user isKindOfClass:[ACUserMo class]]) {
        return (ACUserMo *)user;
    }
    ACUserMo*_user = [[ACUserMo alloc]init];
    _user.Property_SGUser_uin = user.uid;
    _user.Property_SGUser_nickName = user.nickName;
    _user.Property_SGUser_langCode = user.langCode;
    _user.Property_SGUser_phone = user.phone;
    _user.Property_SGUser_telephoneMobile = user.numberInPhoneBook;
    _user.Property_SGUser_smallAvatarUrl = user.smallAvatarURL;
    _user.Property_SGUser_originalAvatarUrl = user.originalAvatarURL;
    _user.Property_SGUser_orginAvatarUrl = user.originalAvatarURL;
    _user.Property_SGUser_email = user.email;
    _user.Property_SGUser_qrCode = user.qrcodeString;
    _user.Property_SGUser_gender = user.gender;
    _user.Property_SGUser_contactStatus = user.contactStatus;
    _user.Property_SGUser_userStatus = user.contactStatus;
    _user.Property_SGUser_alias = user.alias;
    _user.Property_SGUser_aliasDesp = user.aliasDesp;
    _user.Property_SGUser_aliasMobileArray = user.aliasMobileArray;
    
    
	return _user;
}

- (instancetype)initWithPBUser:(ACPBUser *)pbUser {
    self = [super init];
    if (self) {
        self = [self serviceUserCopy:pbUser];
    }
    return self;
}
+ (NSString *)loadProperty_SGUser_nickNameKey{
    return @"Property_SGUser_nickName";
}
+ (NSString *)loadProperty_SGUser_phoneKey {
    return @"Property_SGUser_phone";
}
+ (NSString *)loadProperty_SGUser_aliasKey{
    return @"Property_SGUser_alias";
}
+ (NSString *)loadProperty_SGUser_loaclNameKey {
    return @"Property_SGUser_loaclName";
}
+ (NSString *)loadProperty_SGUser_uinKey {
    return @"Property_SGUser_uin";
}
+ (NSString *)loadProperty_ACDialogs_topMessageSendTimeKey {
	return @"Property_ACDialogs_topMessageSendTime";
}

@end
