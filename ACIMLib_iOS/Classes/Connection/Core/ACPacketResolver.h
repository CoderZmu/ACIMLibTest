//
//  ACPackageResolver.h
//  ACConnection
//
//  Created by 子木 on 2022/6/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol ACPacketResolverDelegate;

@interface ACPacketResolver : NSObject
@property (nonatomic, weak) id<ACPacketResolverDelegate> delegate;

- (void)receive:(NSData *)data;
- (void)clear;
@end

@protocol ACPacketResolverDelegate <NSObject>

- (void)packetResolver:(ACPacketResolver *)resolver didResolveAPackage:(int32_t)commandId payload:(NSData *)payload;

- (void)packetResolverFailed:(ACPacketResolver *)resolver;

@end

NS_ASSUME_NONNULL_END
