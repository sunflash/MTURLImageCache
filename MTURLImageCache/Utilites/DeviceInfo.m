//
//  DeviceInfo.m
//  Test
//
//  Created by Neon on 16/02/14.
//  Copyright (c) 2014 FK Distribution. All rights reserved.
//

#import "DeviceInfo.h"

@implementation DeviceInfo

//-----------------------------------------------------------------------------------------------------------------------

#pragma mark - Device Info

+(NSDictionary*)getDeviceInfo {
    
    static NSDictionary *deviceInfo = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        deviceInfo = @{@"name":[[UIDevice currentDevice] name],
                       @"systemName":[[UIDevice currentDevice] systemName],
                       @"systemVersion":[[UIDevice currentDevice] systemVersion],
                       @"model":[[UIDevice currentDevice] model],
                       @"localizedModel":[[UIDevice currentDevice] localizedModel],
                       @"identifierForVendor":[[[UIDevice currentDevice] identifierForVendor] UUIDString]};
    });
    
    return  deviceInfo;
}

+(float)systemVersionInFloat {
    
    static float versionFloat;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    
        NSString *versionString = [[UIDevice currentDevice]systemVersion];
        
        NSArray *stringArray = [versionString componentsSeparatedByString:@"."];
        
        for (int i = 0; i < stringArray.count; i++) {
            
            if (i == 0) {versionFloat = [[stringArray objectAtIndex:i] floatValue];}
            if (i == 1) {versionFloat = versionFloat + [[stringArray objectAtIndex:i] floatValue] * 0.1;}
            if (i == 2) {versionFloat = versionFloat + [[stringArray objectAtIndex:i] floatValue] * 0.01;}
        }
    });
    
	//NSLog(@"SystemVersionInFloat %.2f",versionFloat);
    
	return versionFloat;
}

+(DeviceType)getDeviceType {
    
    static DeviceType deviceType = unknownDevice;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            
            deviceType = phone;
        }
        else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            
            deviceType = pad;
        }
    });
    
    return deviceType;
}

+(NSString *)getDeviceTypeString {
    
    static NSString *deviceTypeString;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)     deviceTypeString = @"phone";
        else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)  deviceTypeString = @"pad";
        else                                                                                deviceTypeString = @"unknown";
    });
    
    return deviceTypeString;
}

+(BOOL)isiPhone4Or4S {

    static BOOL isiPhone4Or4S;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    
        if ([DeviceInfo getDeviceType] == phone && [DeviceInfo getScreenType] == retina ) {
            
            CGSize screenSize = [self getAppScreenSize:UIInterfaceOrientationPortrait];
            
            if (screenSize.width == 320 && screenSize.height == 480) isiPhone4Or4S = YES;
            else                                                     isiPhone4Or4S = NO;
        }
        else isiPhone4Or4S = NO;
    });
    
    return isiPhone4Or4S;
}

+(BOOL)isiPhone6 {
    
    static BOOL isiPhone6;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if ([DeviceInfo getDeviceType] == phone && [DeviceInfo getScreenType] == retina ) {
            
            CGSize screenSize = [self getAppScreenSize:UIInterfaceOrientationPortrait];
            
            if (screenSize.width == 375 && screenSize.height == 667) isiPhone6 = YES;
            else                                                     isiPhone6 = NO;
        }
        else isiPhone6 = NO;
    });
    
    return isiPhone6;
}

+(BOOL)isiPhone6Plus {

    static BOOL isiPhone6Plus;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if ([DeviceInfo getDeviceType] == phone && [UIScreen mainScreen].scale == 3.0 ) {
            
            CGSize screenSize = [self getAppScreenSize:UIInterfaceOrientationPortrait];
            
            if (screenSize.width == 414 && screenSize.height == 736) isiPhone6Plus = YES;
            else                                                     isiPhone6Plus = NO;
        }
        else isiPhone6Plus = NO;
    });
    
    return isiPhone6Plus;
}

//-----------------------------------------------------------------------------------------------------------------------

#pragma mark - Screen Info

