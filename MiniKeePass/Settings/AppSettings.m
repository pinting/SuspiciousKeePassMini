/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
 * Mdified by Frank Hausmann 2020-2023
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "AppSettings.h"
#import "KeychainUtils.h"
#import "PasswordUtils.h"
#import "AppDelegate.h"
#import "KeePassMini-Swift.h"

#define VERSION                    @"version"
#define USER_NOTIFY                @"usernotify"
#define EXIT_TIME                  @"exitTime"
#define PIN_ENABLED                @"pinEnabled"
//#define ANALYSE_ENABLED            @"analyseDataEnabled"
#define PIN                        @"PIN"
#define DEFAULTDB                  @"DefaultDB"
#define CLOUDURL                   @"cloudURL"
#define CLOUDUSER                  @"cloudUSER"
#define CLOUDPWD                   @"cloudPWD"
#define CLOUDTYPE                  @"cloudType"
#define REFRESHTOKEN               @"refreshToken"
#define NEEDBACKUP                 @"fileneedsBackup"
#define PIN_FAILED_ATTEMPTS        @"pinFailedAttempts"
#define DARK_ENABLED               @"darkEnabled"
#define TOUCH_ID_ENABLED           @"touchIdEnabled"
#define DELETE_ON_FAILURE_ENABLED  @"deleteOnFailureEnabled"
#define DELETE_ON_FAILURE_ATTEMPTS @"deleteOnFailureAttempts"
#define CLOSE_ENABLED              @"closeEnabled"
#define CLOSE_TIMEOUT              @"closeTimeout"
#define REMEMBER_PASSWORDS_ENABLED @"rememberPasswordsEnabled"
#define HIDE_PASSWORDS             @"hidePasswords"
#define SORT_ALPHABETICALLY        @"sortAlphabetically"
#define SEARCH_TITLE_ONLY          @"searchTitleOnly"
#define PASSWORD_ENCODING          @"passwordEncoding"
#define CLEAR_CLIPBOARD_ENABLED    @"clearClipboardEnabled"
#define BACKUP_DISABLED            @"backupEnabled"
#define BACKUP_FIRSTTIME           @"backupFirstTime"
#define AUTOFILL_ENABLED           @"autofillDisabled"
#define AUTOFILL_METHOD            @"autoFillMethod"
#define CLEAR_CLIPBOARD_TIMEOUT    @"clearClipboardTimeout"
#define INTERNAL_VERSION           @"internalVersion"
#define WEB_BROWSER_INTEGRATED     @"webBrowserIntegrated"
#define PW_GEN_LENGTH              @"pwGenLength"
#define PW_GEN_CHAR_SETS           @"pwGenCharSets"

@interface AppSettings () {
    NSUserDefaults *userDefaults;
}
@end

@implementation AppSettings


static NSInteger deleteOnFailureAttemptsValues[] = {
    3,
    5,
    10,
    15
};

static NSInteger closeTimeoutValues[] = {
    0,
    30,
    60,
    120,
    300
};

static NSInteger clearClipboardTimeoutValues[] = {
    30,
    60,
    120,
    180
};

static NSInteger internalVersionValues[] = {
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9
};


static NSStringEncoding passwordEncodingValues[] = {
    NSUTF8StringEncoding,
    NSUTF16BigEndianStringEncoding,
    NSUTF16LittleEndianStringEncoding,
    NSISOLatin1StringEncoding,
    NSISOLatin2StringEncoding,
    NSASCIIStringEncoding,
    NSJapaneseEUCStringEncoding,
    NSISO2022JPStringEncoding
};

static AppSettings *sharedInstance;

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        sharedInstance = [[AppSettings alloc] init];
    }
}

