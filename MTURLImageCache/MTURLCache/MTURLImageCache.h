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
#define defaultMaxCachePeriodInDays      21
#define defaultGlobalDiskCapacityMB      100

#define defaultExpiredMaxAgeInSeconds    86400

typedef void (^MTImageCacheResponse)(BOOL success,UIImage *image, NSTimeInterval fetchTime, NSString *errorMessage);
typedef void (^MTImageCacheCleanStat) (NSDictionary *cleanStatInfo);

@interface MTURLImageCache : NSObject

@property (nonatomic, strong) NSString *cacheFolderName;
@property (nonatomic, strong) NSDictionary *sessionHTTPAdditionalHeaders;

// Default 1 day, 60*60*24
@property (nonatomic) NSTimeInterval expiredMaxAgeInSeconds;

-(instancetype)initWithName:(NSString*)name;

+ (id)sharedMTURLImageCache;

-(void)getImageFromURL:(NSString *)urlString completionHandler:(MTImageCacheResponse)completionHandler;

-(void)removeCachedFileWithURL:(NSString*)urlString;
-(void)emptyCacheFolder;

+(void)backgroundCleanDisk;
+(void)cleanDiskWithCompletion:(MTImageCacheCleanStat)completionBlock;
+(void)cleanDiskWithCompletionAsync:(MTImageCacheCleanStat)completionBlock;

@end
