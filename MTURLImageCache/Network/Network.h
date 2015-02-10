//
//  Network.h
//  MinButik
//
//  Created by Neon on 16/11/14.
//  Copyright (c) 2014 MineTilbud. All rights reserved.
//

@import Foundation;
@import UIKit;
@import MobileCoreServices;

typedef void (^DataURL) (BOOL success, NSURL *dataURL);

#define DataTypeKey     @"DataType" // string, json, image
#define DataNameKey     @"Name"
#define DataStringKey   @"String"
#define DataJSONKey     @"JSON"
#define DataFileNameKey @"FileName"
#define DataImageKey    @"Image"


@interface Network : NSObject

@property (nonatomic, strong) NSURLSession *defaultSession;

+(id)sharedNetwork;

+(BOOL)isValidJSONResponse:(NSURLResponse *)response;
+(BOOL)isValidImageResponse:(NSURLResponse*)response;
+(BOOL)isValidUploadResponse:(NSURLResponse*)response;
+(BOOL)isValidResponse:(NSURLResponse*)response;

+(NSDate*)getCacheExpireDate:(NSURLResponse*)response;

-(void)urlForData:(NSString*)dataDescription completionHandler:(DataURL)block;

+(NSMutableURLRequest*)createMultipartFormRequestWithURL:(NSURL*)url andData:(NSArray*)dataDictArray logging:(BOOL)debugSwitch;

+(NSString *)mimeTypeForPath:(NSString *)path;

@end
