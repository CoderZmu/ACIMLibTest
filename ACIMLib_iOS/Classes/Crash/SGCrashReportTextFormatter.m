//
//  SGCrashReportTextFormatter.m
//  Sugram
//
//  Created by 子木 on 2023/7/24.
//  Copyright © 2023 Sugram. All rights reserved.
//

#import "SGCrashReportTextFormatter.h"
@import CrashReporter;

@implementation SGCrashReportTextFormatter


+ (NSString *) stringValueForCrashReport: (PLCrashReport *) report {
    NSMutableString* text = [NSMutableString string];
    boolean_t lp64 = true; // quiesce GCC uninitialized value warning

    /* Header */
    
    /* Map to apple style OS name */
    NSString *osName;
    switch (report.systemInfo.operatingSystem) {
        case PLCrashReportOperatingSystemMacOSX:
            osName = @"Mac OS X";
            break;
        case PLCrashReportOperatingSystemiPhoneOS:
            osName = @"iPhone OS";
            break;
        case PLCrashReportOperatingSystemiPhoneSimulator:
            osName = @"Mac OS X";
            break;
        case PLCrashReportOperatingSystemAppleTVOS:
            osName = @"Apple tvOS";
            break;
        default:
            osName = [NSString stringWithFormat: @"Unknown (%d)", report.systemInfo.operatingSystem];
            break;
    }
    
    /* Map to Apple-style code type, and mark whether architecture is LP64 (64-bit) */
    NSString *codeType = nil;
    {
        /* Attempt to derive the code type from the binary images */
        for (PLCrashReportBinaryImageInfo *image in report.images) {
            /* Skip images with no specified type */
            if (image.codeType == nil)
                continue;

            /* Skip unknown encodings */
            if (image.codeType.typeEncoding != PLCrashReportProcessorTypeEncodingMach)
                continue;
            
            switch (image.codeType.type) {
                case CPU_TYPE_ARM:
                    codeType = @"ARM";
                    lp64 = false;
                    break;
                    
                case CPU_TYPE_ARM64:
                    codeType = @"ARM-64";
                    lp64 = true;
                    break;

                case CPU_TYPE_X86:
                    codeType = @"X86";
                    lp64 = false;
                    break;

                case CPU_TYPE_X86_64:
                    codeType = @"X86-64";
                    lp64 = true;
                    break;

                case CPU_TYPE_POWERPC:
                    codeType = @"PPC";
                    lp64 = false;
                    break;
                    
                default:
                    // Do nothing, handled below.
                    break;
            }

            /* Stop immediately if code type was discovered */
            if (codeType != nil)
                break;
        }

        /* If we were unable to determine the code type, fall back on the processor info's value. */
        if (codeType == nil && report.systemInfo.processorInfo.typeEncoding == PLCrashReportProcessorTypeEncodingMach) {
            switch (report.systemInfo.processorInfo.type) {
                case CPU_TYPE_ARM:
                    codeType = @"ARM";
                    lp64 = false;
                    break;

                case CPU_TYPE_ARM64:
                    codeType = @"ARM-64";
                    lp64 = true;
                    break;

                case CPU_TYPE_X86:
                    codeType = @"X86";
                    lp64 = false;
                    break;

                case CPU_TYPE_X86_64:
                    codeType = @"X86-64";
                    lp64 = true;
                    break;

                case CPU_TYPE_POWERPC:
                    codeType = @"PPC";
                    lp64 = false;
                    break;

                default:
                    codeType = [NSString stringWithFormat: @"Unknown (%llu)", report.systemInfo.processorInfo.type];
                    lp64 = true;
                    break;
            }
        }
        
        /* If we still haven't determined the code type, we're totally clueless. */
        if (codeType == nil) {
            codeType = @"Unknown";
            lp64 = true;
        }
    }

    {
        NSString *hardwareModel = @"???";
        if (report.hasMachineInfo && report.machineInfo.modelName != nil)
            hardwareModel = report.machineInfo.modelName;

        NSString *incidentIdentifier = @"???";
        if (report.uuidRef != nil) {
            incidentIdentifier = (__bridge_transfer NSString *) CFUUIDCreateString(nil, report.uuidRef);
        }
    
        [text appendFormat: @"Incident Identifier: %@\n", incidentIdentifier];
        [text appendFormat: @"Hardware Model:      %@\n", hardwareModel];
    }
    
    /* Application and process info */
    {
        NSString *unknownString = @"???";
        
        NSString *processName = unknownString;
        NSString *processId = unknownString;
        NSString *processPath = unknownString;
        NSString *parentProcessName = unknownString;
        NSString *parentProcessId = unknownString;
        
        /* Process information was not available in earlier crash report versions */
        if (report.hasProcessInfo) {
            /* Process Name */
            if (report.processInfo.processName != nil)
                processName = report.processInfo.processName;
            
            /* PID */
            processId = [[NSNumber numberWithUnsignedInteger: report.processInfo.processID] stringValue];
            
            /* Process Path */
            if (report.processInfo.processPath != nil)
                processPath = report.processInfo.processPath;
            
            /* Parent Process Name */
            if (report.processInfo.parentProcessName != nil)
                parentProcessName = report.processInfo.parentProcessName;
            
            /* Parent Process ID */
            parentProcessId = [[NSNumber numberWithUnsignedInteger: report.processInfo.parentProcessID] stringValue];
        }
        
        NSString *versionString = report.applicationInfo.applicationVersion;
        /* Marketing version is optional */
        if (report.applicationInfo.applicationMarketingVersion != nil)
            versionString = [NSString stringWithFormat: @"%@ (%@)", report.applicationInfo.applicationMarketingVersion, report.applicationInfo.applicationVersion];
        
        [text appendFormat: @"Process:         %@ [%@]\n", processName, processId];
        [text appendFormat: @"Path:            %@\n", processPath];
        [text appendFormat: @"Identifier:      %@\n", report.applicationInfo.applicationIdentifier];
        [text appendFormat: @"Version:         %@\n", versionString];
        [text appendFormat: @"Code Type:       %@\n", codeType];
        [text appendFormat: @"Parent Process:  %@ [%@]\n", parentProcessName, parentProcessId];
    }
    
    [text appendString: @"\n"];
    
    /* System info */
    {
        NSString *osBuild = @"???";
        if (report.systemInfo.operatingSystemBuild != nil)
            osBuild = report.systemInfo.operatingSystemBuild;
        
        [text appendFormat: @"Date/Time:       %@\n", report.systemInfo.timestamp];
        [text appendFormat: @"OS Version:      %@ %@ (%@)\n", osName, report.systemInfo.operatingSystemVersion, osBuild];
        [text appendFormat: @"Report Version:  104\n"];
    }

    [text appendString: @"\n"];

    /* Exception code */
    [text appendFormat: @"Exception Type:  %@\n", report.signalInfo.name];
    [text appendFormat: @"Exception Codes: %@ at 0x%" PRIx64 "\n", report.signalInfo.code, report.signalInfo.address];
    
    for (PLCrashReportThreadInfo *thread in report.threads) {
        if (thread.crashed) {
            [text appendFormat: @"Crashed Thread:  %ld\n", (long) thread.threadNumber];
            break;
        }
    }
    
    [text appendString: @"\n"];
    
    /* Uncaught Exception */
    if (report.hasExceptionInfo) {
        [text appendFormat: @"Application Specific Information:\n"];
        [text appendFormat: @"*** Terminating app due to uncaught exception '%@', reason: '%@'\n",
                report.exceptionInfo.exceptionName, report.exceptionInfo.exceptionReason];
        
        [text appendString: @"\n"];
    }

    /* If an exception stack trace is available, output an Apple-compatible backtrace. */
    if (report.exceptionInfo != nil && report.exceptionInfo.stackFrames != nil && [report.exceptionInfo.stackFrames count] > 0) {
        PLCrashReportExceptionInfo *exception = report.exceptionInfo;
        
        /* Create the header. */
        [text appendString: @"Last Exception Backtrace:\n"];

        /* Write out the frames. In raw reports, Apple writes this out as a simple list of PCs. In the minimally
         * post-processed report, Apple writes this out as full frame entries. We use the latter format. */
        for (NSUInteger frame_idx = 0; frame_idx < [exception.stackFrames count]; frame_idx++) {
            PLCrashReportStackFrameInfo *frameInfo = [exception.stackFrames objectAtIndex: frame_idx];
            [text appendString: [self formatStackFrame: frameInfo frameIndex: frame_idx report: report lp64: lp64]];
        }
        [text appendString: @"\n"];
    }

    /* Threads */
    PLCrashReportThreadInfo *crashed_thread = nil;
    NSInteger maxThreadNum = 0;
    for (PLCrashReportThreadInfo *thread in report.threads) {
        if (thread.crashed) {
            [text appendFormat: @"Thread %ld Crashed:\n", (long) thread.threadNumber];
            crashed_thread = thread;
        } else {
            [text appendFormat: @"Thread %ld:\n", (long) thread.threadNumber];
        }
        for (NSUInteger frame_idx = 0; frame_idx < [thread.stackFrames count]; frame_idx++) {
            PLCrashReportStackFrameInfo *frameInfo = [thread.stackFrames objectAtIndex: frame_idx];
            [text appendString: [self formatStackFrame: frameInfo frameIndex: frame_idx report: report lp64: lp64]];
        }
        [text appendString: @"\n"];

        /* Track the highest thread number */
        maxThreadNum = MAX(maxThreadNum, thread.threadNumber);
    }

    
    return text;
}



