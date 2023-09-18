//
//  SGChatMessage.h
//  Sugram
//
//  Created by gnutech003 on 2017/6/5.
//  Copyright © 2017年 gossip. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACChatMessageMo : NSObject
@property (nonatomic, copy) NSString *dialogId;
@property (nonatomic, strong) NSMutableSet *msgIdSet;

@end
