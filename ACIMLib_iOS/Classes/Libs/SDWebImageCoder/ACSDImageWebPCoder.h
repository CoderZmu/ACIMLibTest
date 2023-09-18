/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "ACSDImageCoder.h"
/**
 Built in coder that supports WebP and animated WebP
 */
@interface ACSDImageWebPCoder : NSObject <ACSDImageCoder>

@property (nonatomic, class, readonly, nonnull) ACSDImageWebPCoder *sharedCoder;

@end
