//
//  ACBaseMacro.h
//  ACIMLib
//
//  Created by 子木 on 2022/6/13.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <pthread.h>

//字符串是否为空
#define kStringIsEmpty(str) ([str isKindOfClass:[NSNull class]] || str == nil || [str length] < 1 ? YES : NO )
//数组是否为空
#define kArrayIsEmpty(array) (array == nil || [array isKindOfClass:[NSNull class]] || array.count == 0)
//字典是否为空
#define kDictIsEmpty(dic) (dic == nil || [dic isKindOfClass:[NSNull class]] || dic.allKeys == 0)
//是否是空对象
#define kObjectIsEmpty(_object) (_object == nil \
|| [_object isKindOfClass:[NSNull class]] \
|| ([_object respondsToSelector:@selector(length)] && [(NSData *)_object length] == 0) \
|| ([_object respondsToSelector:@selector(count)] && [(NSArray *)_object count] == 0))


// NSCoding协议
#define ACHHJNSCoding(ClassName) - (void)encodeWithCoder:(NSCoder *)aCoder{\
unsigned int count = 0;\
Ivar * ivars = class_copyIvarList([ClassName class], &count);\
for (int i = 0; i < count; i++) {\
Ivar ivar = ivars[i];\
const char * name = ivar_getName(ivar);\
NSString * key = [NSString stringWithUTF8String:name];\
@try {\
[aCoder encodeObject:[self valueForKey:key] forKey:key];\
} @catch (NSException *exception) {\
} @finally {\
}\
}\
free(ivars);\
}\
\
- (instancetype)initWithCoder:(NSCoder *)aDecoder {\
if (self = [super init]) {\
unsigned int count = 0;\
Ivar * ivars = class_copyIvarList([ClassName class], &count);\
for (int i = 0; i < count; i++) {\
Ivar ivar = ivars[i];\
const char * name = ivar_getName(ivar);\
NSString * key = [NSString stringWithUTF8String:name];\
id value = [aDecoder decodeObjectForKey:key];\
@try {\
[self setValue:value forKey:key];\
} @catch (NSException *exception) {\
} @finally {\
}\
}\
free(ivars);\
}\
return self;\
}




// .h文件
#define ACSingletonH(name) + (instancetype)shared##name;

// .m文件
#define SGSingletonM(name) \
static id _instance=nil; \
\
+ (instancetype)allocWithZone:(struct _NSZone *)zone \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [super allocWithZone:zone]; \
}); \
return _instance; \
} \
\
+ (instancetype)shared##name \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [[self alloc] init]; \
}); \
return _instance; \
} \
\
- (id)copyWithZone:(NSZone *)zone \
{ \
return _instance; \
}



// 弱引用
#ifndef ac_weakify
#if DEBUG
#if __has_feature(objc_arc)
#define ac_weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define ac_weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#else
#if __has_feature(objc_arc)
#define ac_weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
#else
#define ac_weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
#endif
#endif
#endif

// 强引用
#ifndef ac_strongify
#if DEBUG
#if __has_feature(objc_arc)
#define ac_strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
#else
#define ac_strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
#endif
#else
#if __has_feature(objc_arc)
#define ac_strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define ac_strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif
#endif


static inline bool ac_dispatch_is_main_queue(void) {
    return pthread_main_np() != 0;
}


static inline void ac_dispatch_async_on_main_queue(void (^block)(void)) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}


static inline void ac_dispatch_sync_on_main_queue(void (^block)(void)) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}


