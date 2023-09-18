//
//  ACDeviceInfo.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/14.
//

#import <UIKit/UIKit.h>
#import "ACSAMKeychain.h"
#import "ACDeviceInfo.h"
#import "ACBase.h"

#define Service @"org.sugram.sugram"
#define Account @"org.sugram.sugram.ios"

@implementation ACDeviceInfo


+ (NSString *)getPhoneUUID {
    NSString* uuid = [ACSAMKeychain passwordForService:Service account:Account];
    if (!uuid) {
        uuid = [UIDevice currentDevice].identifierForVendor.UUIDString;
        [ACSAMKeychain setPassword:uuid forService:Service account:Account];
    }
    return uuid;
}

+ (int )getAppVersion {
    return 0;
}

+ (NSString *)getPhoneModel {
    return [UIDevice currentDevice].localizedModel;
}

+ (NSString*)getEncodeKey {
    return [[[self getPhoneUUID] stringByAppendingString:@"_sm-ac"] ac_md5String];
}


@end
