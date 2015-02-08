//
//  AppDirectory.h
//  Forum
//
//  Created by Min Wu on 10/02/14.
//  Copyright (c) 2014 FK Distribution. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppDirectory : NSObject

+ (NSURL *)applicationDocumentsDirectory;

+ (NSString *)applicationDocumentsPath;
+ (NSString *)applicationLibraryPath;
+ (NSString *)applicationCachePath;
+ (NSString *)applicationTempPath;

@end