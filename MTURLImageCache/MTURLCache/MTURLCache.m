//
//  MTURLCache.m
//  MTURLCache
//
//  Created by Neon on 04/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

@import ImageIO;
#import "MTURLCache.h"
#import "AppDirectory.h"
#import "CryptoHash.h"
#import "ImageDecoder.h"

@interface MTURLCache ()

@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSString *cacheFolderPath;

@end

@implementation MTURLCache

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

+ (id)sharedMTURLCache {
    
    static MTURLCache *urlCache = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        urlCache = [[MTURLCache alloc] initWithName:nil];
        urlCache.cacheObjectType = CacheObjectTypeUnknown;
    });
    
    return urlCache;
}

+ (id)sharedMTURLImageCache {
    
    static MTURLCache *urlImageCache = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        urlImageCache = [[MTURLCache alloc] initWithName:@"Image"];
        urlImageCache.cacheObjectType = CacheObjectTypeImage;
    });
    
    return urlImageCache;
}

+ (id)sharedMTURLJSONCache {
    
    static MTURLCache *urlJSONCache = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        urlJSONCache = [[MTURLCache alloc] initWithName:@"JSON"];
        urlJSONCache.cacheObjectType = CacheObjectTypeJSON;
        urlJSONCache.expiredMaxAgeInSeconds = 60*30;
    });
    
    return urlJSONCache;
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

-(URLCacheCancellationToken*)getObjectFromURL:(NSString *)urlString completionHandler:(MTCacheResponse)completionHandler {
    
    if (!completionHandler) return nil;
    
    NSDate *start = [NSDate date];
    BOOL anyError = NO;

    //===============================
    // Step 1 - Check URL String
    
    anyError = ![self isValidURLString:urlString];
    
    if (anyError) completionHandler(NO,nil,[MTURLCache elapsedTimeSinceDate:start],@"Wrong url parameter");
    
    //===============================
    // Step 2 - Return cache object
    
    BOOL isObjectExpired = YES;
    BOOL isCacheObjectUsed = NO;
    NSString *filePath = nil;
    
    if (!anyError) {
        
        filePath = [self getObjectPath:urlString];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            
            isObjectExpired = [self isObjectExpired:filePath];
            isCacheObjectUsed = YES;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                
                id object = [self getObjectInFilePath:filePath];
                if (object) {
                    NSString *infoString = [NSString stringWithFormat:@"Cached %@",[self objectTypeString:object]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(YES,object,[MTURLCache elapsedTimeSinceDate:start],infoString);
                    });
                }
            });
        }
    }
    
    //===============================
    // Step 3 - Fetch new object
    
    URLCacheCancellationToken *cancellationToken = [URLCacheCancellationToken new];
    
    if (!anyError && (!isCacheObjectUsed || isObjectExpired)) {
        
        NSDictionary *objectInfo = @{@"url":urlString,@"filePath":filePath,@"isCacheObjectUsed":@(isCacheObjectUsed)};
        
        NSURLSessionDownloadTask *objectDownloadTask = [self fetchObject:objectInfo cancellationToken:cancellationToken completion:^(BOOL success, id cacheObject, NSTimeInterval fetchTime, NSString *infoMessage) {
            
            completionHandler(success,cacheObject,[MTURLCache elapsedTimeSinceDate:start],infoMessage);
        }];
        
        cancellationToken.downloadTask = objectDownloadTask;
    }
    
    return cancellationToken;
}

-(id)getObjectFromURL:(NSString*)urlString {
    
    id object = nil;
    
    //===============================
    // Step 1 - Check URL String
    
    BOOL isValidString = [self isValidURLString:urlString];
    if (!isValidString) return nil;
    
    //===============================
    // Step 2 - Return cache object
    
    NSString *filePath = [self getObjectPath:urlString];
    BOOL isObjectExpired = YES;
    BOOL isCacheObjectUsed = NO;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        
        id object = [self getObjectInFilePath:filePath];

        if (object) {
            isObjectExpired = [self isObjectExpired:filePath];
            isCacheObjectUsed = YES;
        }
    }
    
    //===============================
    // Step 3 - Fetch new object
    
    if (!isCacheObjectUsed || isObjectExpired) {
        
        NSDictionary *objectInfo = @{@"url":urlString,@"filePath":filePath,@"isCacheObjectUsed":@(isCacheObjectUsed)};
        [self fetchObject:objectInfo cancellationToken:nil completion:NULL];
    }
    
    return object;
}

