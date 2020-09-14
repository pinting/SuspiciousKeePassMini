//
//  KTouchIDAuthentication.m
//  TouchIDDemo
//
//  Created by Rohit Nisal on 7/21/16.
//  Copyright © 2016 Rohit Nisal. All rights reserved.
//

#import "KTouchIDAuthentication.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface KTouchIDAuthentication ()

@property (nonatomic, strong) LAContext * context;
// Default value is LAPolicyDeviceOwnerAuthenticationWithBiometrics.  This value will be useful if LocalAuthentication.framework introduces new auth policies in future version of iOS.
@property (nonatomic, assign) LAPolicy policy;
@end

@implementation KTouchIDAuthentication

+ (BOOL) canAuthenticateWithError:(NSError **) error
{
    if ([NSClassFromString(@"LAContext") class]) {
        if ([[KTouchIDAuthentication sharedInstance].context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:error]) {
            return YES;
        }
        return NO;
    }
    return NO;
}

static KTouchIDAuthentication *sharedInstance;

+ (KTouchIDAuthentication *) sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[KTouchIDAuthentication alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init{
    if (self = [super init]) {
        if ([NSClassFromString(@"LAContext") class]){
            self.context = [[LAContext alloc] init];
            self.useDefaultFallbackTitle = NO;
            self.hideFallbackButton = NO;
        }
    }
    if(self.reason == nil)
        self.reason = @"You uing ToucId/FacID";
    
    return self;
}

- (void) authenticateBiometricsWithSuccess:(KTouchIDAuthenticationCompletionBlock) success andFailure:(KTouchIDAuthenticationAuthenticationErrorBlock) failure {
    if ([NSClassFromString(@"LAContext") class]){
        self.context = [[LAContext alloc] init];
        NSError *authError = nil;
        if (self.useDefaultFallbackTitle) {
            self.context.localizedFallbackTitle = self.fallbackButtonTitle;
        }else if (self.hideFallbackButton){
            self.context.localizedFallbackTitle = @"";
        }
        if ([self.context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
            
            [self.context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                         localizedReason:self.reason
                                   reply:^(BOOL authenticated, NSError *error) {
                                       if (authenticated) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               if(success){
                                                   success();
                                                   return;
                                               }
                                           });
                                       } else {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               if(failure){
                                                   failure(error.code);
                                                   return;
                                               }
                                           });
                                       }
                                   }];
        }else {
            if(failure){
                failure(authError.code);
            }
        }
    }else{
        if(failure){
            failure(KTouchIDAuthenticationErroriOSNotSupport);
        }
    }
}
- (void) authenticatePasscodeWithSuccess:(KTouchIDAuthenticationCompletionBlock) success andFailure:(KTouchIDAuthenticationAuthenticationErrorBlock) failure{
    if ([NSClassFromString(@"LAContext") class] && SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9")){
        self.context = [[LAContext alloc] init];
        NSError *authError = nil;
        if (self.useDefaultFallbackTitle) {
            self.context.localizedFallbackTitle = self.fallbackButtonTitle;
        }else if (self.hideFallbackButton){
            self.context.localizedFallbackTitle = @"";
        }
        if ([self.context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&authError]) {
            [self.context evaluatePolicy:LAPolicyDeviceOwnerAuthentication
                         localizedReason:self.reason
                                   reply:^(BOOL authenticated, NSError *error) {
                                       if (authenticated) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               if(success){
                                                   success();
                                                   return;
                                               }
                                           });
                                       } else {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               if(failure){
                                                   failure(error.code);
                                                   return;
                                               }
                                           });
                                       }
                                   }];
        }else {
            if(failure){
                failure(authError.code);
            }
        }
    }else{
        if(failure){
            failure(KTouchIDAuthenticationErroriOSNotSupport);
        }
    }
}
@end