+(ScreenType)getScreenType {
    
    static ScreenType deviecScreenType;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        float screenScale = [UIScreen mainScreen].scale;
        
        if (screenScale > 1.1) deviecScreenType = retina;
        else                   deviecScreenType = lowRes;

    });
    
    return deviecScreenType;
}

+(ScreenOrientation)getScreenOrientation {
    
    ScreenOrientation screenOrientation = unknownOrientation;
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        
        screenOrientation = portrait;
    }
    else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
    
        screenOrientation= landscape;
    }
    
    return screenOrientation;
}

+(NSNumber*)getScreenScale {
    
    return @([UIScreen mainScreen].scale);
}

//-----------------------------------------------------------------------------------------------------------------------

#pragma mark - App frame, bounds, status bar size

+(CGSize)getAppFrameSize {

    CGSize appFrameSize;
    CGRect applicationFrame = [UIScreen mainScreen].bounds;
    
    ScreenOrientation screenOrientation = [self getScreenOrientation];
    
    if (screenOrientation == portrait) {
        
        appFrameSize = CGSizeMake(applicationFrame.size.width, applicationFrame.size.height);
    }
    else if (screenOrientation == landscape && applicationFrame.size.width < applicationFrame.size.height) {
    
        appFrameSize = CGSizeMake(applicationFrame.size.height, applicationFrame.size.width);
    }
    else appFrameSize = applicationFrame.size;
    
    return appFrameSize;
}

+(CGSize)getAppFrameSize:(UIInterfaceOrientation)interfaceOrientation {

    CGSize appFrameSize;
    CGRect applicationFrame = [UIScreen mainScreen].bounds;
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        
        appFrameSize = CGSizeMake(applicationFrame.size.width, applicationFrame.size.height);
    }
    else if (UIInterfaceOrientationIsLandscape(interfaceOrientation) && applicationFrame.size.width < applicationFrame.size.height) {
    
        appFrameSize = CGSizeMake(applicationFrame.size.height, applicationFrame.size.width);
    }
    else appFrameSize = applicationFrame.size;
    
    return appFrameSize;
}

+(CGSize)getAppScreenSize {
    
    CGSize appScreenSize;
    CGRect appBoundSize = [UIScreen mainScreen].bounds;
    
    ScreenOrientation screenOrientation = [self getScreenOrientation];
    
    if (screenOrientation == portrait) {
        
        appScreenSize = CGSizeMake(appBoundSize.size.width, appBoundSize.size.height);
    }
    else if (screenOrientation == landscape && appBoundSize.size.width < appBoundSize.size.height) {
        
        appScreenSize = CGSizeMake(appBoundSize.size.height, appBoundSize.size.width);
    }
    else appScreenSize = appBoundSize.size;
    
    return appScreenSize;
}

+(CGSize)getAppScreenSize:(UIInterfaceOrientation)interfaceOrientation {
    
    CGSize appScreenSize;
    CGRect appBoundSize = [UIScreen mainScreen].bounds;
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        
        appScreenSize = CGSizeMake(appBoundSize.size.width, appBoundSize.size.height);
    }
    else if (UIInterfaceOrientationIsLandscape(interfaceOrientation) && appBoundSize.size.width < appBoundSize.size.height) {
        
        appScreenSize = CGSizeMake(appBoundSize.size.height, appBoundSize.size.width);
    }
    else appScreenSize = appBoundSize.size;
    
    return appScreenSize;
}

+(CGSize)getStatusBarSize {

    CGSize statusBarSize;
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    
    ScreenOrientation screenOrientation = [self getScreenOrientation];
    
    if (screenOrientation == portrait) {
        
        statusBarSize = CGSizeMake(statusBarFrame.size.width,statusBarFrame.size.height);
    }
    else if (screenOrientation == landscape && statusBarFrame.size.width < statusBarFrame.size.height) {
    
        statusBarSize = CGSizeMake(statusBarFrame.size.height, statusBarFrame.size.width);
    }
    else statusBarSize = statusBarFrame.size;
    
    return statusBarSize;
}

@end

