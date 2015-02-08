//
//  MTURLImageCache.m
//  MTURLImageCache
//
//  Created by Neon on 04/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

#import "MTURLImageCache.h"

@interface MTURLImageCache ()

@property (nonatomic, strong) NSURLSession *urlSession;

@end

@implementation MTURLImageCache

+ (id)sharedMTURLImageCache {
    
    static MTURLImageCache *urlImageCache = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
    
        urlImageCache                            = [MTURLImageCache new];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        urlImageCache.urlSession                 = [NSURLSession sessionWithConfiguration:configuration];
        urlImageCache.expiredMaxAgeInSeconds     = defaultExpiredMaxAgeInSeconds;
        urlImageCache.maxCachePeriod             = defaultMaxCachePeriodInDays;
        urlImageCache.cacheFolderName            = defulatCacheRootFolderName;
    });
    
    return urlImageCache;
}

-(void)setSessionHTTPAdditionalHeaders:(NSDictionary *)sessionHTTPAdditionalHeaders {

    if (sessionHTTPAdditionalHeaders) {
        
        [self.urlSession finishTasksAndInvalidate];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.HTTPAdditionalHeaders = sessionHTTPAdditionalHeaders;
        self.urlSession = [NSURLSession sessionWithConfiguration:configuration];
    }
}

//typedef void (^MTImageCacheResponse)(BOOL success,UIImage *image,float fetchTime,NSString *errorMessage);

-(void)getImageFromURL:(NSString *)urlString withCachePolicy:(MTURLImageCachePolicies)cachePolicy completionHandler:(MTImageCacheResponse)completionHandler {
    
    if (urlString && urlString.length > 0) {
        
        UIImage *image = [self isImageOnDisk:urlString];
        
        //if (image) completionHandler(NO,image,)
            
        
        
    }
    else completionHandler (NO,nil,0,@"Missing url parameter");
    
}

-(UIImage*)isImageOnDisk:(NSString*)urlString {
    
    //[]


    return nil;

}




@end
