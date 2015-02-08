//
//  DeviceInfo.h
//  Test
//
//  Created by Neon on 16/02/14.
//  Copyright (c) 2014 FK Distribution. All rights reserved.

@import Foundation;
@import UIKit;

typedef NS_ENUM(NSUInteger, DeviceType) {phone,pad,unknownDevice};
typedef NS_ENUM(NSUInteger, ScreenType) {lowRes,retina};
typedef NS_ENUM(NSUInteger, ScreenOrientation) {portrait,landscape,unknownOrientation};

@interface DeviceInfo : NSObject

+(NSDictionary*)getDeviceInfo;
+(float)systemVersionInFloat;

+(DeviceType)getDeviceType;
+(NSString *)getDeviceTypeString;
+(BOOL)isiPhone4Or4S;
+(BOOL)isiPhone6;
+(BOOL)isiPhone6Plus;

+(ScreenType)getScreenType;
+(ScreenOrientation)getScreenOrientation;
+(NSNumber*)getScreenScale;

+(CGSize)getAppFrameSize;
+(CGSize)getAppFrameSize:(UIInterfaceOrientation)interfaceOrientation;

+(CGSize)getAppScreenSize;
+(CGSize)getAppScreenSize:(UIInterfaceOrientation)interfaceOrientation;
+(CGSize)getStatusBarSize;

@end