+ (AppSettings *)sharedInstance {
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        userDefaults = [NSUserDefaults standardUserDefaults];

        // Register the default values
        NSMutableDictionary *defaultsDict = [NSMutableDictionary dictionary];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:DARK_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:TOUCH_ID_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:DELETE_ON_FAILURE_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithInt:1] forKey:DELETE_ON_FAILURE_ATTEMPTS];
        [defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:CLOSE_ENABLED];
        //[defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:ANALYSE_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:USER_NOTIFY];
        [defaultsDict setValue:[NSNumber numberWithInt:4] forKey:CLOSE_TIMEOUT];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:REMEMBER_PASSWORDS_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:HIDE_PASSWORDS];
        [defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:SORT_ALPHABETICALLY];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:SEARCH_TITLE_ONLY];
        [defaultsDict setValue:[NSNumber numberWithInt:0] forKey:PASSWORD_ENCODING];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:CLEAR_CLIPBOARD_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithInt:0] forKey:CLEAR_CLIPBOARD_TIMEOUT];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:BACKUP_DISABLED];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:BACKUP_FIRSTTIME];
        [defaultsDict setValue:[NSNumber numberWithBool:NO] forKey:AUTOFILL_ENABLED];
        [defaultsDict setValue:[NSNumber numberWithInt:0] forKey:CLOUDTYPE];
        [defaultsDict setValue:[NSNumber numberWithInt:0] forKey:AUTOFILL_METHOD];
        [defaultsDict setValue:[NSNumber numberWithBool:YES] forKey:WEB_BROWSER_INTEGRATED];
        [defaultsDict setValue:[NSNumber numberWithInt:10] forKey:PW_GEN_LENGTH];
        [defaultsDict setValue:[NSNumber numberWithInt:0x07] forKey:PW_GEN_CHAR_SETS];
        [userDefaults registerDefaults:defaultsDict];

        [self upgrade];
    }
    return self;
}

- (void)upgrade {
    NSString *version = [self version];
    if (version == nil) {
        version = @"1.5.2";
    }
    
    if ([version isEqualToString:@"1.5.2"]) {
        [self upgrade152];
    }
    
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [self setVersion:currentVersion];
}

- (void)upgrade152 {
    // Migrate the pin enabled setting
    BOOL pinEnabled = [userDefaults boolForKey:PIN_ENABLED];
    [self setPinEnabled:pinEnabled];
    
    
    // Migrate the pin failed attempts setting
    NSInteger pinFailedAttempts = [userDefaults boolForKey:PIN_FAILED_ATTEMPTS];
    [self setPinFailedAttempts:pinFailedAttempts];

    // Check if we need to migrate the plaintext pin to the hashed pin
    NSString *pin = [self pin];
    if (![pin hasPrefix:@"sha512"]) {
        NSString *pinHash = [PasswordUtils hashPassword:pin];
        [self setPin:pinHash];
    }

    // Remove the old keys
    [userDefaults removeObjectForKey:EXIT_TIME];
    [userDefaults removeObjectForKey:PIN_ENABLED];
    [userDefaults removeObjectForKey:PIN_FAILED_ATTEMPTS];
}

- (NSString *)version {
    return [userDefaults stringForKey:VERSION];
}

- (void)setVersion:(NSString *)version {
    return [userDefaults setValue:version forKey:VERSION];
}

- (NSDate *)exitTime {
    NSString *string = [KeychainUtils stringForKey:EXIT_TIME andServiceName:KEYCHAIN_PIN_SERVICE];
    if (string == nil) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSinceReferenceDate:[string doubleValue]];
}

- (void)setExitTime:(NSDate *)exitTime {
    NSNumber *number = [NSNumber numberWithDouble:[exitTime timeIntervalSinceReferenceDate]];
    [KeychainUtils setString:[number stringValue] forKey:EXIT_TIME andServiceName:KEYCHAIN_PIN_SERVICE];
}

- (BOOL)darkEnabled {
    return [userDefaults boolForKey:DARK_ENABLED];
}

- (void)setDarkEnabled:(BOOL)darkEnabled {
    [userDefaults setBool:darkEnabled forKey:DARK_ENABLED];
}

