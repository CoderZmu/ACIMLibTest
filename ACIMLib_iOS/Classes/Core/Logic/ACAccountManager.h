//
//  SGAccount.h
//  Sugram
//
//  Created by gossip2 on 16/12/5.
//  Copyright © 2016年 gossip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACUserMo.h"

@class ACPBAuthSignIn2TokenResp;
@interface ACAccountManager : NSObject
@property(nonatomic,strong)ACUserMo* user;

+(ACAccountManager*)shared;

+ (void)setLoggedWithModel:(ACPBAuthSignIn2TokenResp *)resp token:(NSString *)token;
+ (void)logOut;

@end
