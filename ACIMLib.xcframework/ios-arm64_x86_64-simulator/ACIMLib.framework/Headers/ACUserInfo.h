//
//  ACUserInfo.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/*!
 用户信息类
 */
@interface ACUserInfo : NSObject

/*!
 用户 ID
 */
@property (nonatomic, assign) NSString *userId;

/*!
 用户名称
 */
@property (nonatomic, copy) NSString *name;

/*!
 用户头像的 URL
 */
@property (nonatomic, copy) NSString *portraitUri;

/*!
 用户备注
 */
@property (nonatomic, copy, nullable) NSString *alias;

/**
 用户信息附加字段

 */
@property (nonatomic, copy) NSString *extra;

/*!
 用户信息的初始化方法

 @param userId      用户 ID
 @param username    用户名称
 @param portrait    用户头像的 URL
 @return            用户信息对象
 */
- (instancetype)initWithUserId:(NSString *)userId name:(NSString *)username portrait:(nullable NSString *)portrait;


- (instancetype)initWithEncodeData:(nonnull NSDictionary *)data;
- (nonnull NSDictionary *)encode;
@end

NS_ASSUME_NONNULL_END
