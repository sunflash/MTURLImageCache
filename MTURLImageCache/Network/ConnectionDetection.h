//
//  ConnectionDetection.h
//  MinButik
//
//  Created by Neon on 20/11/14.
//  Copyright (c) 2014 MineTilbud. All rights reserved.
//

@import Foundation;

@interface ConnectionDetection : NSObject

@property BOOL isInternetAvailable;

+(id)sharedConnectionDetectionManager;
-(void)startConnectionMonitoring;

@end
