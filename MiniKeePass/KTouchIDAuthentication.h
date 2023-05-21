//
//  KTouchIDAuthentication.h
//  TouchIDDemo
//
//  Created by Rohit Nisal on 7/21/16.
//  Copyright © 2016 Rohit Nisal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

typedef NS_ENUM(NSInteger, KTouchIDAuthenticationError)
{
    /// Authentication was not successful, because user failed to provide valid credentials.
    KTouchIDAuthenticationErrorAuthenticationFailed = -1,
    
    /// Authentication was canceled by user (e.g. tapped Cancel button).
    KTouchIDAuthenticationErrorUserCancel           = -2,
    
    /// Authentication was canceled, because the user tapped the fallback button (Enter Password).
    KTouchIDAuthenticationErrorUserFallback         = -3,
    
    /// Authentication was canceled by system (e.g. another application went to foreground).
    KTouchIDAuthenticationErrorSystemCancel         = -4,
    
    /// Authentication could not start, because passcode is not set on the device.
    KTouchIDAuthenticationErrorPasscodeNotSet       = -5,
    
    /// Authentication could not start, because Touch ID is not available on the device.
    KTouchIDAuthenticationErrorTouchIDNotAvailable  = -6,
    
    /// Authentication could not start, because Touch ID has no enrolled fingers.
    KTouchIDAuthenticationErrorTouchIDNotEnrolled   = -7,
    
    /// Authentication could not start, because Touch ID iOS version not support.
    KTouchIDAuthenticationErroriOSNotSupport   = 9999
};

@interface KTouchIDAuthentication : NSObject

typedef void(^KTouchIDAuthenticationCompletionBlock)();
typedef void(^KTouchIDAuthenticationAuthenticationErrorBlock)(long);


+ (KTouchIDAuthentication *) sharedInstance;

//reason string presented to the user in auth dialog
@property (nonatomic, copy) NSString * reason;

//Allows fallback button title customization. If set to @"", the button will be hidden. If set to nil, "Enter Password" is used.
@property (nonatomic, copy) NSString * fallbackButtonTitle;

//If set to NO it will not customize the fallback title, shows default "Enter Password".  If set to YES, title is customizable.  Default value is NO.
@property (nonatomic, assign) BOOL useDefaultFallbackTitle;

// Disable "Enter Password" fallback button. Default value is NO.
@property (nonatomic, assign) BOOL hideFallbackButton;

// returns YES if device and Apple ID can use Touch ID. If there is an error, it returns NO and assigns error so that UI can respond accordingly
+ (BOOL) canAuthenticateWithError:(NSError **) error;

// Authenticate the user by showing the Touch ID dialog and calling your success or failure block.  Failure block will return an NSError with a code of enum type LAError: https://developer.apple.com/library/ios/documentation/LocalAuthentication/Reference/LAContext_Class/index.html#//apple_ref/c/tdef/LAError
// Use the error to handle different types of failure and fallback authentication.
- (void) authenticateBiometricsWithSuccess:(KTouchIDAuthenticationCompletionBlock) success andFailure:(KTouchIDAuthenticationAuthenticationErrorBlock) failure;
- (void) authenticatePasscodeWithSuccess:(KTouchIDAuthenticationCompletionBlock) success andFailure:(KTouchIDAuthenticationAuthenticationErrorBlock) failure;
@end