/*- (BOOL)analyseDataEnabled {
    return [userDefaults boolForKey:ANALYSE_ENABLED];
}

- (void)setAnalyseDataEnabled:(BOOL)analyseDataEnabled {
    [userDefaults setBool:analyseDataEnabled forKey:ANALYSE_ENABLED];
}*/

- (BOOL)userNotify {
    return [userDefaults boolForKey:USER_NOTIFY];
}

- (void)setUserNotify:(BOOL)userNotify {
    [userDefaults setBool:userNotify forKey:USER_NOTIFY];
}

- (BOOL)pinEnabled {
    NSString *string = [KeychainUtils stringForKey:PIN_ENABLED andServiceName:KEYCHAIN_PIN_SERVICE];
    if (string == nil) {
        return NO;
    }
    return [string boolValue];
}

- (void)setPinEnabled:(BOOL)pinEnabled {
    NSNumber *number = [NSNumber numberWithBool:pinEnabled];
    [KeychainUtils setString:[number stringValue] forKey:PIN_ENABLED andServiceName:KEYCHAIN_PIN_SERVICE];
}

- (NSString *)pin {
    return [KeychainUtils stringForKey:PIN andServiceName:KEYCHAIN_PIN_SERVICE];
}

- (void)setPin:(NSString *)pin {
    [KeychainUtils setString:pin forKey:PIN andServiceName:KEYCHAIN_PIN_SERVICE];
}

- (NSInteger)pinFailedAttempts {
    NSString *string = [KeychainUtils stringForKey:PIN_FAILED_ATTEMPTS andServiceName:KEYCHAIN_PIN_SERVICE];
    if (string == nil) {
        return 0;
    }
    return [string integerValue];
}

- (void)setPinFailedAttempts:(NSInteger)pinFailedAttempts {
    NSNumber *number = [NSNumber numberWithInteger:pinFailedAttempts];
    [KeychainUtils setString:[number stringValue] forKey:PIN_FAILED_ATTEMPTS andServiceName:KEYCHAIN_PIN_SERVICE];
}

- (BOOL)deleteOnFailureEnabled {
    return [userDefaults boolForKey:DELETE_ON_FAILURE_ENABLED];
}

- (BOOL)touchIdEnabled {
    return [userDefaults boolForKey:TOUCH_ID_ENABLED];
}

- (void)setTouchIdEnabled:(BOOL)touchIdEnabled {
    [userDefaults setBool:touchIdEnabled forKey:TOUCH_ID_ENABLED];
}

- (void)setDeleteOnFailureEnabled:(BOOL)deleteOnFailureEnabled {
    [userDefaults setBool:deleteOnFailureEnabled forKey:DELETE_ON_FAILURE_ENABLED];
}

- (NSInteger)deleteOnFailureAttempts {
    return deleteOnFailureAttemptsValues[[userDefaults integerForKey:DELETE_ON_FAILURE_ATTEMPTS]];
}

- (NSInteger)deleteOnFailureAttemptsIndex {
    return [userDefaults integerForKey:DELETE_ON_FAILURE_ATTEMPTS];
}

- (void)setDeleteOnFailureAttemptsIndex:(NSInteger)deleteOnFailureAttemptsIndex {
    [userDefaults setInteger:deleteOnFailureAttemptsIndex forKey:DELETE_ON_FAILURE_ATTEMPTS];
}

- (BOOL)closeEnabled {
    return [userDefaults boolForKey:CLOSE_ENABLED];
}

- (void)setCloseEnabled:(BOOL)closeEnabled {
    [userDefaults setBool:closeEnabled forKey:CLOSE_ENABLED];
}

- (BOOL)autofillEnabled {
    return [userDefaults boolForKey:AUTOFILL_ENABLED];
}

- (void)setAutofillEnabled:(BOOL)autofillEnabled{
    [userDefaults setBool:autofillEnabled forKey:AUTOFILL_ENABLED];
}

