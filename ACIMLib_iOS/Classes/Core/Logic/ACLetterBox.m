//
//  ACGetNewMsgConf.m
//  ACIMLib
//
//  Created by 子木 on 2022/6/24.
//

#import "ACLetterBox.h"
#import "ACFileManager.h"

@interface ACGetNewMsgConf : NSObject <NSCoding>
@property (nonatomic, assign) long messageOffset;
@property (nonatomic, assign) long dialogStatusOffset;
@end

@implementation ACGetNewMsgConf

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInt64:self.messageOffset forKey:@"_offSet"];
    [aCoder encodeInt64:self.dialogStatusOffset forKey:@"_dialogOffSet"];
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.messageOffset = [aDecoder decodeInt64ForKey:@"_offSet"];
        self.dialogStatusOffset = [aDecoder decodeInt64ForKey:@"_dialogOffSet"];
    }
    return self;
}

@end

@implementation ACLetterBox

+ (void)setMessageOffSet:(long)offset {
    @synchronized (self) {
        ACGetNewMsgConf *conf = [self getLocalConf];
        conf.messageOffset = offset;
        [self saveConf:conf];
    }
}

+ (long)getMessageOffSet {
    return [self getLocalConf].messageOffset;
}

+ (void)setDialogStatusOffSet:(long)offset {
    @synchronized (self) {
        ACGetNewMsgConf *conf = [self getLocalConf];
        conf.dialogStatusOffset = offset;
        [self saveConf:conf];
    }
}

+ (long)getDialogStatusOffSet {
    return [self getLocalConf].dialogStatusOffset;
}


+ (ACGetNewMsgConf *)getLocalConf {
    ACGetNewMsgConf *conf;
    NSString *confiArchiverPath = [ACFileManager getUserArchiverFilePath:@"GetMsgConf"];
    if (confiArchiverPath) {
        conf = [NSKeyedUnarchiver unarchiveObjectWithFile:confiArchiverPath];
    }
    return conf ?: [ACGetNewMsgConf new];
}

+ (void)saveConf:(ACGetNewMsgConf *)conf {
    [NSKeyedArchiver archiveRootObject:conf toFile:[ACFileManager getUserArchiverFilePath:@"GetMsgConf"]];
}


@end
