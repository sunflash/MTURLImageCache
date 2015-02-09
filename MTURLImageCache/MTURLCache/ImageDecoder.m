//
//  ImageDecoder.m
//  MTURLImageCache
//
//  Created by Neon on 09/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

#import "ImageDecoder.h"

@implementation ImageDecoder

+ (UIImage *)decompressedImage:(UIImage*)image {
    
    if (image.images) {
        // Do not decode animated images
        return image;
    }
    
    CGImageRef originalImageRef = image.CGImage;
    const CGBitmapInfo originalBitmapInfo = CGImageGetBitmapInfo(originalImageRef);
    
    const uint32_t alphaInfo = (originalBitmapInfo & kCGBitmapAlphaInfoMask);
    CGBitmapInfo bitmapInfo = originalBitmapInfo;
    switch (alphaInfo)
    {
        case kCGImageAlphaNone:
            bitmapInfo &= ~kCGBitmapAlphaInfoMask;
            bitmapInfo |= kCGImageAlphaNoneSkipFirst;
            break;
        case kCGImageAlphaPremultipliedFirst:
        case kCGImageAlphaPremultipliedLast:
        case kCGImageAlphaNoneSkipFirst:
        case kCGImageAlphaNoneSkipLast:
            break;
        case kCGImageAlphaOnly:
        case kCGImageAlphaLast:
        case kCGImageAlphaFirst:
        { // Unsupported
            return image;
        }
            break;
    }
    
    const CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    const CGSize pixelSize = CGSizeMake(image.size.width * image.scale, image.size.height * image.scale);
    const CGContextRef context = CGBitmapContextCreate(NULL,
                                                       pixelSize.width,
                                                       pixelSize.height,
                                                       CGImageGetBitsPerComponent(originalImageRef),
                                                       0,
                                                       colorSpace,
                                                       bitmapInfo);
    CGColorSpaceRelease(colorSpace);
    
    // If failed, return undecompressed image
    if (!context) return image;
    
    const CGRect imageRect = CGRectMake(0, 0, pixelSize.width, pixelSize.height);
    UIGraphicsPushContext(context);
    
    // Flip coordinate system. See: http://stackoverflow.com/questions/506622/cgcontextdrawimage-draws-image-upside-down-when-passed-uiimage-cgimage
    CGContextTranslateCTM(context, 0, pixelSize.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // UIImage and drawInRect takes into account image orientation, unlike CGContextDrawImage.
    [image drawInRect:imageRect];
    UIGraphicsPopContext();
    const CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(decompressedImageRef);
    return decompressedImage;
}

@end
