//
//  ACOssConfig.h
//  Sugram
//
//  Created by 子木 on 2023/1/5.
//  Copyright © 2023 Sugram. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACOssConfig : NSObject<NSCoding, NSSecureCoding>

@property (nonatomic,copy) NSString *accessKey;

@property (nonatomic,copy) NSString *secretKey;

@property (nonatomic,copy) NSString *endPoint;

@property (nonatomic,copy) NSString *chatBucket;

+ (instancetype)createOssConfigWithServerConfDict:(NSDictionary *)confDict;
@end



NS_ASSUME_NONNULL_END
