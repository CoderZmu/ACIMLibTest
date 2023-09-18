/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "ACSDImageCoder.h"

NS_ASSUME_NONNULL_BEGIN

/**
Integer value
Quality/speed trade-off (0=fast, 6=slower-better)
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPMethod;

/**
Integer value
Number of entropy-analysis passes (in [1..10])
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPPass;

/**
 Integer value
 Preprocessing filter (0=none, 1=segment-smooth)
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPPreprocessing;

/**
 Float value
 if non-zero, specifies the minimal distortion to try to achieve. Takes precedence over target_size.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPTargetPSNR;

/**
 Integer value
 If non-zero, try and use multi-threaded encoding.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPThreadLevel;

/**
 Integer value
 If set, reduce memory usage (but increase CPU use).
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPLowMemory;

/**
 Integer value
 if non-zero, specifies the minimal distortion to try to achieve. Takes precedence over target_size.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPSegments;

/**
 Integer value
 Spatial Noise Shaping. 0=off, 100=maximum.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPSnsStrength;

/**
 Integer value
 Range: [0 = off .. 100 = strongest]
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPFilterStrength;

/**
 Integer value
 range: [0 = off .. 7 = least sharp]
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPFilterSharpness;

/**
 Integer value
 Filtering type: 0 = simple, 1 = strong (only used If filter_strength > 0 or autofilter > 0)
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPFilterType;

/**
 Integer value
 Auto adjust filter's strength [0 = off, 1 = on]
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPAutofilter;

/**
 Integer value
 Algorithm for encoding the alpha plane (0 = none, 1 = compressed with WebP lossless). Default is 1.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPAlphaCompression;

/**
 Integer value
 Predictive filtering method for alpha plane. 0: none, 1: fast, 2: best. Default if 1.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPAlphaFiltering;

/**
 Integer value
 Between 0 (smallest size) and 100 (lossless).
 Default is 100.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPAlphaQuality;

/**
 Integer value
 If true, export the compressed picture back.
 In-loop filtering is not applied.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPShowCompressed;

/**
 Integer
 Log2(number of token partitions) in [0..3]
 Default is set to 0 for easier progressive decoding.
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPPartitions;

/**
 Integer value
 Quality degradation allowed to fit the 512k limit on
 Prediction modes coding (0: no degradation, 100: maximum possible degradation).
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPPartitionLimit;

/**
 Integer value
 if needed, use sharp (and slow) RGB->YUV conversion
 */
FOUNDATION_EXPORT ACSDImageCoderOption _Nonnull const ACSDImageCoderEncodeWebPUseSharpYuv;

NS_ASSUME_NONNULL_END
