//
//  NetworkTask.h
//  MTURLImageCache
//
//  Created by Neon on 10/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

@import Foundation;

@interface NetworkTask : NSObject

+(void)getDataWithBaseURL:(NSString*)baseURL path:(NSString*)path completion:(void (^)(BOOL success, NSArray *data))completionHandler;

@end
