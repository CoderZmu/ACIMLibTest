//
//  ACSendMessageConfig.h
//  ACIMLib
//
//  Created by 子木 on 2023/4/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACSendMessageConfig : NSObject

@property (nonatomic, assign) BOOL deleteWhenFailed;

@property (nonatomic, assign) BOOL saveWhenSent;

@end

NS_ASSUME_NONNULL_END
