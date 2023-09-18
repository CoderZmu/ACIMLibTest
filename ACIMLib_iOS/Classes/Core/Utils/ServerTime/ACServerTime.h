//
//  ACServerTime.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACServerTime : NSObject

+ (long)getServerMSTime;

+ (void)performTimeSynchronization;

+ (BOOL)isSyncDone;
@end

NS_ASSUME_NONNULL_END
