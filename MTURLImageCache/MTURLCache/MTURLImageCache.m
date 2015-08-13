//
//  MTURLImageCache.m
//  MTURLImageCache
//
//  Created by Neon on 04/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

@import ImageIO;
#import "MTURLImageCache.h"
#import "AppDirectory.h"
#import "CryptoHash.h"
#import "ImageDecoder.h"

@interface MTURLImageCache ()

@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSString *cacheFolderPath;

@end

@implementation MTURLImageCache

//-------------------------------------------------------------------------------------------------------------

#pragma mark - Property

-(instancetype)initWithName:(NSString*)name; {
    
    self = [super init];
    
    if (self) {
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.urlSession                          = [NSURLSession sessionWithConfiguration:configuration];
        self.expiredMaxAgeInSeconds              = defaultExpiredMaxAgeInSeconds;
        if (name.length == 0) {
            name = @"default";
        }
        self.cacheFolderPath = [NSString stringWithFormat:@"%@/%@/%@",[AppDirectory applicationCachePath],defulatCacheRootFolderName,name];
    }
    
    return self;
}

+ (id)sharedMTURLImageCache {
    
    static MTURLImageCache *urlImageCache = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        urlImageCache = [[MTURLImageCache alloc] initWithName:nil];
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

#pragma mark - Function

-(URLCacheCancellationToken*)getImageFromURL:(NSString *)urlString completionHandler:(MTImageCacheResponse)completionHandler {
    
    NSDate *start = [NSDate date];
    BOOL anyError = NO;

    //===============================
    // Step 1 - Check URL String
    
    anyError = ![self isValidURLString:urlString];
    
    if (anyError) completionHandler(NO,nil,[MTURLImageCache elapsedTimeSinceDate:start],@"Wrong url parameter");
    
    //===============================
    // Step 2 - Return cache image
    
    BOOL isImageExpired = YES;
    BOOL isCacheImageUsed = NO;
    NSString *filePath = nil;
    
    if (!anyError) {
        
        filePath = [self getImagePath:urlString];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            
            isImageExpired = [self isImageExpired:filePath];
            isCacheImageUsed = YES;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSError *error;
                UIImage *image = [ImageDecoder decompressedImage:[UIImage imageWithContentsOfFile:filePath]];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(YES,image,[MTURLImageCache elapsedTimeSinceDate:start],@"Cached image");
                    });
                }
                else [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            });
        }
    }
    
    //===============================
    // Step 3 - Fetch new image
    
    URLCacheCancellationToken *cancellationToken = [URLCacheCancellationToken new];
    
    if (!anyError && (!isCacheImageUsed || isImageExpired)) {
        
        NSDictionary *imageInfo = @{@"url":urlString,@"filePath":filePath,@"isCacheImageUsed":@(isCacheImageUsed)};
        
        NSURLSessionDownloadTask *imageDownloadTask = [self fetchImage:imageInfo cancellationToken:cancellationToken completion:^(BOOL success, UIImage *image, NSTimeInterval fetchTime, NSString *infoMessage) {
            
            completionHandler(success,image,[MTURLImageCache elapsedTimeSinceDate:start],infoMessage);
        }];
        
        cancellationToken.downloadTask = imageDownloadTask;
    }
    
    return cancellationToken;
}

-(UIImage*)getImageFromURL:(NSString*)urlString {
    
    UIImage *image = nil;
    
    //===============================
    // Step 1 - Check URL String
    
    BOOL isValidString = [self isValidURLString:urlString];
    if (!isValidString) return nil;
    
    //===============================
    // Step 2 - Return cache image
    
    NSString *filePath = [self getImagePath:urlString];
    BOOL isImageExpired = YES;
    BOOL isCacheImageUsed = NO;
    
    NSError *error;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        
        image = [ImageDecoder decompressedImage:[UIImage imageWithContentsOfFile:filePath]];
        
        if (image) {
            
            isImageExpired = [self isImageExpired:filePath];
            isCacheImageUsed = YES;
        }
        else [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    }
    
    //===============================
    // Step 3 - Fetch new image
    
    if (!isCacheImageUsed || isImageExpired) {
        
        NSDictionary *imageInfo = @{@"url":urlString,@"filePath":filePath,@"isCacheImageUsed":@(isCacheImageUsed)};
        [self fetchImage:imageInfo cancellationToken:nil completion:NULL];
    }
    
    return image;
}

