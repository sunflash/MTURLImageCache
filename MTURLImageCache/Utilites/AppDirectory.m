//
//  AppDirectory.m
//  Forum
//
//  Created by Min Wu on 10/02/14.
//  Copyright (c) 2014 FK Distribution. All rights reserved.
//

#import "AppDirectory.h"

@implementation AppDirectory

// Returns the URL to the application's Documents directory.
+ (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSString *)applicationDocumentsPath {

    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)applicationLibraryPath {

    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)applicationCachePath {
    
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)applicationTempPath {

    return NSTemporaryDirectory();
}

@end