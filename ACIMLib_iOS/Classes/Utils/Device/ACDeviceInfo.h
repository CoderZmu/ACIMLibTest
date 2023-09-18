//
//  ACDeviceInfo.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACDeviceInfo : NSObject

+ (NSString *)getPhoneUUID;
+ (int       )getAppVersion;
+ (NSString *)getPhoneModel;
+ (NSString*)getEncodeKey;
@end

NS_ASSUME_NONNULL_END
