//
//  ACPushProfile.m
//  ACIMLib
//
//  Created by 子木 on 2022/7/21.
//

#import "ACPushProfile.h"
#import "ACFileManager.h"
#import "ACConnectionListenerManager.h"
#import "ACNetErrorConverter.h"
#import "ACBase.h"
#import "ACUpdatePushConfigPacket.h"
#import "ACGetPushConfigPacket.h"

@interface ACPushProfileMo : NSObject<NSCoding>
@property (nonatomic, copy) NSString *lan;
@property (nonatomic, assign, getter=isPreview) BOOL preview;
+ (NSString *)getLanJsonKey;
+ (NSString *)getPreviewJsonKey;
@end

@implementation ACPushProfileMo

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.lan.length ? self.lan : @"" forKey:@"_lan"];
    [aCoder encodeBool:self.preview forKey:@"_preview"];
   
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _lan = [aDecoder decodeObjectForKey:@"_lan"];
        _preview = [aDecoder decodeBoolForKey:@"_preview"];
    }
    return self;
}

+ (instancetype)pushProfileWithJsonString:(NSString *)jsonString {
    ACPushProfileMo *instance = [[ACPushProfileMo alloc] init];
    
    if (![jsonString isKindOfClass:NSString.class] || !jsonString.length) return instance;
    NSDictionary *keyValues = [jsonString ac_jsonValueDecoded];
    if (![keyValues isKindOfClass:NSDictionary.class]) return instance;
    
    
    instance.lan = keyValues[[self getLanJsonKey]];
    instance.preview = [keyValues[[self getPreviewJsonKey]] boolValue];
    return instance;
}

+ (NSString *)getLanJsonKey {
    return @"lan";
}

+ (NSString *)getPreviewJsonKey {
    return @"preview";
}

@end

@interface ACPushProfile()<ACConnectionListenerProtocol>
@property (nonatomic, strong) ACPushProfileMo *profileMo;
@end

@implementation ACPushProfile

- (instancetype)init {
    self = [super init];
    _profileMo = [self createDefaultProfile];
    [[ACConnectionListenerManager shared] addListener:self];
    return self;
}


#pragma mark - ACConnectionListenerProtocol

- (void)userDataDidLoad {
    ACPushProfileMo *m = [NSKeyedUnarchiver unarchiveObjectWithFile:[self pushProfileArchivePath]];
    _profileMo = m ?: [self createDefaultProfile];
    
    [[[ACGetPushConfigPacket alloc] init] sendWithSuccessBlockIdParameter:^(ACPBGetPushConfigResp * _Nonnull response) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.profileMo = [ACPushProfileMo pushProfileWithJsonString:response.content];
            [self updatePushProfile];
        });
    } failure:nil];
}


#pragma mark - Public

- (void)updateShowPushContentStatus:(BOOL)isShowPushContent
                            success:(void (^)(void))successBlock
                              error:(void (^)(ACErrorCode status))errorBlock {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@(isShowPushContent) forKey:[ACPushProfileMo getPreviewJsonKey]];
    
    [[[ACUpdatePushConfigPacket alloc] initWithConfig:[NSString ac_jsonStringWithJsonObject:dict]] sendWithSuccessBlockEmptyParameter:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.profileMo.preview = isShowPushContent;
            [self updatePushProfile];
            successBlock();
        });
    } failure:^(NSError * _Nonnull error, NSInteger errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock([ACNetErrorConverter toAcErrorCodeEnumProperty:errorCode]);
        });
    }];
    
}

- (void)setPushLanguageCode:(NSString *)language
                    success:(void (^)(void))successBlock
                      error:(void (^)(ACErrorCode status))errorBlock {
    if (!language.length) {
        errorBlock(INVALID_PARAMETER);
        return;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:language forKey:[ACPushProfileMo getLanJsonKey]];
    [[[ACUpdatePushConfigPacket alloc] initWithConfig:[NSString ac_jsonStringWithJsonObject:dict]] sendWithSuccessBlockEmptyParameter:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.profileMo.lan = language;
            [self updatePushProfile];
            successBlock();
        });
    } failure:^(NSError * _Nonnull error, NSInteger errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock([ACNetErrorConverter toAcErrorCodeEnumProperty:errorCode]);
        });
    }];
}

- (BOOL)isShowPushContent {
    return _profileMo.isPreview;
}


- (ACPushLanguage)pushLanguage {
    if ([_profileMo.lan isEqualToString:@"en_US"]) return ACPushLanguage_EN_US;
    return ACPushLanguage_ZH_CN;
}


#pragma mark - Private

- (ACPushProfileMo *)createDefaultProfile {
    ACPushProfileMo *mo = [[ACPushProfileMo alloc] init];
    mo.lan = @"zh_CN";
    mo.preview = NO;
    return mo;
}


-(void)updatePushProfile {
    [NSKeyedArchiver archiveRootObject:self.profileMo toFile:[self pushProfileArchivePath]];
}


- (NSString *)pushProfileArchivePath {
    return [ACFileManager getUserArchiverFilePath:@"PushProfile" ];
}



@end
