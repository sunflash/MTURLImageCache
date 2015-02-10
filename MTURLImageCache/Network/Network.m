//
//  Network.m
//  MinButik
//
//  Created by Neon on 16/11/14.
//  Copyright (c) 2014 MineTilbud. All rights reserved.
//

#import "Network.h"
#import "NetworkParameter.h"
#import "JSONHalFormatter.h"

@interface Network ()

@property (nonatomic, strong) NSDate *cacheExpireDate;
@property (nonatomic, strong) NSDictionary *links;

@end

@implementation Network

//-------------------------------------------------------------------------------------------------------------------------------------------------------------

#pragma mark - Network

+(id)sharedNetwork {
    
    static Network *network = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        network = [self new];
        [network configureDefaultSession];
    });
    return network;
}

-(void)configureDefaultSession {

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSDictionary *httpHeaders = @{@"ocp-apim-subscription-key":BackendAccessKey,@"API-Authorization":BackendAPIKey};
    configuration.HTTPAdditionalHeaders = httpHeaders;
    self.defaultSession = [NSURLSession sessionWithConfiguration:configuration];
}

+(BOOL)isValidResponse:(NSURLResponse *)response mimeTypes:(NSArray*)mimeTypes {
    
    BOOL isValidResponse = NO;
    
    if (response && mimeTypes && [response isKindOfClass:[NSHTTPURLResponse class]] && mimeTypes.count > 0) {
        
        NSHTTPURLResponse *httpResponse = (id)response;
        NSInteger statusCodeHundreds = floorf(httpResponse.statusCode / 100);
        
        if (statusCodeHundreds == 2 || statusCodeHundreds == 3) {
        
            isValidResponse = ([mimeTypes containsObject:response.MIMEType]) ? YES : NO;
        }
    }
    
    return isValidResponse;
}

+(BOOL)isValidJSONResponse:(NSURLResponse *)response {
    
    return [Network isValidResponse:response mimeTypes:@[@"application/json",@"application/hal+json"]];
}

+(BOOL)isValidImageResponse:(NSURLResponse*)response {

    return [Network isValidResponse:response mimeTypes:@[@"image/jpeg",@"image/png"]];
}

+(BOOL)isValidUploadResponse:(NSURLResponse*)response {

    return [Network isValidResponse:response];
}

+(BOOL)isValidResponse:(NSURLResponse*)response {
    
    BOOL isValidResponse = NO;
    
    if (response && [response isKindOfClass:[NSHTTPURLResponse class]]) {
        
        NSHTTPURLResponse *httpResponse = (id)response;
        NSInteger statusCodeHundreds = floorf(httpResponse.statusCode / 100);
        
        if (statusCodeHundreds == 2 || statusCodeHundreds == 3) isValidResponse = YES;
    }
    
    return isValidResponse;
}

+(NSDate*)getCacheExpireDate:(NSURLResponse*)response {
    
    NSDate *expireDate = nil;
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        
        NSHTTPURLResponse *httpResponse = (id)response;
        NSDictionary *responseHeaderFields = httpResponse.allHeaderFields;
        
        id cacheControl = [responseHeaderFields objectForKey:@"Cache-Control"];
        
        if (cacheControl && [cacheControl isKindOfClass:[NSString class]]) {
            
            __block NSUInteger cacheIntervalFromNow = 0;
            
            NSString *cacheControlHeader = (NSString*)cacheControl;
            NSArray *controlHeaderValueArray = [cacheControlHeader componentsSeparatedByString:@";"];
            
            [controlHeaderValueArray enumerateObjectsUsingBlock:^(NSString *values, NSUInteger idx, BOOL *stop) {
                
                if ([values rangeOfString:@"max-age:"].location != NSNotFound) cacheIntervalFromNow = [[values componentsSeparatedByString:@":"][1] integerValue];
                else                                                           cacheIntervalFromNow = 2700;
                    
            }];
            
            if (cacheIntervalFromNow != 0) expireDate = [[NSDate date] dateByAddingTimeInterval:cacheIntervalFromNow];
        }
    }

    return expireDate;
}

