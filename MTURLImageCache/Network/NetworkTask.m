//
//  NetworkTask.m
//  MTURLImageCache
//
//  Created by Neon on 10/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

#import "NetworkTask.h"
#import "Network.h"
#import "MTURLCache.h"
#import "JSONHalFormatter.h"

#define TestMode @"cache"

@implementation NetworkTask

+(void)getDataWithBaseURL:(NSString*)baseURL path:(NSString*)path completion:(void (^)(BOOL success, NSArray *data))completionHandler {

    if (baseURL && path) {
        
        NSString *urlString = [baseURL stringByAppendingPathComponent:path];
        NSURL *url = [NSURL URLWithString:urlString];
        
        if ([TestMode isEqualToString:@"cache"]) {
            
            [[MTURLCache sharedMTURLJSONCache] getObjectFromURL:urlString completionHandler:^(BOOL success, id object, NSTimeInterval fetchTime, NSString *infoMessage) {
                
                if (success) {
                    
                    NSArray *dataArray = [JSONHalFormatter processJSONHalFormat:object withBaseURL:[NSURL URLWithString:baseURL]];
                    if (dataArray.count > 0) completionHandler(YES,dataArray);
                    else                     completionHandler(NO,nil);
                }
            }];
        }
        else {
            
            [[[[Network sharedNetwork] defaultSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (!error && [Network isValidResponse:response]) {
                        
                        NSError *err;
                        id dataObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
                        NSArray *dataArray = [JSONHalFormatter processJSONHalFormat:dataObject withBaseURL:[NSURL URLWithString:baseURL]];
                        
                        if (dataArray.count > 0) completionHandler(YES,dataArray);
                        else                     completionHandler(NO,nil);
                    }
                    else completionHandler(NO,nil);
                });
            }] resume];
        }
    }
}

@end
