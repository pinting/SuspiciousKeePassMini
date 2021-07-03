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

#import <UIKit/UIKit.h>
#import "DatabaseDocument.h"
#import "MBProgressHUD.h"

@interface AppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) DatabaseDocument *databaseDocument;
@property (nonatomic, retain) NSTimer *silenceTimer;
@property (nonatomic) UIBackgroundTaskIdentifier bgTask;

+ (NSTimer *)silenceTimer;
+ (UIBackgroundTaskIdentifier)bgTask;
+ (AppDelegate *)getDelegate;
+ (NSString *)documentsDirectory;
+ (NSURL *)documentsDirectoryUrl;
+ (MBProgressHUD *)showGlobalProgressHUDWithTitle:(NSString *)title;
+ (void)dismissGlobalHUD;

- (DatabaseDocument *)getOpenDataBase;
- (void)buildAutoFillIfNeeded:(NSString *)dbname;
- (void)closeDatabase;
- (void)deleteAllData;
- (UIViewController *)topViewController;


@end