- (NSInteger)autoFillMethod {
    return [userDefaults integerForKey:AUTOFILL_METHOD];
}
- (void)setautoFillMethod:(NSInteger)autoFillMethod{
    [userDefaults setInteger:autoFillMethod forKey:AUTOFILL_METHOD];
}

- (NSInteger)cloudType {
    return [userDefaults integerForKey:CLOUDTYPE];
}
- (void)setCloudType:(NSInteger)cloudType{
    [userDefaults setInteger:cloudType forKey:CLOUDTYPE];
}
- (NSString *)defaultDB {
    return [userDefaults stringForKey:DEFAULTDB];
}

- (void)setDefaultDB:(NSString *)defdb {
    //[userDefaults setString:defdb forKey:DEFAULTDB];
    [userDefaults setValue:defdb forKey:DEFAULTDB];
}

- (NSString *)fileneedsBackup {
    return [userDefaults stringForKey:NEEDBACKUP];
}

- (void)setfileneedsBackup:(NSString *)fileneedsBackup {
    //[userDefaults setString:defdb forKey:DEFAULTDB];
    [userDefaults setValue:fileneedsBackup forKey:NEEDBACKUP];
}

- (NSString *)cloudURL {
    return [userDefaults stringForKey:CLOUDURL];
}

- (void)setCloudURL:(NSString *)cloudURL {
    //[userDefaults setString:defdb forKey:DEFAULTDB];
    [userDefaults setValue:cloudURL forKey:CLOUDURL];
}

- (NSString *)cloudUser {
    return [userDefaults stringForKey:CLOUDUSER];
}

- (void)setCloudUser:(NSString *)cloudUser {
    //[userDefaults setString:defdb forKey:DEFAULTDB];
    [userDefaults setValue:cloudUser forKey:CLOUDUSER];
}

- (NSString *)cloudPWD {
    return [userDefaults stringForKey:CLOUDPWD];
}

- (void)setCloudPWD:(NSString *)cloudPWD {
    //[userDefaults setString:defdb forKey:DEFAULTDB];
    [userDefaults setValue:cloudPWD forKey:CLOUDPWD];
}

- (NSString *)refreshToken {
    return [userDefaults stringForKey:REFRESHTOKEN];
}

- (void)setRefreshToken:(NSString *)refreshToken {
    //[userDefaults setString:defdb forKey:DEFAULTDB];
    [userDefaults setValue:refreshToken forKey:REFRESHTOKEN];
}

- (BOOL)backupEnabled {
    return [userDefaults boolForKey:BACKUP_DISABLED];
}

- (void)setBackupEnabled:(BOOL)backupEnabled {
    [userDefaults setBool:backupEnabled forKey:BACKUP_DISABLED];

    NSURL *url = [NSURL fileURLWithPath:[AppDelegate documentsDirectory] isDirectory:YES];

    NSError *error = nil;
    if (![url setResourceValue:[NSNumber numberWithBool:!backupEnabled] forKey:NSURLIsExcludedFromBackupKey error:&error]) {
        NSLog(@"Error excluding %@ from backup: %@", url, error);
    }
    
    if(backupEnabled == NO){
        [userDefaults setBool:NO forKey:BACKUP_FIRSTTIME];
    }
}

- (BOOL)backupFirstTime {
    return [userDefaults boolForKey:BACKUP_FIRSTTIME];
}

- (void)setBackupFirstTime:(BOOL)backupFirstTime {
    [userDefaults setBool:backupFirstTime forKey:BACKUP_FIRSTTIME];
}

- (NSInteger)closeTimeout {
    return closeTimeoutValues[[userDefaults integerForKey:CLOSE_TIMEOUT]];
}

- (NSInteger)closeTimeoutIndex {
    return [userDefaults integerForKey:CLOSE_TIMEOUT];
}

- (void)setCloseTimeoutIndex:(NSInteger)closeTimeoutIndex {
    [userDefaults setInteger:closeTimeoutIndex forKey:CLOSE_TIMEOUT];
}

