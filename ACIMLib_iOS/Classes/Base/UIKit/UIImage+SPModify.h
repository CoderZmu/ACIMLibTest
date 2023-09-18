//
//  UIImage+SPModify.h
//  SPBase_Example
//
//  Created by 子木 on 2019/6/13.
//  Copyright © 2019 ZiMu-cd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, ACImageEncodeFormat) {
    ACImageEncodeFormat_IO,
    ACImageEncodeFormat_Webp ,
};


@interface UIImage (SPModify)

- (UIImage *)sp_fixOrientation;

// 无损压缩图片
- (NSData *)sp_losslessCompress;

// 压缩图片
- (NSData *)sp_compressIntelligently:(ACImageEncodeFormat)encodeFormat finalPixelSize:(CGSize *)finalPixelSize;

// 略缩图
- (NSData *)sp_thumbnail:(ACImageEncodeFormat)encodeFormat ;

/**
 根据给定的显示模式重绘图片到指定的矩形框

 @param rect 矩形框
 @param contentMode 显示模式
 @param clips 超过框的内容是否被裁减
 */
- (void)sp_drawInRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode clipsToBounds:(BOOL)clips;

// 缩放图片到指定的尺寸，如果图片具体尺寸跟被缩放的尺寸比例不一致，则会被拉伸
- (UIImage *)sp_imageByResizeToSize:(CGSize)size;

// 根据给定的最大尺寸调整图片；如果图片当前尺寸小于给定值，直接返回
- (UIImage *)sp_imageScaleToMaxSize:(CGSize)maxSize;

// 根据给定的显示模式缩放图片到指定的尺寸
- (UIImage *)sp_imageByResizeToSize:(CGSize)size contentMode:(UIViewContentMode)contentMode;

// 绘制带圆角的图片
- (UIImage *)sp_imageByRoundCornerRadius:(CGFloat)radius;

- (UIImage *)sp_imageByRoundCornerRadius:(CGFloat)radius
                          borderWidth:(CGFloat)borderWidth
                          borderColor:(nullable UIColor *)borderColor;

- (nullable UIImage *)sp_imageByRoundCornerRadius:(CGFloat)radius
                                       corners:(UIRectCorner)corners
                                   borderWidth:(CGFloat)borderWidth
                                   borderColor:(nullable UIColor *)borderColor
                                borderLineJoin:(CGLineJoin)borderLineJoin;


@end

NS_ASSUME_NONNULL_END
