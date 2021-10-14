/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
 * Mdified by Frank Hausmann 2020-2021
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

#import "AppDelegate.h"
#import "EntryViewController.h"
#import "AppSettings.h"
#import "DatabaseManager.h"
#import "KeychainUtils.h"
//#import "LockScreenManager.h"
#import "IOSKeePass-Swift.h"
#import "KTouchIDAuthentication.h"


@interface AppDelegate ()

@property (nonatomic, strong) FilesViewController *filesViewController;;
@property (nonatomic, strong) UINavigationController *navigationController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _databaseDocument = nil;
    
    // Store references to base view controllers
    self.navigationController = (UINavigationController *) self.window.rootViewController;
    self.filesViewController = (FilesViewController *) self.navigationController.topViewController;
    
    // Add a pasteboard notification listener to support clearing the clipboard
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handlePasteboardNotification:)
                               name:UIPasteboardChangedNotification
                             object:nil];
    
   
    [self checkFileProtection];
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Check file protection
    [self checkFileProtection];
}

-(void)applicationDidEnterBackground:(UIApplication *)application {
        
        if ([[AppSettings sharedInstance] closeEnabled]) {
            //Get Time
            
            UIApplication  *app = [UIApplication sharedApplication];
            self.bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
                [app endBackgroundTask:self.bgTask];
            }];
            NSLog(@"Closed enabled timout:30sec");
            self.silenceTimer = [NSTimer scheduledTimerWithTimeInterval:[[AppSettings sharedInstance] closeTimeout] target:self
            selector:@selector(startShutdown) userInfo:nil repeats:YES];
        }
}

- (void)startShutdown{
    NSLog(@"App Closedatabase time reached");
    // Get the application delegate
    AppDelegate *appDelegate = [AppDelegate getDelegate];
    [appDelegate closeDatabase];
    [self.silenceTimer invalidate];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [self importUrl:url];

    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
     [self importUrl:url];
    
    return YES;
}

+ (AppDelegate *)getDelegate {
    return [[UIApplication sharedApplication] delegate];
}


+ (NSString *)documentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

+ (NSURL *)documentsDirectoryUrl {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *urls = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    return [urls firstObject];
}
/*- (void)methodAWithCompletion:(void (^) (BOOL success))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, kNilOptions), ^{

        // go do something asynchronous...

        dispatch_async(dispatch_get_main_queue(), ^{

            completion(ifThingWorked)

        });
    });
}*/
- (void)buildAutoFillIfNeeded:(NSString *)dbname
{
    if (_databaseDocument == nil) {
       
    }
    AppSettings *appSettings = [AppSettings sharedInstance];
    
    if(appSettings.autoFillMethod == 1 && appSettings.autofillEnabled == YES)
    {
        //Dump all Entries
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Autofill request", nil) message:NSLocalizedString(@"I hereby confirm that my passwords in this DB will be made available to the IOS Autofill mechanism.", nil)  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Accept", nil) style:UIAlertActionStyleDefault
                handler:^(UIAlertAction * action) {
                
                
                NSLog(@"%@",self->_databaseDocument.kdbTree.metaData.customData.description);

                    [AppDelegate showGlobalProgressHUDWithTitle:@"AutoFill build..."];
                
                    AutoFillDB *adb = [[AutoFillDB alloc] init];
                    for(KPKEntry *entry in self->_databaseDocument.kdbTree.allEntries) {
                        //NSLog(@"%@",entry.title);
                        NSString *u;
                        if(entry.url.length <=1)
                            u = entry.title;
                        else
                            u = entry.url;
                        
                        [adb InsertEntryWithUser:entry.username secret:entry.password url:u];
                    }
               
                NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
                 [dateFormatter setDateFormat:@"YYYYMMddHHmmss"];
                [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
                NSDate *currentDate = [NSDate date];
                [dateFormatter stringFromDate:currentDate];
               
                
                [adb KeePassDBSyncWithDbname:dbname syncdate:[dateFormatter stringFromDate:currentDate]];//(dbname: dname, syncdate: [dateFormatter stringFromDate:currentDate])
                [AppDelegate dismissGlobalHUD];
                
                   
                
            }];
            
            
            UIAlertAction* leaveAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault
                handler:^(UIAlertAction * action) {}];

            [alert addAction:defaultAction];
            [alert addAction:leaveAction];
            
           
            [self.topViewController presentViewController:alert animated:YES completion:nil];
        
             
             
                });
             });
       
    }
    
    
}

- (DatabaseDocument *)getOpenDataBase {
    
    if (_databaseDocument == nil) {
        return nil;
    }
    
    return _databaseDocument;
}
    
- (void)importUrl:(NSURL *)url {
    // Get the filename
    NSString *filename = [url lastPathComponent];

    // Get the full path of where we're going to move the file
    NSString *documentsDirectory = [AppDelegate documentsDirectory];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];

    // Move input file into documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    if ([fileManager fileExistsAtPath:path isDirectory:&isDirectory]) {
        if (isDirectory) {
            // Should not have been passed a directory
            return;
        } else {
            [fileManager removeItemAtPath:path error:nil];
        }
    }
    [fileManager moveItemAtURL:url toURL:[NSURL fileURLWithPath:path] error:nil];

    // Make sure the file is writable.
    if (![fileManager isWritableFileAtPath:path]) {
        [fileManager setAttributes:@{NSFilePosixPermissions:@0711} ofItemAtPath:path error:nil];
    }
    
    // Set file protection on the new file
    [fileManager setAttributes:@{NSFileProtectionKey:NSFileProtectionComplete} ofItemAtPath:path error:nil];

    // Delete the Inbox folder if it exists
    [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:@"Inbox"] error:nil];

    [self.filesViewController updateFiles];
    [self.filesViewController.tableView reloadData];
}

