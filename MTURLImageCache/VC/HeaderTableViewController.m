//
//  HeaderTableViewController.m
//  MTURLImageCache
//
//  Created by Neon on 13/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

#import "HeaderTableViewController.h"
#import "HeaderTableViewCell.h"
#import "NetworkParameter.h"
#import "NetworkTask.h"
#import "MTURLImageCache.h"
#import "CSURITemplate.h"

@interface HeaderTableViewController ()

@property (nonatomic, strong) NSArray *headerArray;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *refreshButton;

@end

//-------------------------------------------------------------------------------------------------------------

#pragma mark - View

@implementation HeaderTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[MTURLImageCache sharedMTURLImageCache] setSessionHTTPAdditionalHeaders:@{@"ocp-apim-subscription-key":BackendAccessKey,@"API-Authorization":BackendAPIKey}];
    
    [self getHeaderData];
    [self addPushToUpdate];
}

//-------------------------------------------------------------------------------------------------------------

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.headerArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    HeaderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    if (indexPath.section < self.headerArray.count) {
        
        NSDictionary *headerDict = [self.headerArray objectAtIndex:indexPath.section];
        [cell configureHeader:headerDict];
    }
    
    return cell;
}

//-------------------------------------------------------------------------------------------------------------

#pragma mark - Function

-(void)getHeaderData {
    
    [NetworkTask getDataWithBaseURL:BackendURL path:@"customers" completion:^(BOOL success, NSArray *data) {
        
        data = [data sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
        
        NSMutableArray *headerMutableArray = [NSMutableArray new];
        
        [data enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            NSString *primaryColor    = obj[@"primarycolor"];
            NSString *secondaryColor  = obj[@"secondarycolor"];
            NSString *headerTextColor = obj[@"headertextcolor"];
            NSString *headerURLString = obj[@"headerimageurl"];
            NSString *companyName     = obj[@"name"];
            
            if (companyName && companyName.length > 0) {
                
                NSMutableDictionary *headerMutableDict = [NSMutableDictionary new];
                
                if (companyName && companyName.length > 0)              headerMutableDict[@"companyName"]       = companyName;
                if (primaryColor && primaryColor.length > 0)            headerMutableDict[@"primaryColor"]      = primaryColor;
                if (secondaryColor && secondaryColor.length > 0)        headerMutableDict[@"secondaryColor"]    = secondaryColor;
                if (headerTextColor && headerTextColor.length > 0)      headerMutableDict[@"headerTextColor"]   = headerTextColor;
                if (headerURLString && headerURLString.length > 0)      headerMutableDict[@"headerURL"]         = headerURLString;
                
                [headerMutableArray addObject:[NSDictionary dictionaryWithDictionary:headerMutableDict]];
            }
        }];
        
        self.HeaderArray = [NSArray arrayWithArray:headerMutableArray];
        [self.tableView reloadData];
    }];
}

-(IBAction)refreshHeader:(id)sender {

    [[MTURLImageCache sharedMTURLImageCache] emptyCacheFolder];
    [self getHeaderData];
    [self.refreshControl endRefreshing];
}

-(void)addPushToUpdate {
    
    self.refreshControl = [UIRefreshControl new];
    self.refreshControl.backgroundColor = [UIColor purpleColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self action:@selector(refreshHeader:) forControlEvents:UIControlEventValueChanged];
}

@end
