//
//  JSONHalFormatter.m
//  MinButik
//
//  Created by Neon on 16/11/14.
//  Copyright (c) 2014 MineTilbud. All rights reserved.
//

#import "JSONHalFormatter.h"

@implementation JSONHalFormatter

+(NSString*)jsonHalLinkToURLString:(id)linkObject baseURL:(NSURL*)baseURL {
    
    NSString *urlString = nil;
    
    if ([linkObject isKindOfClass:[NSDictionary class]] && [(NSDictionary*)linkObject objectForKey:@"href"]) {
        
        NSString *localURLPath = [(NSDictionary*)linkObject objectForKey:@"href"];
        NSURLComponents *urlComponent = [NSURLComponents componentsWithURL:baseURL resolvingAgainstBaseURL:YES];
        urlComponent.path = [urlComponent.path stringByAppendingString:localURLPath];
        urlString = urlComponent.URL.absoluteString;
    }
    
    return urlString;
}

+(NSArray*)processJSONHalFormat:(id)dataObject withBaseURL:(NSURL*)baseURL {
    
    NSArray *result;
    
    if (dataObject) {
        
        if ([dataObject isKindOfClass:[NSDictionary class]] && [(NSDictionary*)dataObject count] > 0 ) {
            
            NSDictionary *dataDict = [JSONHalFormatter processJSONHalDataWithDictionary:dataObject withBaseURL:baseURL];
            result = @[dataDict];
        }
        else if ([dataObject isKindOfClass:[NSArray class]] && [(NSArray*)dataObject count] > 0) {
            
            NSMutableArray *resultMutableArray = [NSMutableArray new];
            
            [(NSArray*)dataObject enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                if ([obj isKindOfClass:[NSDictionary class]]) [resultMutableArray addObject:[JSONHalFormatter processJSONHalDataWithDictionary:obj withBaseURL:baseURL]];
            }];
            
            result = [NSArray arrayWithArray:resultMutableArray];
        }
    }
    
    return result;
}

+(NSDictionary *)processJSONHalDataWithDictionary:(id)dataObject withBaseURL:(NSURL*)baseURL {
    
    NSMutableDictionary *resultMutableDict = [NSMutableDictionary new];
    
    [(NSDictionary*)dataObject enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        
        if ([key isEqualToString:@"_links"] && [obj isKindOfClass:[NSDictionary class]]) {
            
            NSMutableDictionary *linksMutableDict = [NSMutableDictionary new];
            
            [(NSDictionary*)obj enumerateKeysAndObjectsUsingBlock:^(NSString *keyOfLink, id linkData, BOOL *stop) {
                
                NSString *urlString = [JSONHalFormatter jsonHalLinkToURLString:linkData baseURL:baseURL];
                if (urlString) linksMutableDict[keyOfLink] = urlString;
            }];
            
            if (linksMutableDict.count > 0) resultMutableDict[key] = [NSDictionary dictionaryWithDictionary:linksMutableDict];
        }
        else if ([obj isKindOfClass:[NSDictionary class]] && [(NSDictionary*)obj objectForKey:@"href"]) {
            
            NSString *urlString = [JSONHalFormatter jsonHalLinkToURLString:obj baseURL:baseURL];
            if (urlString) resultMutableDict[key] = urlString;
        }
        else resultMutableDict[key] = obj;
    }];
    
    return [NSDictionary dictionaryWithDictionary:resultMutableDict];
}

@end