-(void)urlForData:(NSString*)dataDescription completionHandler:(DataURL)block {
    
    if (self.links && self.cacheExpireDate && [self.cacheExpireDate timeIntervalSinceNow] > 0) { // Get data from cache
    
        NSString *urlString = self.links[dataDescription];
        
        if (urlString) block(YES,[NSURL URLWithString:urlString]); // Link is fund in cache
        else           block(NO,nil);                              // Link not exist in cache
        
    }
    else { // Get fresh data from server
    
        NSURL *baseURL = [NSURL URLWithString:BackendURL];
        
        NSURLSessionDataTask *getLinksTask = [self.defaultSession dataTaskWithURL:baseURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            if (!error && [Network isValidJSONResponse:response] == YES && data) {
                
                NSError *err;
                id dataObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
                NSArray *result = [JSONHalFormatter processJSONHalFormat:dataObject withBaseURL:baseURL];
                
                if (result.count > 0) {
                    
                    id links = [[result firstObject] objectForKey:@"_links"];
                    
                    if (links && [links isKindOfClass:[NSDictionary class]]) {
                        
                        self.links = links;
                        self.cacheExpireDate = [Network getCacheExpireDate:response];
                        
                        NSString *urlString = self.links[dataDescription];
                        
                        if (urlString) block(YES,[NSURL URLWithString:urlString]); // Link is fund
                        else           block(NO,nil);                              // Link not exist
                        
                    }
                    else block(NO, nil); // No link data
                }
                else block(NO,nil); // empty JSON data
            }
            else block(NO,nil); // error, not valid data
        }];
        
        [getLinksTask resume];
    }
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------------

#pragma mark - multipart post