+ (NSString *) formatStackFrame: (PLCrashReportStackFrameInfo *) frameInfo
                     frameIndex: (NSUInteger) frameIndex
                         report: (PLCrashReport *) report
                           lp64: (BOOL) lp64
{
    /* Base image address containing instrumention pointer, offset of the IP from that base
     * address, and the associated image name */
    uint64_t baseAddress = 0x0;
    uint64_t pcOffset = 0x0;
    NSString *imageName = @"\?\?\?";
    NSString *symbolString = nil;

    PLCrashReportBinaryImageInfo *imageInfo = [report imageForAddress:frameInfo.instructionPointer];
    if (imageInfo != nil) {
        imageName = [imageInfo.imageName lastPathComponent];
        baseAddress = imageInfo.imageBaseAddress;
        pcOffset = frameInfo.instructionPointer - imageInfo.imageBaseAddress;
    } else if (frameInfo.instructionPointer) {
    }

    /* If symbol info is available, the format used in Apple's reports is Sym + OffsetFromSym. Otherwise,
     * the format used is imageBaseAddress + offsetToIP */
    if (frameInfo.symbolInfo != nil) {
        NSString *symbolName = frameInfo.symbolInfo.symbolName;

        /* Apple strips the _ symbol prefix in their reports. */
        if ([symbolName rangeOfString: @"_"].location == 0 && [symbolName length] > 1) {
            switch (report.systemInfo.operatingSystem) {
                case PLCrashReportOperatingSystemMacOSX:
                case PLCrashReportOperatingSystemiPhoneOS:
                case PLCrashReportOperatingSystemAppleTVOS:
                case PLCrashReportOperatingSystemiPhoneSimulator:
                    symbolName = [symbolName substringFromIndex: 1];
                    break;

                default:
                    break;
            }
        }
        
        
        uint64_t symOffset = frameInfo.instructionPointer - frameInfo.symbolInfo.startAddress;
        symbolString = [NSString stringWithFormat: @"%@ + %" PRId64, symbolName, symOffset];
    } else {
        symbolString = [NSString stringWithFormat: @"0x%" PRIx64 " + %" PRId64, baseAddress, pcOffset];
    }

    /* Note that width specifiers are ignored for %@, but work for C strings.
     * UTF-8 is not correctly handled with %s (it depends on the system encoding), but
     * UTF-16 is supported via %S, so we use it here */
    return [NSString stringWithFormat: @"%-4ld%-35S 0x%0*" PRIx64 " %@\n",
            (long) frameIndex,
            (const uint16_t *)[imageName cStringUsingEncoding: NSUTF16StringEncoding],
            lp64 ? 16 : 8, frameInfo.instructionPointer,
            symbolString];
}

@end
