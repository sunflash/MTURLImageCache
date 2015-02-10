//
//  NetworkTask.m
//  MTURLImageCache
//
//  Created by Neon on 10/02/15.
//  Copyright (c) 2015 MineTilbud. All rights reserved.
//

#import "NetworkTask.h"
#import "Network.h"
#import "JSONHalFormatter.h"

@implementation NetworkTask

+(void)getDataWithBaseURL:(NSString*)baseURL path:(NSString*)path completion:(void (^)(BOOL success, NSArray *data))completionHandler {

    if (baseURL && path) {
        
        NSURL *url = [NSURL URLWithString:[baseURL stringByAppendingPathComponent:path]];
        
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

@end