-(void)prefetchImageFromURL:(NSString*)urlString {
    
    //===============================
    // Step 1 - Check URL String
    
    BOOL isValidString = [self isValidURLString:urlString];
    
    //===============================
    // Step 2 - Check cache image stat
    
    if (isValidString) {
        
        NSString *filePath = [self getImagePath:urlString];
        BOOL isImageExpired = YES;
        BOOL isCacheImageExist = NO;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            isImageExpired = [self isImageExpired:filePath];
            isCacheImageExist = YES;
        }
        
        //===============================
        // Step 3 - Fetch new image
        
        if (!isCacheImageExist || isImageExpired) {
            
            NSDictionary *imageInfo = @{@"url":urlString,@"filePath":filePath,@"isCacheImageUsed":@(isCacheImageExist)};
            [self fetchImage:imageInfo cancellationToken:nil completion:NULL];
        }
    }
}

-(CGSize)getDiskImageSizeWithoutLoadingIntoMemory:(NSString*)urlString {
    
    CGSize imageSize = CGSizeZero;
    if ([self isValidURLString:urlString]) imageSize = [MTURLImageCache diskImageSize:[self getImagePath:urlString]];
    return imageSize;
}

//-------------------------------------------------------------------------------------------------------------

#pragma mark - SubTasks

-(BOOL)isValidURLString:(NSString*)urlString {

    if (urlString && urlString.length > 0) {
        
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURLComponents *urlComponent = [NSURLComponents componentsWithString:urlString];
        if (urlComponent) return YES;
    }
    
    return NO;
}

-(NSString*)getImagePath:(NSString*)urlString {
    
    NSString *filePath = [self.cacheFolderPath stringByAppendingPathComponent:[CryptoHash md5:urlString]];
    return filePath;
}

-(NSURLSessionDownloadTask*)fetchImage:(NSDictionary*)imageInfo cancellationToken:(URLCacheCancellationToken*)cancellationToken completion:(MTImageCacheResponse)completionHandler {
    
    NSDate *start = [NSDate date];
    
    //===============================
    
    if (cancellationToken.isCancelled) return nil;
    
    if (!imageInfo) {
        if (completionHandler) completionHandler(NO,nil,[MTURLImageCache elapsedTimeSinceDate:start],@"No image info");
        return nil;
    }
    
    //===============================
    
    if (cancellationToken.isCancelled) return nil;
    
    BOOL isCacheImageUsed = NO;
    NSString *urlString = nil;
    NSString *filePath = nil;
    
    urlString = imageInfo[@"url"];
    filePath = imageInfo[@"filePath"];
    if (imageInfo[@"isCacheImageUsed"]) {
        isCacheImageUsed = [imageInfo[@"isCacheImageUsed"] boolValue];
    }
    
    if (!urlString || !filePath) {
        if (!isCacheImageUsed && completionHandler) completionHandler(NO,nil,[MTURLImageCache elapsedTimeSinceDate:start],@"Not valid image info");
        return nil;
    }
    
    //===============================
    
    if (cancellationToken.isCancelled) return nil;
    
    BOOL isFolderExist = [self createFolderIfNotExist:self.cacheFolderPath];
    
    if (isFolderExist == NO) {
        if (!isCacheImageUsed && completionHandler) completionHandler(NO,nil,[MTURLImageCache elapsedTimeSinceDate:start],@"Create folder failed");
        return  nil;
    }
    
    //===============================
    
    if (cancellationToken.isCancelled) return nil;
    
    NSURLSessionDownloadTask *imageDownloadTask = [[self urlSession] downloadTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        
        //===============================
        
        if (cancellationToken.isCancelled) return;
        
        if (error || [MTURLImageCache isValidImage:response] == NO) {
            
            if (!isCacheImageUsed && completionHandler) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(NO,nil,[MTURLImageCache elapsedTimeSinceDate:start],@"File download failed");
                });
            }
            return;
        }
        
        //===============================
        
        if (cancellationToken.isCancelled) return;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:filePath error:NULL];
        BOOL copyDownloadedImageSuccess = [fileManager copyItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:&error];
        
        if (error || copyDownloadedImageSuccess == NO) {
            
            if (!isCacheImageUsed && completionHandler) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(NO,nil,[MTURLImageCache elapsedTimeSinceDate:start],@"File copy failed");
                });
            }
            return;
        }
        
        //===============================
        
        if (cancellationToken.isCancelled) return;
        
        UIImage *image  = [ImageDecoder decompressedImage:[UIImage imageWithContentsOfFile:filePath]];
        
        if (!image) {
            
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            
            if (!isCacheImageUsed && completionHandler) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(NO,nil,[MTURLImageCache elapsedTimeSinceDate:start],@"File is not image");
                });
            }
            return;
        }
        
        //===============================
        
        if (cancellationToken.isCancelled) return;
        
        if (image && completionHandler) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                completionHandler(YES,image,[MTURLImageCache elapsedTimeSinceDate:start],@"Fresh image");
            });
        }
    }];
    
    [imageDownloadTask resume];
    
    return imageDownloadTask;
}

