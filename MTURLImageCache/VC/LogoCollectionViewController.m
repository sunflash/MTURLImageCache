//
//  LogoCollectionViewController.m
//  MTURLImageCache
//
//  Created by Neon on 10/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

#import "LogoCollectionViewController.h"
#import "ImageCollectionViewCell.h"
#import "NetworkParameter.h"
#import "NetworkTask.h"
#import "MTURLImageCache.h"
#import "CSURITemplate.h"

@interface LogoCollectionViewController ()

@property (nonatomic, strong) NSArray *logoURL;

@end

@implementation LogoCollectionViewController

//-------------------------------------------------------------------------------------------------------------

#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[MTURLImageCache sharedMTURLImageCache] setSessionHTTPAdditionalHeaders:@{@"ocp-apim-subscription-key":BackendAccessKey,@"API-Authorization":BackendAPIKey}];
    
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
    
    ImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LogoCell" forIndexPath:indexPath];
    cell.imageView.image = nil;
    
    if (indexPath.row < self.logoURL.count) {
        
        NSString *urlString = [self.logoURL objectAtIndex:indexPath.row];
        
        [[MTURLImageCache sharedMTURLImageCache] getImageFromURL:urlString completionHandler:^(BOOL success, UIImage *image, NSTimeInterval fetchTime, NSString *infoMessage) {
            
            if (success) cell.imageView.image = image;
            
            if (success) NSLog(@"%@ %f",infoMessage,fetchTime);
            else         NSLog(@"%@",infoMessage);
        }];
    }
    
    return cell;
}

//-------------------------------------------------------------------------------------------------------------

#pragma mark - Function

-(void)getLogoData {

    [NetworkTask getDataWithBaseURL:BackendURL path:@"customers" completion:^(BOOL success, NSArray *data) {

        NSMutableArray *logosURLString = [NSMutableArray new];
        
        [data enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            [logosURLString addObject:[self getURL:obj[@"logourl"] parameters:@{}]];
        }];
        
        self.logoURL = [NSArray arrayWithArray:logosURLString];
        [self.collectionView reloadData];
    }];
}

-(NSString *)getURL:(NSString *)urlBaseString parameters:(NSDictionary *)parameters {
    
    CSURITemplate *template = [CSURITemplate URITemplateWithString:urlBaseString error:nil];
    NSURL *url = [NSURL URLWithString:[template relativeStringWithVariables:parameters error:nil]];
    
    return url.absoluteString;
}

@end
