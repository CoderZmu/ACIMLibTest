/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "ACSDImageFrame.h"

@interface ACSDImageFrame ()

@property (nonatomic, strong, readwrite, nonnull) UIImage *image;
@property (nonatomic, readwrite, assign) NSTimeInterval duration;

@end

@implementation ACSDImageFrame

- (instancetype)initWithImage:(UIImage *)image duration:(NSTimeInterval)duration {
    self = [super init];
    if (self) {
        _image = image;
        _duration = duration;
    }
    return self;
}

+ (instancetype)frameWithImage:(UIImage *)image duration:(NSTimeInterval)duration {
    ACSDImageFrame *frame = [[ACSDImageFrame alloc] initWithImage:image duration:duration];
    return frame;
}

@end
