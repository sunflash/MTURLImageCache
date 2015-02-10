//
//  LogoCollectionViewController.m
//  MTURLImageCache
//
//  Created by Neon on 10/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

#import "LogoCollectionViewController.h"
#import "NetworkParameter.h"
#import "NetworkTask.h"
#import "ImageCollectionViewCell.h"
#import "MTURLImageCache.h"

@interface LogoCollectionViewController ()

@property (nonatomic, strong) NSArray *logoURL;

@end

@implementation LogoCollectionViewController

//-------------------------------------------------------------------------------------------------------------

#pragma mark - View

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    [self getLogoData];
}

//-------------------------------------------------------------------------------------------------------------

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.logoURL.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (indexPath.row < self.logoURL.count) {
        
        NSString *urlString = [self.logoURL objectAtIndex:indexPath.row];
        
        [[MTURLImageCache sharedMTURLImageCache] getImageFromURL:urlString completionHandler:^(BOOL success, UIImage *image, NSTimeInterval fetchTime, NSString *errorMessage) {
            
            NSLog(@"%f %@",fetchTime,errorMessage);
            
            if (success) {
                
                cell.imageView.image = image;
            }
        }];
    }
    
    return cell;
}

//-------------------------------------------------------------------------------------------------------------

#pragma mark - Fuction

-(void)getLogoData {

    [NetworkTask getDataWithBaseURL:BackendURL path:@"customers" completion:^(BOOL success, NSArray *data) {

        NSMutableArray *logosURLString = [NSMutableArray new];
        
        [data enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            [logosURLString addObject:obj[@"logourl"]];
        }];
        
        self.logoURL = [NSArray arrayWithArray:logosURLString];
        [self.collectionView reloadData];
    }];
}

@end
