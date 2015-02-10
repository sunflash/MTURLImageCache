//
//  ConnectionDetection.m
//  MinButik
//
//  Created by Neon on 20/11/14.
//  Copyright (c) 2014 MineTilbud. All rights reserved.
//

#import "ConnectionDetection.h"
#import "Reachability.h"
#import "Network.h"

@interface ConnectionDetection ()

@property (nonatomic) Reachability *googleReachability;
@property (nonatomic) Reachability *appleReachability;

@property BOOL isGoogleReachable;
@property BOOL isAppleReachable;

@end

@implementation ConnectionDetection

//--------------------------------------------------------------------------------------------------------------------------------------------

#pragma mark - Connection

+(id)sharedConnectionDetectionManager {
    
    static ConnectionDetection *connectionDetection = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        connectionDetection = [self new];
    });
    return connectionDetection;
}

-(void)startConnectionMonitoring {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    NSString *remoteHostNameApple = @"www.apple.com";
    self.appleReachability = [Reachability reachabilityWithHostName:remoteHostNameApple];
    [self.appleReachability startNotifier];
    
    NSString *remoteHostNameGoogle = @"www.google.com";
    self.googleReachability = [Reachability reachabilityWithHostName:remoteHostNameGoogle];
    [self.googleReachability startNotifier];
    
    [self updateReachabilityStat:self.googleReachability];
    [self updateReachabilityStat:self.appleReachability];
}

- (void)reachabilityChanged:(NSNotification *)note {
    
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateReachabilityStat:curReach];
}

- (void)updateReachabilityStat:(Reachability *)reachability {
    
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    BOOL connectionRequired = [reachability connectionRequired];
    
    if (netStatus != NotReachable && connectionRequired == NO) {
        
        if (reachability == self.googleReachability)            self.isGoogleReachable = YES;
        else if (reachability == self.appleReachability)        self.isAppleReachable = YES;
    }
    else {
        
        if (reachability == self.googleReachability)            self.isGoogleReachable = NO;
        else if (reachability == self.appleReachability)        self.isAppleReachable = NO;
    }
    
    if (self.isAppleReachable || self.isGoogleReachable)    self.isInternetAvailable = YES;
    else                                                    self.isInternetAvailable = NO;
    
//    if (self.isInternetAvailable)   NSLog(@"Internet: YES");
//    else                            NSLog(@"Internet: NO");
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

@end









