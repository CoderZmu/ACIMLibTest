//
//  ACNetErrorConverter.h
//  ACIMLib
//
//  Created by 子木 on 2022/7/22.
//

#import <Foundation/Foundation.h>
#import "ACStatusDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACNetErrorConverter : NSObject
+ (ACErrorCode)toAcErrorCodeEnumProperty:(NSInteger)respCode;
@end

NS_ASSUME_NONNULL_END
