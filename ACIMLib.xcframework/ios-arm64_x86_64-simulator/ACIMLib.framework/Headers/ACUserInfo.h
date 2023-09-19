//
//  ACUserInfo.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/*!
 *  \~chinese
 用户信息类
 */
@interface ACUserInfo : NSObject

/*!
 *  \~chinese
 用户 ID
 */
@property (nonatomic, assign) long userId;

/*!
 *  \~chinese
 用户名称
 */
@property (nonatomic, copy) NSString *name;

/*!
 *  \~chinese
 用户头像的 URL
 */
@property (nonatomic, copy) NSString *portraitUri;

/**
 *  \~chinese
 用户信息附加字段

 */
@property (nonatomic, copy) NSString *extra;

/*!
 *  \~chinese
 用户信息的初始化方法

 @param userId      用户 ID
 @param username    用户名称
 @param portrait    用户头像的 URL
 @return            用户信息对象
 */
- (instancetype)initWithUserId:(long)userId name:(NSString *)username portrait:(NSString *)portrait;


- (instancetype)initWithEncodeData:(nonnull NSDictionary *)data;
- (nonnull NSDictionary *)encode;
@end

NS_ASSUME_NONNULL_END