+(NSMutableURLRequest*)createMultipartFormRequestWithURL:(NSURL*)url andData:(NSArray*)dataDictArray logging:(BOOL)debugSwitch {
    
    if (url && dataDictArray && dataDictArray.count > 0) {
        
        NSString *newLine = @"\r\n";
        NSMutableString *debugString = [NSMutableString new];
        
        // Request
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        
        NSString *boundary = [Network boundary];
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        NSMutableData *body = [NSMutableData new];
        
        [dataDictArray enumerateObjectsUsingBlock:^(NSDictionary *dataInfo, NSUInteger idx, BOOL *stop) {
            
            NSString *dataType = dataInfo[DataTypeKey];
            
            if (dataType && dataType.length > 0 && dataInfo[DataNameKey]) {
                
                // boundary
                
                NSMutableString *boundaryLine = [NSMutableString new];
                NSString *boundaryString = [NSString stringWithFormat:@"--%@",boundary];
                [boundaryLine appendString:boundaryString];
                [boundaryLine appendString:newLine];
                [body appendData:[boundaryLine dataUsingEncoding:NSUTF8StringEncoding]];
                if (debugSwitch == YES) [debugString appendString:boundaryLine];
                
                // Compose Content-Disposition
                
                NSString *name = dataInfo[DataNameKey];
                NSString *fileName = @"";
                if ([dataType isEqualToString:@"image"] && dataInfo[DataFileNameKey]) {
                
                    fileName = [NSString stringWithFormat:@"; filename=\"%@\"",dataInfo[DataFileNameKey]];
                }
                NSString *ContentDisposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"%@",name,fileName];
                
                
                if ([dataType isEqualToString:@"string"]) {
                    
                    NSString *string = dataInfo[DataStringKey];
                    
                    if (string && string.length > 0) {
                        
                        NSMutableString *stringPart = [NSMutableString new];
                        
                        [stringPart appendString:ContentDisposition];
                        [stringPart appendString:newLine];
                        [stringPart appendString:@"Content-Type: text/plain; charset=UTF-8"];
                        [stringPart appendString:newLine];
                        [stringPart appendString:[NSString stringWithFormat:@"Content-Length: %lu",(unsigned long)string.length]];
                        [stringPart appendString:newLine];
                        [stringPart appendString:@"Content-Transfer-Encoding: binary"];
                        [stringPart appendString:newLine];
                        [stringPart appendString:newLine];
                       
                        [stringPart appendString:string];
                        [stringPart appendString:newLine];
                        
                        [body appendData:[stringPart dataUsingEncoding:NSUTF8StringEncoding]];
                        if (debugSwitch) [debugString appendString:stringPart];
                    }
                }
                else if ([dataType isEqualToString:@"json"]) {
                    
                    NSString *jsonString = dataInfo[DataJSONKey];
                    
                    if (jsonString) {
                        
                        NSMutableString *jsonPart = [NSMutableString new];
                        
                        [jsonPart appendString:ContentDisposition];
                        [jsonPart appendString:newLine];
                        [jsonPart appendString:@"Content-Type: application/json; charset=UTF-8"];
                        [jsonPart appendString:newLine];
                        [jsonPart appendString:[NSString stringWithFormat:@"Content-Length: %lu",(unsigned long)jsonString.length]];
                        [jsonPart appendString:newLine];
                        [jsonPart appendString:@"Content-Transfer-Encoding: binary"];
                        [jsonPart appendString:newLine];
                        [jsonPart appendString:newLine];
                        
                        [jsonPart appendString:jsonString];
                        [jsonPart appendString:newLine];
                        
                        [body appendData:[jsonPart dataUsingEncoding:NSUTF8StringEncoding]];
                        if (debugSwitch) [debugString appendString:jsonPart];
                    }
                }
                else if ([dataType isEqualToString:@"image"]) {
                    
                    NSString *fileName = dataInfo[DataFileNameKey];
                    UIImage *image = dataInfo[DataImageKey];
                    
                    if (fileName && image) {
                        
                        NSData *imageData = nil;
                        
                        if ([fileName hasSuffix:@"jpg"])        imageData = UIImageJPEGRepresentation(image, 0.9);
                        else if ([fileName hasSuffix:@"png"])   imageData = UIImagePNGRepresentation(image);
                        else                                    imageData = UIImageJPEGRepresentation(image, 0.9);
                        
                        NSMutableString *imagePart = [NSMutableString new];
                        
                        [imagePart appendString:ContentDisposition];
                        [imagePart appendString:newLine];
                        [imagePart appendString:[NSString stringWithFormat:@"Content-Type: %@",[Network mimeTypeForPath:fileName]]];
                        [imagePart appendString:newLine];
                        [imagePart appendString:[NSString stringWithFormat:@"Content-Length: %lu",(unsigned long)imageData.length]];
                        [imagePart appendString:newLine];
                        [imagePart appendString:@"Content-Transfer-Encoding: binary"];
                        [imagePart appendString:newLine];
                        [imagePart appendString:newLine];
                        
                        [body appendData:[imagePart dataUsingEncoding:NSUTF8StringEncoding]];
                        [body appendData:imageData];
                        [body appendData:[newLine dataUsingEncoding:NSUTF8StringEncoding]];
                        
                        [imagePart appendString:@"****Image Data*****"];
                        [imagePart appendString:newLine];
                        if (debugSwitch) [debugString appendString:imagePart];
                    }
                }
            }
        }];
        
        // boundary end
        
        NSString *boundaryEndString = [NSString stringWithFormat:@"--%@--%@",boundary,newLine];
        [body appendData:[boundaryEndString dataUsingEncoding:NSUTF8StringEncoding]];
        if (debugSwitch) [debugString appendString:boundaryEndString];
        
        // Content-Length
        
        NSString *contentLength = [NSString stringWithFormat:@"%ld",(unsigned long)body.length];
        [request addValue:contentLength forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:body];
        
        // Debug output
        
        if (debugSwitch) {
            
            NSString *separatorString = @"-------------------------------------------------------------------------------------------------------------------------";
            if ([request respondsToSelector:@selector(allHTTPHeaderFields)]) NSLog(@"\n%@\n %@ \n%@",separatorString,request.allHTTPHeaderFields,separatorString);
            NSLog(@"\n%@\n %@ \n%@",separatorString,debugString,separatorString);
        }
        
        return request;
    }
    else return nil;
}

+(NSString *)mimeTypeForPath:(NSString *)path {
    
    CFStringRef extension = (__bridge CFStringRef)[path pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);
    assert(UTI != NULL);
    
    NSString *mimetype = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    assert(mimetype != NULL);
    
    CFRelease(UTI);
    
    return mimetype;
}

+ (NSString *)boundary {
    
    CFUUIDRef  uuid;
    NSString  *uuidStr;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
    assert(uuidStr != NULL);
    
    CFRelease(uuid);
    
    return [NSString stringWithString:uuidStr];
}


@end
