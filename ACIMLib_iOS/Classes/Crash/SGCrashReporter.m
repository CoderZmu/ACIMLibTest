//
//  SGCrashReporter.m
//  Sugram
//
//  Created by 子木 on 2023/7/24.
//  Copyright © 2023 Sugram. All rights reserved.
//

@import CrashReporter;
#import "ACLogger.h"
#import "SGCrashReporter.h"
#import "SGCrashReportTextFormatter.h"


@interface SGCrashReporter()

@property (nonatomic, strong) PLCrashReporter *crashReporter;

@end

@implementation SGCrashReporter

+ (instancetype)sharedManager {
    static dispatch_once_t once;
    static id obj = nil;
    dispatch_once(&once, ^{obj = [self new];});
    return obj;
}


- (instancetype)init {
    self = [super init];
    if (self) {
#ifndef DEBUG
        [self initCrashReporter];
        [self handleCrashReport];
#endif
        }
        
    return self;
}


- (void)initCrashReporter {
    
    PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType: PLCrashReporterSignalHandlerTypeMach
                                                                       symbolicationStrategy: PLCrashReporterSymbolicationStrategyAll];
    self.crashReporter = [[PLCrashReporter alloc] initWithConfiguration: config];

    NSError *error;
    if (![self.crashReporter enableCrashReporterAndReturnError: &error]) {
        NSLog(@"Warning: Could not enable crash reporter: %@", error);
    }

}

- (void)handleCrashReport {
    if ([self.crashReporter hasPendingCrashReport]) {
        NSError *error;

        // Try loading the crash report.
        NSData *data = [self.crashReporter loadPendingCrashReportDataAndReturnError: &error];
        if (data == nil) {
            NSLog(@"Failed to load crash report data: %@", error);
            return;
        }

        // Retrieving crash reporter data.
        PLCrashReport *report = [[PLCrashReport alloc] initWithData: data error: &error];
        if (report == nil) {
            NSLog(@"Failed to parse crash report: %@", error);
            return;
        }

        NSString *text = [SGCrashReportTextFormatter stringValueForCrashReport: report];

        // upload
        ACLog(@"%@", text);
        
        [self.crashReporter purgePendingCrashReport];
    }
}



@end
