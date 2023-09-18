//
//  SGCrashReportTextFormatter.h
//  Sugram
//
//  Created by 子木 on 2023/7/24.
//  Copyright © 2023 Sugram. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PLCrashReport;
@interface SGCrashReportTextFormatter : NSObject

+ (NSString *) stringValueForCrashReport: (PLCrashReport *) report;
@end

NS_ASSUME_NONNULL_END
