//
//  Configuration.h
//  Forum
//
//  Created by Jens Jakob Jensen on 01/04/14.
//  Copyright (c) 2014 FK Distribution. All rights reserved.
//

@import Foundation;

/*!
 @warning Please do not use these from more than one place...
 */

@interface Configuration : NSObject

+ (NSString *)backendURL;
+ (NSString *)backendAccessKey;
+ (NSString *)backendAPIKey;

+ (BOOL)isProductionVersion;

+ (NSString *)azureMessagingConnectionString;
+ (NSString *)azureMessagingHubPath;

+ (NSString *)googleAnalyticsTrackerID;
+ (NSString *)googleAdwordsConversionID;
+ (NSString *)googleAdwordsConversionLabel;
+ (NSString *)googleAdwordsConversionValue;

+ (NSString *)facebookAppID;

+ (NSString *)flurryAPIKey;

+ (BOOL)forceShowLocalTab;

@end
