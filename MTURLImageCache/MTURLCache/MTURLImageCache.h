//
//  MTURLImageCache.h
//  MTURLImageCache
//
//  Created by Neon on 04/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface URLCacheCancellationToken : NSObject

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic) BOOL isCancelled;

-(void)cancel;

@end

#define defulatCacheRootFolderName       @"MTUCF"
#define defaultMaxCachePeriodInDays      21
#define defaultGlobalDiskCapacityMB      100

#define defaultExpiredMaxAgeInSeconds    60*60*24

typedef void (^MTImageCacheResponse)(BOOL success,UIImage *image, NSTimeInterval fetchTime, NSString *infoMessage);
typedef void (^MTImageCacheCleanStat) (NSDictionary *cleanStatInfo);

@interface MTURLImageCache : NSObject

@property (nonatomic, strong) NSDictionary *sessionHTTPAdditionalHeaders;

// Default 1 day, 60*60*24
@property (nonatomic) NSTimeInterval expiredMaxAgeInSeconds;

-(instancetype)initWithName:(NSString*)name;

+ (id)sharedMTURLImageCache;

-(URLCacheCancellationToken*)getImageFromURL:(NSString *)urlString completionHandler:(MTImageCacheResponse)completionHandler;
-(UIImage*)getImageFromURL:(NSString*)urlString;
-(void)prefetchImageFromURL:(NSString*)urlString;

-(void)removeCachedFileWithURL:(NSString*)urlString;
-(void)emptyCacheFolder;

+(void)backgroundCleanDisk;
+(void)cleanDiskWithCompletion:(MTImageCacheCleanStat)completionBlock;
+(void)cleanDiskWithCompletionAsync:(MTImageCacheCleanStat)completionBlock;

@end