- (BOOL)rememberPasswordsEnabled {
    return [userDefaults boolForKey:REMEMBER_PASSWORDS_ENABLED];
}

- (void)setRememberPasswordsEnabled:(BOOL)rememberPasswordsEnabled {
    [userDefaults setBool:rememberPasswordsEnabled forKey:REMEMBER_PASSWORDS_ENABLED];
}

- (BOOL)hidePasswords {
    return [userDefaults boolForKey:HIDE_PASSWORDS];
}

- (void)setHidePasswords:(BOOL)hidePasswords {
    [userDefaults setBool:hidePasswords forKey:HIDE_PASSWORDS];
}

- (BOOL)sortAlphabetically {
    return [userDefaults boolForKey:SORT_ALPHABETICALLY];
}

- (void)setSortAlphabetically:(BOOL)sortAlphabetically {
    [userDefaults setBool:sortAlphabetically forKey:SORT_ALPHABETICALLY];
}

- (BOOL)searchTitleOnly {
    return [userDefaults boolForKey:SEARCH_TITLE_ONLY];
}

- (void)setSearchTitleOnly:(BOOL)searchTitleOnly {
    [userDefaults setBool:searchTitleOnly forKey:SEARCH_TITLE_ONLY];
}

- (NSStringEncoding)passwordEncoding {
    return passwordEncodingValues[[userDefaults integerForKey:PASSWORD_ENCODING]];
}

- (NSInteger)passwordEncodingIndex {
    return [userDefaults integerForKey:PASSWORD_ENCODING];
}

- (void)setPasswordEncodingIndex:(NSInteger)passwordEncodingIndex {
    [userDefaults setInteger:passwordEncodingIndex forKey:PASSWORD_ENCODING];
}

- (BOOL)clearClipboardEnabled {
    return [userDefaults boolForKey:CLEAR_CLIPBOARD_ENABLED];
}

- (void)setClearClipboardEnabled:(BOOL)clearClipboardEnabled {
    [userDefaults setBool:clearClipboardEnabled forKey:CLEAR_CLIPBOARD_ENABLED];
}

- (NSInteger)clearClipboardTimeout {
    return clearClipboardTimeoutValues[[userDefaults integerForKey:CLEAR_CLIPBOARD_TIMEOUT]];
}

- (NSInteger)clearClipboardTimeoutIndex {
    return [userDefaults integerForKey:CLEAR_CLIPBOARD_TIMEOUT];
}

- (NSInteger)getInternalVersion {
    return internalVersionValues[[userDefaults integerForKey:INTERNAL_VERSION]];
}

- (void)setInternalVersion:(NSInteger)internalVersion {
    [userDefaults setInteger:internalVersion forKey:INTERNAL_VERSION];
}

- (void)setClearClipboardTimeoutIndex:(NSInteger)clearClipboardTimeoutIndex {
    [userDefaults setInteger:clearClipboardTimeoutIndex forKey:CLEAR_CLIPBOARD_TIMEOUT];
}

- (BOOL)webBrowserIntegrated {
    return [userDefaults boolForKey:WEB_BROWSER_INTEGRATED];
}

- (void)setWebBrowserIntegrated:(BOOL)webBrowserIntegrated {
    [userDefaults setBool:webBrowserIntegrated forKey:WEB_BROWSER_INTEGRATED];
}

- (NSInteger)pwGenLength {
    return [userDefaults integerForKey:PW_GEN_LENGTH];
}

- (void)setPwGenLength:(NSInteger)pwGenLength {
    [userDefaults setInteger:pwGenLength forKey:PW_GEN_LENGTH];
}

- (NSInteger)pwGenCharSets {
    return [userDefaults integerForKey:PW_GEN_CHAR_SETS];
}

- (void)setPwGenCharSets:(NSInteger)pwGenCharSets {
    [userDefaults setInteger:pwGenCharSets forKey:PW_GEN_CHAR_SETS];
}

@end