-(void)prefetchObjectFromURL:(NSString*)urlString {
    
    //===============================
    // Step 1 - Check URL String
    
    BOOL isValidString = [self isValidURLString:urlString];
    
    //===============================
    // Step 2 - Check cache object stat
    
    if (isValidString) {
        
        NSString *filePath = [self getObjectPath:urlString];
        BOOL isObjectExpired = YES;
        BOOL isCacheObjectExist = NO;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            isObjectExpired = [self isObjectExpired:filePath];
            isCacheObjectExist = YES;
        }
        
        //===============================
        // Step 3 - Fetch new image
        
        if (!isCacheObjectExist || isObjectExpired) {
            
            NSDictionary *objectInfo = @{@"url":urlString,@"filePath":filePath,@"isCacheObjectUsed":@(isCacheObjectExist)};
            [self fetchObject:objectInfo cancellationToken:nil completion:NULL];
        }
    }
}

-(CGSize)getDiskImageSizeWithoutLoadingIntoMemory:(NSString*)urlString {
    
    CGSize imageSize = CGSizeZero;
    if ([self isValidURLString:urlString]) imageSize = [MTURLCache diskImageSize:[self getObjectPath:urlString]];
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

-(NSString*)getObjectPath:(NSString*)urlString {
    
    NSString *filePath = [self.cacheFolderPath stringByAppendingPathComponent:[CryptoHash md5:urlString]];
    return filePath;
}

-(id)getObjectInFilePath:(NSString*)filePath  {
    
    id object = nil;
    
    if (self.cacheObjectType == CacheObjectTypeImage)       object = [ImageDecoder decompressedImage:[UIImage imageWithContentsOfFile:filePath]];
    else if (self.cacheObjectType == CacheObjectTypeJSON)   object = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    else                                                    object = [NSData dataWithContentsOfFile:filePath];
    
    if (!object) [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL]; // Object is not valid
    return object;
}

-(NSURLSessionDownloadTask*)fetchObject:(NSDictionary*)objectInfo cancellationToken:(URLCacheCancellationToken*)cancellationToken completion:(MTCacheResponse)completionHandler {
    
    if (!completionHandler) return nil;
    
    NSDate *start = [NSDate date];
    
    //===============================
    
    if (cancellationToken.isCancelled) return nil;
    
    if (!objectInfo) {
        completionHandler(NO,nil,[MTURLCache elapsedTimeSinceDate:start],@"No object info");
        return nil;
    }
    
    //===============================
    
    if (cancellationToken.isCancelled) return nil;
    
    BOOL isCacheObjectUsed = NO;
    NSString *urlString = nil;
    NSString *filePath = nil;
    
    urlString = objectInfo[@"url"];
    filePath = objectInfo[@"filePath"];
    if (objectInfo[@"isCacheObjectUsed"]) {
        isCacheObjectUsed = [objectInfo[@"isCacheObjectUsed"] boolValue];
    }
    
    if (!urlString || !filePath) {
        if (!isCacheObjectUsed) completionHandler(NO,nil,[MTURLCache elapsedTimeSinceDate:start],@"Not valid object info");
        return nil;
    }
    
    //===============================
    
    if (cancellationToken.isCancelled) return nil;
    
    BOOL isFolderExist = [self createFolderIfNotExist:self.cacheFolderPath];
    
    if (isFolderExist == NO) {
        if (!isCacheObjectUsed) completionHandler(NO,nil,[MTURLCache elapsedTimeSinceDate:start],@"Create folder failed");
        return  nil;
    }
    
    //===============================
    
    if (cancellationToken.isCancelled) return nil;
    
    NSURLSessionDownloadTask *objectDownloadTask = [[self urlSession] downloadTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        
        //===============================
        
        if (cancellationToken.isCancelled) return;
        
        if (error || [self isValidResponse:response] == NO) {
            
            if (!isCacheObjectUsed) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(NO,nil,[MTURLCache elapsedTimeSinceDate:start],@"File download failed");
                });
            }
            return;
        }
        
        //===============================
        
        if (cancellationToken.isCancelled) return;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:filePath error:NULL];
        BOOL copyDownloadedObjectSuccess = [fileManager copyItemAtURL:location toURL:[NSURL fileURLWithPath:filePath] error:&error];
        
        if (error || copyDownloadedObjectSuccess == NO) {
            
            if (!isCacheObjectUsed) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(NO,nil,[MTURLCache elapsedTimeSinceDate:start],@"File copy failed");
                });
            }
            return;
        }
        
        //===============================
        
        if (cancellationToken.isCancelled) return;
        
        if (self.cacheObjectType == CacheObjectTypeJSON) {
            
            BOOL isJSONSerializationSuccess = NO;
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            id jsonObject = nil;
            
            if (data) {
                [fileManager removeItemAtPath:filePath error:NULL];
                jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (jsonObject) isJSONSerializationSuccess = [NSKeyedArchiver archiveRootObject:jsonObject toFile:filePath];
            }
            
            if (isJSONSerializationSuccess == NO) {
                
                if (!isCacheObjectUsed) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(NO,nil,[MTURLCache elapsedTimeSinceDate:start],@"Deserilize json or save NSObject to disk failed");
                    });
                }
                return;
            }
            else {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    completionHandler(YES,jsonObject,[MTURLCache elapsedTimeSinceDate:start],@"Fresh JSON");
                });
            }
        }
        else if (self.cacheObjectType == CacheObjectTypeImage) {
            
            //===============================
            
            UIImage *image  = [ImageDecoder decompressedImage:[UIImage imageWithContentsOfFile:filePath]];
            
            if (!image) {
                
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
                
                if (!isCacheObjectUsed) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(NO,nil,[MTURLCache elapsedTimeSinceDate:start],@"File is not image");
                    });
                }
                return;
            }
            
            //===============================
            
            if (cancellationToken.isCancelled) return;
            
            if (image) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    completionHandler(YES,image,[MTURLCache elapsedTimeSinceDate:start],@"Fresh image");
                });
            }
        }
        else {
            
            //===============================
            
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            
            if (data) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    completionHandler(YES,data,[MTURLCache elapsedTimeSinceDate:start],@"Fresh Data");
                });
            }
        }
    }];
    
    [objectDownloadTask resume];
    
    return objectDownloadTask;
}

