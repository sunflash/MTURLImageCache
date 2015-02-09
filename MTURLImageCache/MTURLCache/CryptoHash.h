//
//  CryptoHash.h
//  MinButik
//
//  Created by Neon on 19/11/14.
//  Copyright (c) 2014 MineTilbud. All rights reserved.
//

@import Foundation;
#import <CommonCrypto/CommonDigest.h>

@interface CryptoHash : NSObject

+(NSString*)md5:(NSString*)string;

@end
