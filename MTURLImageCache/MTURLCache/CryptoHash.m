//
//  CryptoHash.m
//  MinButik
//
//  Created by Neon on 19/11/14.
//  Copyright (c) 2014 MineTilbud. All rights reserved.
//

#import "CryptoHash.h"

@implementation CryptoHash

+(NSString*)md5:(NSString*)string {
    
    const char *cStr = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
    NSMutableString *MD5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [MD5String appendFormat:@"%02x",result[i]];
    }
    return [NSString stringWithString:MD5String];
}

@end
