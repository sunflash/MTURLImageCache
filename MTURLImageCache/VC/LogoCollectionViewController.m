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
@property (nonatomic, weak) IBOutlet UIBarButtonItem *emptyLogoItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *refreshLogoItem;

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
        
        //cell.imageView.image = [[MTURLImageCache sharedMTURLImageCache] getImageFromURL:urlString];
        
        URLCacheCancellationToken *cancellationToken = [[MTURLImageCache sharedMTURLImageCache] getImageFromURL:urlString
                                                        completionHandler:^(BOOL success, UIImage *image, NSTimeInterval fetchTime, NSString *infoMessage) {
            
            if (success) cell.imageView.image = image;
            
            if (success) NSLog(@"%@ %f",infoMessage,fetchTime);
            else         NSLog(@"%@",infoMessage);
        }];
        
        [cancellationToken cancel];
    }
    
    return cell;
}

//-------------------------------------------------------------------------------------------------------------

#pragma mark - Function

-(void)getLogoData {

    [NetworkTask getDataWithBaseURL:BackendURL path:@"customers" completion:^(BOOL success, NSArray *data) {
        
        data = [data sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];

        NSMutableArray *logosURLString = [NSMutableArray new];
        float scale = [UIScreen mainScreen].scale;
        __block NSDictionary *parameters = (scale > 1.1) ? @{} : @{@"w":@130,@"h":@130};
        
        [data enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            [logosURLString addObject:[self getURL:obj[@"logourl"] parameters:parameters]];
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

-(IBAction)emptyLogos:(id)sender {

    [[MTURLImageCache sharedMTURLImageCache] emptyCacheFolder];
}

-(IBAction)refreshLogos:(id)sender {

    [self getLogoData];
}

@end