- (void)setDatabaseDocument:(DatabaseDocument *)newDatabaseDocument {
    if (_databaseDocument != nil) {
        [self closeDatabase];
    }
    
    _databaseDocument = newDatabaseDocument;
    
    UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
    FilesViewController * filesViewController = navController.viewControllers.firstObject;
    
    [filesViewController performSegueWithIdentifier:@"fileOpened" sender:self];
}

- (void)closeDatabase {
    // Close any open database views
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    _databaseDocument = nil;
}

- (void)deleteKeychainData {
    // Reset some settings
    AppSettings *appSettings = [AppSettings sharedInstance];
    [appSettings setPinFailedAttempts:0];
    [appSettings setPinEnabled:NO];
    [appSettings setTouchIdEnabled:NO];

    // Delete the PIN from the keychain
    [KeychainUtils deleteStringForKey:@"PIN" andServiceName:KEYCHAIN_PIN_SERVICE];

    // Delete all database passwords from the keychain
    
    [KeychainUtils deleteAllForServiceName:KEYCHAIN_PASSWORDS_SERVICE];
    [KeychainUtils deleteAllForServiceName:KEYCHAIN_KEYFILES_SERVICE];
}

- (void)deleteAllData {
    // Close the current database
    [self closeDatabase];

    // Delete data stored in system keychain
    [self deleteKeychainData];

    // Get the files in the Documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = [AppDelegate documentsDirectory];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    // Delete all the files in the Documents directory
    for (NSString *file in files) {
        [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:file] error:nil];
    }
}

- (UIViewController *)topViewController{
  return [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
  if ([rootViewController isKindOfClass:[UINavigationController class]]) {
    UINavigationController *navigationController = (UINavigationController *)rootViewController;
    return [self topViewController:[navigationController.viewControllers lastObject]];
  }
  if ([rootViewController isKindOfClass:[UITabBarController class]]) {
    UITabBarController *tabController = (UITabBarController *)rootViewController;
    return [self topViewController:tabController.selectedViewController];
  }
  if (rootViewController.presentedViewController) {
    return [self topViewController:rootViewController];
  }
  return rootViewController;
}

- (void)checkFileProtection {
    // Get the document's directory
    NSString *documentsDirectory = [AppDelegate documentsDirectory];

    // Get the contents of the documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];

    // Check all files to see if protection is enabled
    for (NSString *file in dirContents) {
        if (![file hasPrefix:@"."]) {
            NSString *path = [documentsDirectory stringByAppendingPathComponent:file];

            BOOL dir = NO;
            [fileManager fileExistsAtPath:path isDirectory:&dir];
            if (!dir) {
                // Make sure file protecten is turned on
                NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:nil];
                NSString *fileProtection = [attributes valueForKey:NSFileProtectionKey];
                if (![fileProtection isEqualToString:NSFileProtectionComplete]) {
                    [fileManager setAttributes:@{NSFileProtectionKey:NSFileProtectionComplete} ofItemAtPath:path error:nil];
                }
            }
        }
    }
}

+ (MBProgressHUD *)showGlobalProgressHUDWithTitle:(NSString *)title {
    UIWindow *window = [[[UIApplication sharedApplication] windows] lastObject];
    
    if (![[AppSettings sharedInstance] darkEnabled]) {
        window.overrideUserInterfaceStyle=UIUserInterfaceStyleLight;
    }else{
        window.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
    }
    //window.overrideUserInterfaceStyle = .dark;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
    hud.label.text = title;
    hud.backgroundView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.backgroundView.color = [UIColor colorWithRed:0.2f green:0.2f blue:0.5f alpha:0.2f];
    hud.contentColor = [UIColor systemBlueColor]; 
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeIndeterminate;
    return hud;
}

+ (void)dismissGlobalHUD {
    UIWindow *window = [[[UIApplication sharedApplication] windows] lastObject];
    [MBProgressHUD hideHUDForView:window animated:YES];
}

- (void)handlePasteboardNotification:(NSNotification *)notification {
    // Check if the clipboard has any contents
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if (pasteboard.string == nil || [pasteboard.string isEqualToString:@""]) {
        return;
    }
    
    AppSettings *appSettings = [AppSettings sharedInstance];

    // Check if the clearing the clipboard is enabled
    if ([appSettings clearClipboardEnabled]) {
        // Get the "version" of the pasteboard contents
        NSInteger pasteboardVersion = pasteboard.changeCount;

        // Get the clear clipboard timeout (in seconds)
        NSInteger clearClipboardTimeout = [appSettings clearClipboardTimeout];

        UIApplication *application = [UIApplication sharedApplication];

        // Initiate a background task
        __block UIBackgroundTaskIdentifier bgTask;
        bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            // End the background task
            [application endBackgroundTask:bgTask];
        }];
        
        // Start the long-running task and return immediately.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Sleep until it's time to clean the clipboard
            [NSThread sleepForTimeInterval:clearClipboardTimeout];
            
            // Clear the clipboard if it hasn't changed
            if (pasteboardVersion == pasteboard.changeCount) {
                pasteboard.string = @"";
            }
            
            // End the background task
            [application endBackgroundTask:bgTask];
        });
    }
}

@end
