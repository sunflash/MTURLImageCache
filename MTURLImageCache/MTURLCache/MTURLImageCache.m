//
//  MTURLImageCache.m
//  MTURLImageCache
//
//  Created by Neon on 04/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "MTURLImageCache.h"
#import "AppDirectory.h"
#import "CryptoHash.h"
#import "ImageDecoder.h"
#import "Bolts.h"

@interface MTURLImageCache ()

@property (nonatomic, strong) NSURLSession *urlSession;

@end

@implementation MTURLImageCache

//-------------------------------------------------------------------------------------------------------------

#pragma mark - Property

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

//-------------------------------------------------------------------------------------------------------------

#pragma mark - Fuction

-(void)getImageFromURL:(NSString *)urlString withCachePolicy:(MTURLImageCachePolicies)cachePolicy completionHandler:(MTImageCacheResponse)completionHandler {
    
    NSDate *start = [NSDate date];
    
    [[[[[self isValidURLString:urlString] continueWithSuccessBlock:^id(BFTask *task) {
     
        return [self getImagePath:urlString];
        
    }] continueWithSuccessBlock:^id(BFTask *task) {
        
        NSString *filePath = (NSString*)task.result;
        BOOL isImageExpired = YES;
        
        NSError *error;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            
            UIImage *image =  [ImageDecoder decompressedImage:[UIImage imageWithContentsOfFile:filePath]];
            
            if (image) {
            
                completionHandler(YES,image,[self elapsedTimeSinceDate:start],nil);
                isImageExpired = [self isImageExpired:filePath];
            }
            else [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        }
        
        if (isImageExpired == YES) return [self fetchImage:@{@"url":urlString,@"filePath":filePath}];
        else                       return nil;
        
    }] continueWithSuccessBlock:^id(BFTask *task) {
        
        UIImage *image = task.result;
        completionHandler(YES,image,[self elapsedTimeSinceDate:start],nil);
        return nil;
        
    }] continueWithBlock:^id(BFTask *task) {
        
        if (task.error) {
        
            NSString *errorMessage = task.error.domain;
            completionHandler (NO,nil,0,errorMessage);
        }
        return nil;
    }];
}

//-------------------------------------------------------------------------------------------------------------

#pragma mark - SubTasks

-(BFTask*)isValidURLString:(NSString*)urlString {

    NSURLComponents *urlComponent = [NSURLComponents componentsWithString:urlString];
    
    if (urlString && urlString.length > 0 && urlComponent) {
        
        return [BFTask taskWithResult:urlString];
    }
    else return [BFTask taskWithError:[NSError errorWithDomain:@"Missing url parameter" code:1 userInfo:nil]];
}

-(BFTask*)getImagePath:(NSString*)urlString {
    
    NSString *filePath = [AppDirectory applicationCachePath];
    [filePath stringByAppendingPathComponent:self.cacheFolderName];
    [filePath stringByAppendingPathComponent:[CryptoHash md5:urlString]];
    return [BFTask taskWithResult:filePath];
}

-(BFTask*)fetchImage:(NSDictionary*)imageInfo {

    if (imageInfo) {
        
        NSString *urlString = imageInfo[@"url"];
        NSString *filePath = imageInfo[@"filePath"];
        
        if (!urlString || !filePath) return [BFTask taskWithError:[NSError errorWithDomain:@"No image info" code:2 userInfo:nil]];
        
        NSString *folderPath = [[AppDirectory applicationCachePath] stringByAppendingPathComponent:self.cacheFolderName];
        BOOL isFolderExist = [self createFolderIfNotExist:folderPath];
        
        if (!isFolderExist) return [BFTask taskWithError:[NSError errorWithDomain:@"Create folder failed" code:3 userInfo:nil]];
        else {
            
            BFTaskCompletionSource *downloadTask = [BFTaskCompletionSource taskCompletionSource];
            
            [[[self urlSession] downloadTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
               
                if (error || [MTURLImageCache isValidImage:response] == NO) {
                    
                    [downloadTask setError:[NSError errorWithDomain:@"File download failed" code:4 userInfo:nil]];
                }
                
                NSFileManager *fileManager = [NSFileManager defaultManager];
                [fileManager removeItemAtPath:filePath error:NULL];
                BOOL success = [fileManager copyItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:&error];
                
                if (error || success == NO) {
                    
                    [downloadTask setError:[NSError errorWithDomain:@"File copy failed" code:5 userInfo:nil]];
                }
                
                if (!error && success) {
                    
                    UIImage *image = [ImageDecoder decompressedImage:[UIImage imageWithContentsOfFile:filePath]];
                    if (image) [downloadTask setResult:image];
                    else {
                    
                        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
                        [downloadTask setError:[NSError errorWithDomain:@"File is not image" code:6 userInfo:nil]];
                    }
                }
                
            }] resume];
            
            return downloadTask.task;
        }
    }
    else return [BFTask taskWithError:[NSError errorWithDomain:@"No image info" code:2 userInfo:nil]];
}

//-------------------------------------------------------------------------------------------------------------

#pragma mark - Utilites

-(NSTimeInterval)elapsedTimeSinceDate:(NSDate*)date {

    return [[NSDate date] timeIntervalSinceDate:date];
}

-(BOOL)createFolderIfNotExist:(NSString*)folderPath {

    BOOL yes = YES;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&yes]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return [[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&yes];
}

-(BOOL)isImageExpired:(NSString*)filePath {
    
    BOOL isImageExpired = YES;

    NSError *error;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    
    if (!error && attributes) {
        
        NSDate *date = [attributes fileModificationDate];
        NSTimeInterval fileAge = -[date timeIntervalSinceNow];
        
        if (fileAge < self.expiredMaxAgeInSeconds) isImageExpired = NO;
    }
    
    return YES;
}

+ (BOOL)isValidImage:(NSURLResponse *)response {
    
    BOOL isValidImage = NO;
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        
        NSHTTPURLResponse *httpResponse = (id)response;
        NSInteger statusCodeHundreds = httpResponse.statusCode / 100;
        
        if (statusCodeHundreds == 2 || statusCodeHundreds == 3) {
            
            NSString *jpegMIMEType = @"image/jpeg";
            NSString *pngMIMEType = @"image/png";
            
            isValidImage = ([response.MIMEType isEqualToString:jpegMIMEType] || [response.MIMEType isEqualToString:pngMIMEType]) ?  YES : NO;
        }
    }
    
    return isValidImage;
}

@end