//-------------------------------------------------------------------------------------------------------------

#pragma mark - Utilites

+(NSTimeInterval)elapsedTimeSinceDate:(NSDate*)date {

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
     
    return isImageExpired;
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

+(NSString*)byteToString:(NSUInteger)byte {
    
    return [NSByteCountFormatter stringFromByteCount:byte countStyle:NSByteCountFormatterCountStyleFile];
}

+(CGSize)diskImageSize:(NSString*)filePath {
    
    CGSize diskImageSize = CGSizeZero;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        
        NSURL *imageFileURL = [NSURL fileURLWithPath:filePath];
        CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)imageFileURL, NULL);
        
        if (imageSource != NULL) {
            
            CGFloat width = 0.0f, height = 0.0f;
            CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
            
            if (imageProperties != NULL) {
                
                CFNumberRef widthNum  = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
                if (widthNum != NULL) CFNumberGetValue(widthNum, kCFNumberCGFloatType, &width);
                
                CFNumberRef heightNum = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
                if (heightNum != NULL) CFNumberGetValue(heightNum, kCFNumberCGFloatType, &height);
                
                CFRelease(imageProperties);
            }
            
            CFRelease(imageSource);
            
            if (width != 0 && height != 0) diskImageSize = CGSizeMake(width, height);
        }
    }
    
    return diskImageSize;
}

//-------------------------------------------------------------------------------------------------------------

#pragma mark - Disk clean

-(void)removeCachedFileWithURL:(NSString*)urlString {
    
    if (urlString && urlString.length > 0) {
        
        NSString *filePath = [self getImagePath:urlString];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
        
    }
}

-(void)emptyCacheFolder {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSString *folderPath = self.cacheFolderPath;
        [[NSFileManager defaultManager] removeItemAtPath:folderPath error:NULL];
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:NULL];
    });
}

+(void)backgroundCleanDisk {
    
    UIApplication *application = [UIApplication sharedApplication]; //Get the shared application instance
    __block UIBackgroundTaskIdentifier background_task = [application beginBackgroundTaskWithExpirationHandler: ^ {
        [application endBackgroundTask: background_task]; //Tell the system that we are done with the tasks
        background_task = UIBackgroundTaskInvalid; //Set the task to be invalid
        //System will be shutting down the app at any point in time now
    }];
    
    //Background tasks require you to use asyncrous tasks
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //Perform your tasks that your application requires
        
        [self cleanDiskWithCompletion:^(NSDictionary *cleanStatInfo) {
            
#ifdef DEBUG
            NSLog(@"%@",cleanStatInfo);
#endif
        }];
        
        [application endBackgroundTask: background_task]; //End the task so the system knows that you are done with what you need to perform
        background_task = UIBackgroundTaskInvalid; //Invalidate the background_task
    });
}

+(void)cleanDiskWithCompletionAsync:(MTImageCacheCleanStat)completionBlock {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        [MTURLImageCache cleanDiskWithCompletion:^(NSDictionary *cleanStatInfo) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
            
                completionBlock(cleanStatInfo);
            });
        }];
    });
}

