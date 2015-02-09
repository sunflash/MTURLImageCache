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
    return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1],
            result[2], result[3],
            result[4], result[5],
            result[6], result[7],
            result[8], result[9],
            result[10], result[11],
            result[12], result[13],
            result[14], result[15]
            ];

}

@end