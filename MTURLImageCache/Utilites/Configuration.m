//
//  Configuration.m
//  Forum
//
//  Created by Jens Jakob Jensen on 01/04/14.
//  Copyright (c) 2014 FK Distribution. All rights reserved.
//

#import "Configuration.h"



#define BACKEND_URL_TEST @"http://fkd.forum.minreklame.ios.test.pentia.net/api"
#define BACKEND_URL_Staging @"http://test.minetilbud.dk/api"

#define BACKEND_URL_PROD @"https://ios.minetilbud.dk/api"
#define BACKEND_URL_PROD_AZURE @"https://minetilbud.azure-api.net/api/v3"

#define BACKEND_ACCESS_KEY_PROD @"00d9aea5f59844188143dec39b204d63"

#define IOS_TEST_API_KEY @"df6baa3c-9a6b-4395-9d46-bff415c22cdf"
#define IOS_BETA_API_KEY @"3ab9ca46-66ae-411c-8e3c-5a485d5203e8"
#define IOS_PROD_API_KEY @"21fb6a84-5beb-4001-a778-2e936e754c7b"


#define AzureMessagingConnectionString_Test @"Endpoint=sb://fk-dev-ns.servicebus.windows.net/;SharedAccessKeyName=DefaultListenSharedAccessSignature;SharedAccessKey=n/WKIfHd6z19Rx0ewvxQuD/EYbFjenUh1fIFNc3nKKU="
#define AzureMessagingHubPath_Test          @"fk-dev"

#define AzureMessagingConnectionString_Prod @"Endpoint=sb://fk-prod.servicebus.windows.net/;SharedAccessKeyName=DefaultListenSharedAccessSignature;SharedAccessKey=5gKNqbudb8vUN2cR9gA+Y3opGG+ohXd3OGp1u60qn5M="
#define AzureMessagingHubPath_Prod          @"prod01"


#define GA_TRACKER_ID_TEST @"UA-39096681-2"
#define GA_TRACKER_ID_PROD @"UA-39096681-5"

#define ACT_ConversionID    @"977856904"
#define ACT_ConversionLabel @"Fn5uCPi02QcQiNOj0gM"
#define ACT_ConversionValue @"10.000000"

#define Facebook_APP_ID @"431628133616607"

#define Flurry_API_Key_Prod @"27BNVXX9C36YTS6MTHK5"
#define Flurry_API_Key_Test @""


@implementation Configuration

+ (NSString *)mainBundleIdentifier {
    
    static NSString *mainBundleIdentifier =  nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mainBundleIdentifier = [NSBundle mainBundle].bundleIdentifier;
    });
    return mainBundleIdentifier;
}

+ (BOOL)isTestVersion {
    return [[Configuration mainBundleIdentifier] hasSuffix:@"-test"];
}

+ (BOOL)isBetaVersion {
    return [[Configuration mainBundleIdentifier] hasSuffix:@"-beta"];
}

+ (BOOL)isStagingVersion {
    return [[Configuration mainBundleIdentifier] hasSuffix:@"-staging"];
}

+ (BOOL)isProductionVersion {
    
    BOOL isProductionVersion = YES;

    NSString *mainBundleIdentifier = [Configuration mainBundleIdentifier];
    
    if ([mainBundleIdentifier hasSuffix:@"-test"] ||
        [mainBundleIdentifier hasSuffix:@"-beta"] ||
        [mainBundleIdentifier hasSuffix:@"-staging"]) {
        
        isProductionVersion = NO;
    }
    
    return isProductionVersion;
}

+(BOOL)useAzureApiManagerBackend {
    
    if ([self isTestVersion] || [self isStagingVersion])    return NO;
    else                                                    return YES;
}

+ (NSString *)backendURL {
    
    if ([self isTestVersion])           return BACKEND_URL_TEST;
    else if ([self isStagingVersion])   return BACKEND_URL_Staging;
    else if ([self useAzureApiManagerBackend])   return BACKEND_URL_PROD_AZURE;
    else                                return BACKEND_URL_PROD;
}

+(NSString *)backendAccessKey {
    return [self useAzureApiManagerBackend] ? BACKEND_ACCESS_KEY_PROD : @"";
}

+ (NSString *)backendAPIKey {
    
    if ([self isTestVersion] || [self isStagingVersion])    return IOS_TEST_API_KEY;
    else if ([self isBetaVersion])                          return IOS_BETA_API_KEY;
    else                                                    return IOS_PROD_API_KEY;
}

+ (NSString *)azureMessagingConnectionString {
    if ([self isTestVersion] || [self isStagingVersion]) return AzureMessagingConnectionString_Test;
    else                                                 return AzureMessagingConnectionString_Prod;
}

+ (NSString *)azureMessagingHubPath {
    if ([self isTestVersion] || [self isStagingVersion]) return AzureMessagingHubPath_Test;
    else                                                 return AzureMessagingHubPath_Prod;
}

+ (NSString *)googleAnalyticsTrackerID {
    if ([self isTestVersion] || [self isStagingVersion] || [self isBetaVersion]) return GA_TRACKER_ID_TEST;
    else                                                 return GA_TRACKER_ID_PROD;
}

+ (NSString *)googleAdwordsConversionID {
    return ACT_ConversionID;
}

+ (NSString *)googleAdwordsConversionLabel {
    return ACT_ConversionLabel;
}

+ (NSString *)googleAdwordsConversionValue {
    return ACT_ConversionValue;
}

+ (NSString *)facebookAppID {
    return Facebook_APP_ID;
}

+ (NSString *)flurryAPIKey {
    if ([self isTestVersion] || [self isStagingVersion] || [self isBetaVersion]) return Flurry_API_Key_Test;
    else return Flurry_API_Key_Prod;
}

+(BOOL)forceShowLocalTab {
    if ([self isTestVersion] || [self isStagingVersion] || [self isBetaVersion])
        return YES;
    return NO;
}

@end
