//
//  ACServerTime.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/23.
//

#import "ACServerTime.h"
#import "ACActionType.h"
#import "ACEventBus.h"
#import "ACServerTimePacket.h"
#import <sys/sysctl.h>

static long milliDelta__ = 0;
static bool isSyncDone__ = false;

@implementation ACServerTime

+ (void)initialize {
    milliDelta__ = [[NSDate date] timeIntervalSince1970] * 1000 - [self getSystemUptime];
}


//get system uptime since last boot
+ (long)getSystemUptime
{
    struct timeval boottime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(boottime);
    struct timeval now;
    struct timezone tz;
    gettimeofday(&now, &tz);
    double uptime = -1;
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0)
    {
        uptime = (now.tv_sec - boottime.tv_sec) * 1000;
        uptime += (double)(now.tv_usec - boottime.tv_usec) / 1000.0;
    }
    long ret = (long)uptime;
    return ret;
}

+ (long)getServerMSTime {
    return [self getSystemUptime] + milliDelta__;
}

+ (BOOL)isSyncDone {
    return isSyncDone__;
}


+ (void)performTimeSynchronization {
    long time1 = [self getSystemUptime];
    ACServerTimePacket *request = [[ACServerTimePacket alloc] init];
    [request sendWithSuccessBlockIdParameter:^(ACPBSystemCurrentTimeMillisResp * _Nonnull response) {
        long nowTime = [self getSystemUptime];
        milliDelta__ = response.currentTimeMillis + (nowTime - time1)/2 - nowTime;
        isSyncDone__ = true;
        [[ACEventBus globalEventBus] emit:kServerTimeDidSyncNoti];
    } failure:nil];
}

@end
