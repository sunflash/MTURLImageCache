//
//  HeaderTableViewCell.m
//  MTURLImageCache
//
//  Created by Neon on 13/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

#import "HeaderTableViewCell.h"
#import "MTURLCache.h"

@interface HeaderTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *companyNameLabel;
@property (nonatomic, weak) IBOutlet UIImageView *headerImageView;
@property (nonatomic, weak) IBOutlet UIView *primaryView;
@property (nonatomic, weak) IBOutlet UILabel *primaryTextLabel;
@property (nonatomic, weak) IBOutlet UIView *secondaryView;
@property (nonatomic, weak) IBOutlet UILabel *secondaryTextLabel;

@property (nonatomic, strong) URLCacheCancellationToken *cancellationToken;

@end

@implementation HeaderTableViewCell

+ (UIColor *)colorWithHexString:(NSString *)string {
    
    const char *cStr = [string cStringUsingEncoding:NSASCIIStringEncoding];
    long col = strtol(cStr+1, NULL, 16);
    
    unsigned char r, g, b;
    b = col & 0xFF;
    g = (col >> 8) & 0xFF;
    r = (col >> 16) & 0xFF;
    
    return [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
}

-(void)configureHeader:(NSDictionary*)headerDict {
    
    UIColor *lightGrayColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    UIColor *whiteColor     = [UIColor whiteColor];
    
    if (headerDict) {
     
        self.companyNameLabel.text      = headerDict[@"companyName"];
        self.companyNameLabel.textColor = (headerDict[@"headerTextColor"]) ? [HeaderTableViewCell colorWithHexString:headerDict[@"headerTextColor"]] : whiteColor;
        
        self.primaryTextLabel.text      = (headerDict[@"primaryColor"]) ? @"Primary" : @"Primary Unavailable";
        self.primaryTextLabel.textColor = (headerDict[@"headerTextColor"]) ? [HeaderTableViewCell colorWithHexString:headerDict[@"headerTextColor"]] : whiteColor;
        
        self.secondaryTextLabel.text      = (headerDict[@"secondaryColor"]) ? @"Secondary" : @"Secondary Unavailable";
        self.secondaryTextLabel.textColor = (headerDict[@"headerTextColor"]) ? [HeaderTableViewCell colorWithHexString:headerDict[@"headerTextColor"]] : whiteColor;
        
        self.primaryView.backgroundColor = (headerDict[@"primaryColor"]) ? [HeaderTableViewCell colorWithHexString:headerDict[@"primaryColor"]] : lightGrayColor;
        self.secondaryView.backgroundColor = (headerDict[@"secondaryColor"]) ? [HeaderTableViewCell colorWithHexString:headerDict[@"secondaryColor"]] :lightGrayColor;

        NSString *headerURLString = headerDict[@"headerURL"];
        
        if (headerURLString && headerURLString.length > 0) {
            
            URLCacheCancellationToken *cancellationToken = [[MTURLCache sharedMTURLImageCache] getObjectFromURL:headerURLString completionHandler:^(BOOL success, id object, NSTimeInterval fetchTime, NSString *infoMessage) {
                
                if (success) self.headerImageView.image = object;
                
#ifdef DEBUG
                if (success) NSLog(@"%@ %f",infoMessage,fetchTime);
                else         NSLog(@"%@",infoMessage);
#endif
            }];
            
            self.cancellationToken = cancellationToken;
        }
    }
}

-(void)prepareForReuse {
    [super prepareForReuse];
    
    if (self.cancellationToken) [self.cancellationToken cancel];
    
    UIColor *lightGrayColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    UIColor *whiteColor = [UIColor whiteColor];
    
    self.companyNameLabel.text   = @"Company Name";
    self.primaryTextLabel.text   = @"Primary";
    self.secondaryTextLabel.text = @"Secondary";
    
    self.companyNameLabel.textColor   = whiteColor;
    self.primaryTextLabel.textColor   = whiteColor;
    self.secondaryTextLabel.textColor = whiteColor;
    
    self.imageView.image               = nil;
    self.primaryView.backgroundColor   = lightGrayColor;
    self.secondaryView.backgroundColor = lightGrayColor;
}

@end
