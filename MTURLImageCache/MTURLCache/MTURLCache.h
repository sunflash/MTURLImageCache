//
//  MTURLCache.h
//  MTURLCache
//
//  Created by Neon on 04/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

@import Foundation;
@import UIKit;

//-------------------------------------------------------------------------------

#pragma mark - Cancellation Token

@interface URLCacheCancellationToken : NSObject

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic) BOOL isCancelled;

-(void)cancel;

@end

//-------------------------------------------------------------------------------

#pragma mark - Default Cache Parameters

#define defulatCacheRootFolderName       @"MTUCF"
#define defaultMaxCachePeriodInDays      21
#define defaultGlobalDiskCapacityMB      300

#define defaultExpiredMaxAgeInSeconds    60*60*24

//-------------------------------------------------------------------------------

#pragma mark - Cache Interface

typedef NS_ENUM(NSUInteger,CacheObjectType) {
    CacheObjectTypeUnknown,
    CacheObjectTypeImage,
    CacheObjectTypeJSON
};

@interface MTURLCache : NSObject

// Default 1 day, 60*60*24
@property (nonatomic) NSTimeInterval expiredMaxAgeInSeconds;
@property (nonatomic, strong) NSDictionary *sessionHTTPAdditionalHeaders;
@property (nonatomic) CacheObjectType cacheObjectType;

-(instancetype)initWithName:(NSString*)name;
+ (id)sharedMTURLCache;
+ (id)sharedMTURLJSONCache;
+ (id)sharedMTURLImageCache;

//-------------------------------------------------------------------------------

#pragma mark - Get/Prefetch Object

typedef void (^MTCacheResponse)(BOOL success,id object, NSTimeInterval fetchTime, NSString *infoMessage);

-(URLCacheCancellationToken*)getObjectFromURL:(NSString *)urlString completionHandler:(MTCacheResponse)completionHandler;
-(id)getObjectFromURL:(NSString*)urlString;
-(void)prefetchObjectFromURL:(NSString*)urlString;

//-------------------------------------------------------------------------------

#pragma mark - Image

-(CGSize)getDiskImageSizeWithoutLoadingIntoMemory:(NSString*)urlString;

//-------------------------------------------------------------------------------

#pragma mark - Clean Cache

-(void)removeCachedFileWithURL:(NSString*)urlString;
-(void)emptyCacheFolder;

typedef void (^MTCacheCleanStat) (NSDictionary *cleanStatInfo);
+(void)backgroundCleanDisk;
+(void)cleanDiskWithCompletion:(MTCacheCleanStat)completionBlock;
+(void)cleanDiskWithCompletionAsync:(MTCacheCleanStat)completionBlock;

@end
