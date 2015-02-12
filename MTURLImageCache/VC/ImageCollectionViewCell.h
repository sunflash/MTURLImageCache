//
//  ImageCollectionViewCell.h
//  MTURLImageCache
//
//  Created by Neon on 10/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *imageView;

-(void)displayImageFromURL:(NSString*)urlString;

@end
