//
//  ImageCollectionViewCell.m
//  MTURLImageCache
//
//  Created by Neon on 10/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

#import "ImageCollectionViewCell.h"
#import "MTURLCache.h"

@interface ImageCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) URLCacheCancellationToken *cancellationToken;

@end

@implementation ImageCollectionViewCell

-(void)configureLogo:(NSString*)urlString {
    
    URLCacheCancellationToken *cancellationToken = [[MTURLCache sharedMTURLCache] getObjectFromURL:urlString completionHandler:^(BOOL success, UIImage *image, NSTimeInterval fetchTime, NSString *infoMessage) {
        
        if (success) self.imageView.image = image;
        
#ifdef DEBUG
        if (success) NSLog(@"%@ %f",infoMessage,fetchTime);
        else         NSLog(@"%@",infoMessage);
#endif
        
    }];
    
    self.cancellationToken = cancellationToken;
}

-(void)prepareForReuse {
    
    if (self.cancellationToken) [self.cancellationToken cancel];
    self.imageView.image = nil;
}

@end
