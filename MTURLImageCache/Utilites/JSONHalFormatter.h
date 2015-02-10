//
//  JSONHalFormatter.h
//  MinButik
//
//  Created by Neon on 16/11/14.
//  Copyright (c) 2014 MineTilbud. All rights reserved.
//

@import Foundation;

@interface JSONHalFormatter : NSObject

+(NSString*)jsonHalLinkToURLString:(id)linkObject baseURL:(NSURL*)baseURL;
+(NSArray*)processJSONHalFormat:(id)dataObject withBaseURL:(NSURL*)baseURL;

@end
