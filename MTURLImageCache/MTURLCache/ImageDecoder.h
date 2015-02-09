//
//  ImageDecoder.h
//  MTURLImageCache
//
//  Created by Neon on 09/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface ImageDecoder : NSObject

+ (UIImage *)decompressedImage:(UIImage*)image;

@end