+(void)cleanDiskWithCompletion:(MTImageCacheCleanStat)completionBlock {
    
    NSUInteger beforeFileCount = 0;
    NSUInteger beforeCacheSize = 0;
    __block NSUInteger fileDeletedCount = 0;
    
    NSDate *startDate = [NSDate date];
    
    NSString *cacheRootFolder = [[AppDirectory applicationCachePath] stringByAppendingPathComponent:defulatCacheRootFolderName];
    NSArray *resourceKeys     = @[NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey];
    
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL URLWithString:cacheRootFolder]
                                                                 includingPropertiesForKeys:resourceKeys
                                                                                    options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                               errorHandler:NULL];
    NSMutableDictionary *cacheFiles       = [NSMutableDictionary new];
    NSMutableArray *fileURLToDelete       = [NSMutableArray new];
    NSTimeInterval cacheContentMaxAge     = (60*60*24)*defaultMaxCachePeriodInDays;
    NSUInteger maxCacheSize               = (1024*1024)*defaultGlobalDiskCapacityMB;
    __block NSUInteger currentCacheSize   = 0;
    
    for (NSURL *fileURL in fileEnumerator) {
        
        NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];
        
        if ([resourceValues[NSURLIsDirectoryKey] boolValue] == YES) continue;
        
        NSNumber *fileAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
        
        beforeFileCount++;
        beforeCacheSize += [fileAllocatedSize unsignedIntegerValue];
        
        NSDate *fileModificationDate  = resourceValues[NSURLContentModificationDateKey];
        NSTimeInterval fileAge = -[fileModificationDate timeIntervalSinceNow];
        
        if (fileAge > cacheContentMaxAge) [fileURLToDelete addObject:fileURL];
        else {
            currentCacheSize += [fileAllocatedSize unsignedIntegerValue];
            cacheFiles[fileURL] = resourceValues;
        }
    }
    
    [fileURLToDelete enumerateObjectsUsingBlock:^(NSURL *fileURL, NSUInteger idx, BOOL *stop) {
        fileDeletedCount++;
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:NULL];
    }];
    
    if (maxCacheSize > 0 && currentCacheSize > maxCacheSize) {
        
        const NSUInteger desireCacheSize = maxCacheSize*0.5;
        
        NSArray *sortFilesByModificationDate = [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                                        usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                            return [obj1[NSURLContentModificationDateKey] compare:obj2[NSURLContentModificationDateKey]];
                                                                        }];
        
        [sortFilesByModificationDate enumerateObjectsUsingBlock:^(NSURL *fileURL, NSUInteger idx, BOOL *stop) {
            
            if ([[NSFileManager defaultManager] removeItemAtURL:fileURL error:NULL]) {
                
                fileDeletedCount++;
             
                NSDictionary *resoruceValues = cacheFiles[fileURL];
                NSNumber *fileAllocatedSize = resoruceValues[NSURLTotalFileAllocatedSizeKey];
                currentCacheSize -= [fileAllocatedSize unsignedIntegerValue];
                
                if (currentCacheSize < desireCacheSize) *stop = YES;
            }
        }];
    }
    
    NSDictionary *cleanStatDict = @{@"BeforeFilesCount":@(beforeFileCount),
                                    @"CurretFilesCount":@(beforeFileCount-fileDeletedCount),
                                    @"FilesDeletedCount":@(fileDeletedCount),
                                    @"BeforeCacheSize":[MTURLImageCache byteToString:beforeCacheSize],
                                    @"CurrentCacheSize":[MTURLImageCache byteToString:currentCacheSize],
                                    @"DeletedFilesSiz":[MTURLImageCache byteToString:(beforeCacheSize-currentCacheSize)],
                                    @"CleanElapsedTime":@([MTURLImageCache elapsedTimeSinceDate:startDate])};
    
    if (completionBlock) {
        completionBlock(cleanStatDict);
    }
}

@end

//-------------------------------------------------------------------------------------------------------------

#pragma mark - CancellationToken

@implementation URLCacheCancellationToken

-(id)init {
    
    if (self = [super init]) {
        
        self.isCancelled = NO;
    }
    return self;
}

-(void)cancel {
    
    self.isCancelled = YES;
    
    if (self.downloadTask) {
        
        [self.downloadTask cancel];
        self.downloadTask = nil;
    }
}

@end
