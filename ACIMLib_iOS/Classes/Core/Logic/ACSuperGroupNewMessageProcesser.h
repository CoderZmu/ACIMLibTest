//
//  ACSuperGroupNewMessageProcesser.h
//  ACIMLib
//
//  Created by 子木 on 2022/8/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACSuperGroupNewMessageProcesser : NSObject

+ (void)onReceiveNewMessageData:(NSData *)data;
@end

NS_ASSUME_NONNULL_END