//-------------------------------------------------------------------------------------------------------------

#pragma mark - URL response validation

+(BOOL)isValidDataResponse:(NSURLResponse*)response {
    
    BOOL isValidDataResponse = NO;
    
    if (response && [response isKindOfClass:[NSHTTPURLResponse class]]) {
        
        NSHTTPURLResponse *httpResponse = (id)response;
        NSInteger statusCodeHundreds = floorf(httpResponse.statusCode / 100);
        
        if (statusCodeHundreds == 2 || statusCodeHundreds == 3) isValidDataResponse = YES;
    }
    
    return isValidDataResponse;
}

+(BOOL)isValidResponse:(NSURLResponse *)response mimeTypes:(NSArray*)mimeTypes {
    
    BOOL isValidResponse = NO;
    
    if ([self isValidDataResponse:response] == YES && mimeTypes && mimeTypes.count > 0) {
        
        isValidResponse = ([mimeTypes containsObject:response.MIMEType.lowercaseString]) ? YES : NO;
    }
    
    return isValidResponse;
}

+(BOOL)isValidJSONResponse:(NSURLResponse *)response {
    
    return [MTURLCache isValidResponse:response mimeTypes:@[@"application/json",@"application/hal+json",@"application/javascript"]];
}

+(BOOL)isValidImageResponse:(NSURLResponse*)response {
    
    return [MTURLCache isValidResponse:response mimeTypes:@[@"image/jpeg",@"image/png"]];
}


-(BOOL)isValidResponse:(NSURLResponse *)response {
    
    BOOL isValidResponse = NO;
    
    if (self.cacheObjectType == CacheObjectTypeImage) {
        
        isValidResponse = [MTURLCache isValidImageResponse:response];
    }
    else if (self.cacheObjectType == CacheObjectTypeJSON) {
        
        isValidResponse = [MTURLCache isValidJSONResponse:response];
    }
    else isValidResponse = [MTURLCache isValidDataResponse:response];
    
    return isValidResponse;
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

-(BOOL)isObjectExpired:(NSString*)filePath {
    
    BOOL isObjectExpired = YES;

    NSError *error;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    
    if (!error && attributes) {
        
        NSDate *date = [attributes fileModificationDate];
        NSTimeInterval fileAge = -[date timeIntervalSinceNow];
        
        if (fileAge < self.expiredMaxAgeInSeconds) isObjectExpired = NO;
    }
     
    return isObjectExpired;
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

-(NSString*)objectTypeString:(id)object {
    
    NSString *objectType = nil;
    
    if (!object) {
        objectType = @"NULL";
    }
    else if ([object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSDictionary class]]) {
        objectType = @"json";
    }
    else if ([object isKindOfClass:[UIImage class]]) {
        objectType = @"image";
    }
    else objectType = @"data";
    
    return objectType;
}

//-------------------------------------------------------------------------------------------------------------

#pragma mark - Disk clean

-(void)removeCachedFileWithURL:(NSString*)urlString {
    
    if (urlString && urlString.length > 0) {
        
        NSString *filePath = [self getObjectPath:urlString];
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

+(void)cleanDiskWithCompletionAsync:(MTCacheCleanStat)completionBlock {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        [MTURLCache cleanDiskWithCompletion:^(NSDictionary *cleanStatInfo) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
            
                completionBlock(cleanStatInfo);
            });
        }];
    });
}

+(void)cleanDiskWithCompletion:(MTCacheCleanStat)completionBlock {
    
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
                                    @"BeforeCacheSize":[MTURLCache byteToString:beforeCacheSize],
                                    @"CurrentCacheSize":[MTURLCache byteToString:currentCacheSize],
                                    @"DeletedFilesSiz":[MTURLCache byteToString:(beforeCacheSize-currentCacheSize)],
                                    @"CleanElapsedTime":@([MTURLCache elapsedTimeSinceDate:startDate])};
    
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
