//
//  SGAccount.m
//  Sugram
//
//  Created by gossip2 on 16/12/5.
//  Copyright © 2016年 gossip. All rights reserved.
//

#import "ACAccountManager.h"
#import "AcpbBase.pbobjc.h"
#import "ACFileManager.h"

@interface ACAccountManager ()
@end

@implementation ACAccountManager
+(ACAccountManager*)shared
{
    static ACAccountManager* instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        instance = [[ACAccountManager alloc] init];
    
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    ACUserMo *user = [NSKeyedUnarchiver unarchiveObjectWithFile:[self accountArchivePath]];
    self.user = user ?: [ACUserMo new];
    return self;
}

-(void)updateAccount {
    [NSKeyedArchiver archiveRootObject:self.user toFile:[self accountArchivePath]];
}


+ (void)setLoggedWithModel:(ACPBAuthSignIn2TokenResp *)resp token:(NSString *)token {
    ACUserMo *user = [ACUserMo new];
    user = [user serviceUserCopy:resp.user];
    user.Property_SGUser_active = YES;
    user.Property_SGUser_deviceID = resp.deviceId;
    user.Property_SGUser_sessionID = resp.sessionId;
    user.Property_SGUser_token = token;
   
    [ACAccountManager shared].user = user;
    [[ACAccountManager shared] updateAccount];
}

+ (void)logOut {
    
    [ACAccountManager shared].user.Property_SGUser_active = NO;
    [ACAccountManager shared].user.Property_SGUser_deviceID = 0;
    [ACAccountManager shared].user.Property_SGUser_sessionID = 0;
    [ACAccountManager shared].user.Property_SGUser_token = @"";
    [[ACAccountManager shared] updateAccount];
}

- (NSString *)accountArchivePath {
    return [[ACFileManager publicPath] stringByAppendingPathComponent:@"account.achive"];;
}

@end
