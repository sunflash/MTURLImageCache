//
//  MTURLImageCache.h
//  MTURLImageCache
//
//  Created by Neon on 04/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

@import Foundation;
@import UIKit;

#define defulatCacheRootFolderName       @"MTUCF"
#define defaultExpiredMaxAgeInSeconds    86400
#define defaultMaxCachePeriodInDays      21

typedef NS_ENUM(NSUInteger, MTURLImageCachePolicies) {
    
    DeleteExpiredFile,
    KeepExpiredFileUntilReplace
};

typedef void (^MTImageCacheResponse)(BOOL success,UIImage *image, NSTimeInterval fetchTime, NSString *errorMessage);

@interface MTURLImageCache : NSObject

@property (nonatomic, strong) NSString *cacheFolderName;
@property (nonatomic, strong) NSDictionary *sessionHTTPAdditionalHeaders;

// Default 1 day, 60*60*24
@property (nonatomic) NSTimeInterval expiredMaxAgeInSeconds;

// Default 21 day, no matter of which cachePolicies is used, prevent unused data fill up disk space
@property (nonatomic) float maxCachePeriod;

+ (id)sharedMTURLImageCache;

-(void)getImageFromURL:(NSString *)urlString withCachePolicy:(MTURLImageCachePolicies)cachePolicy completionHandler:(MTImageCacheResponse)completionHandler;

@end
