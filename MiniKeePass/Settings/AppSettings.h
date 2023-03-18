/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
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

#import <Foundation/Foundation.h>

@interface AppSettings : NSObject

+ (AppSettings *)sharedInstance;

- (NSDate *)exitTime;
- (void)setExitTime:(NSDate *)exitTime;

- (BOOL)darkEnabled;
- (void)setDarkEnabled:(BOOL)darkEnabled;

- (NSInteger)autoFillMethod;
- (void)setautoFillMethod:(NSInteger)autoFillMethod;

- (NSInteger)cloudType;
- (void)setCloudType:(NSInteger)cloudType;

- (BOOL)pinEnabled;
- (void)setPinEnabled:(BOOL)pinEnabled;

- (BOOL)analyseDataEnabled;
- (void)setAnalyseDataEnabled:(BOOL)analyseDataEnabled;

- (BOOL)userNotify;
- (void)setUserNotify:(BOOL)userNotify;
    
- (NSString *)pin;
- (void)setPin:(NSString *)pin;

- (NSInteger)pinFailedAttempts;
- (void)setPinFailedAttempts:(NSInteger)pinFailedAttempts;

- (BOOL)touchIdEnabled;
- (void)setTouchIdEnabled:(BOOL)touchIdEnabled;

- (BOOL)deleteOnFailureEnabled;
- (void)setDeleteOnFailureEnabled:(BOOL)deleteOnFailureEnabled;

- (NSInteger)deleteOnFailureAttempts;
- (NSInteger)deleteOnFailureAttemptsIndex;
- (void)setDeleteOnFailureAttemptsIndex:(NSInteger)deleteOnFailureAttemptsIndex;

- (BOOL)closeEnabled;
- (void)setCloseEnabled:(BOOL)closeEnabled;

- (NSInteger)closeTimeout;
- (NSInteger)closeTimeoutIndex;
- (void)setCloseTimeoutIndex:(NSInteger)closeTimeoutIndex;

- (BOOL)rememberPasswordsEnabled;
- (void)setRememberPasswordsEnabled:(BOOL)rememberPasswordsEnabled;

- (BOOL)hidePasswords;
- (void)setHidePasswords:(BOOL)hidePasswords;

- (BOOL)sortAlphabetically;
- (void)setSortAlphabetically:(BOOL)sortAlphabetically;

- (BOOL)searchTitleOnly;
- (void)setSearchTitleOnly:(BOOL)searchTitleOnly;

- (NSStringEncoding)passwordEncoding;
- (NSInteger)passwordEncodingIndex;
- (void)setPasswordEncodingIndex:(NSInteger)passwordEncodingIndex;

- (BOOL)clearClipboardEnabled;
- (void)setClearClipboardEnabled:(BOOL)clearClipboardEnabled;

- (BOOL)autofillEnabled;
- (void)setAutofillEnabled:(BOOL)autofillEnabled;

- (BOOL)backupEnabled;
- (void)setBackupEnabled:(BOOL)backupEnabled;

- (BOOL)backupFirstTime;
- (void)setBackupFirstTime:(BOOL)backupFirstTime;

- (NSString *)cloudURL;
- (void)setCloudURL:(NSString *)cloudURL;

- (NSString *)fileneedsBackup;
- (void)setfileneedsBackup:(NSString *)fileneedsBackup;

- (NSString *)cloudUser;
- (void)setCloudUser:(NSString *)cloudUser;

- (NSString *)refreshToken;
- (void)setRefreshToken:(NSString *)refreshToken;

- (NSString *)cloudPWD;
- (void)setCloudPWD:(NSString *)cloudPWD;

- (NSInteger)clearClipboardTimeout;
- (NSInteger)clearClipboardTimeoutIndex;
- (void)setClearClipboardTimeoutIndex:(NSInteger)clearClipboardTimeoutIndex;

- (NSInteger)getInternalVersion;
- (void)setInternalVersion:(NSInteger)internalVersion;

- (BOOL)webBrowserIntegrated;
- (void)setWebBrowserIntegrated:(BOOL)webBrowserIntegrated;

- (NSInteger)pwGenLength;
- (void)setPwGenLength:(NSInteger)pwGenLength;

- (NSInteger)pwGenCharSets;
- (void)setPwGenCharSets:(NSInteger)pwGenCharSets;

- (NSString *)defaultDB;
- (void)setDefaultDB:(NSString *)defdb;
@end
