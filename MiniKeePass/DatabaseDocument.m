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

#import "DatabaseDocument.h"
#import "AppDelegate.h"
#import "AppSettings.h"
#import "MBProgressHUD.h"


@interface DatabaseDocument ()
#ifdef USE_KDB
@property (nonatomic, strong) KdbPassword *kdbPassword;
#else
@property (nonatomic, strong) KPKCompositeKey *kpkkey;
#endif
@end

@implementation DatabaseDocument

- (id)initWithFilename:(NSString *)filename password:(NSString *)password keyFile:(NSString *)keyFile
{
    self = [super init];
    if (self) {
        if (password == nil && keyFile == nil) {
            @throw [NSException exceptionWithName:@"IllegalArgument"
                                           reason:NSLocalizedString(@"No password or keyfile specified", nil)
                                         userInfo:nil];
        }

        self.filename = filename;
        
       
#ifdef USE_KDB
        
        NSStringEncoding passwordEncoding = [[AppSettings sharedInstance] passwordEncoding];
        self.kdbPassword = [[KdbPassword alloc] initWithPassword:password
                                                passwordEncoding:passwordEncoding
                                                         keyFile:keyFile];

        self.kdbTree = [KdbReaderFactory load:self.filename withPassword:self.kdbPassword];
#else
            
        self.kpkkey = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithPassword:password]]];
        
        NSData *keyFileData = nil;
       
        
        if(keyFile != nil)
           keyFileData =  [self _loadDataBase:keyFile];
        
        if(keyFileData !=nil)
            [self.kpkkey addKey:[KPKKey keyWithKeyFileData:keyFileData]];
       
        NSData *data = [self _loadDataBase:self.filename];// extension:@"kdb"];
        if(data ==nil)
            @throw [NSException exceptionWithName:@"IllegalData"
                                           reason:NSLocalizedString(@"Wrong Databae Data", nil)
                                         userInfo:nil];
        self.kdbTree = [[KPKTree alloc] initWithData:data key:self.kpkkey error:NULL];
        
          
            
       
              
            
        
        if(self.kdbTree == nil){
            
            @throw [NSException exceptionWithName:@"IllegalData"
                                           reason:NSLocalizedString(@"Passwords do not match", nil)
                                         userInfo:nil];
            
        }
        
        /*KPKMetaData *meta = self.kdbTree.metaData;
        if(meta!=nil)
        {
            NSLog(@"%@",meta);
        }*/
        
#endif
    }
    return self;
}

- (NSData *)_loadDataBase:(NSString *)name{
  self.url = [NSURL fileURLWithPath:name];
  return [NSData dataWithContentsOfURL:self.url];
}


- (NSData *)_loadDataBase:(NSString *)name extension:(NSString *)extension {
    
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  NSURL *url = [myBundle URLForResource:name withExtension:extension];
  return [NSData dataWithContentsOfURL:url];
}

- (NSString *)getFileFormat
{
    NSData *fileData = [NSData dataWithContentsOfURL:self.url];
    if(!fileData) {
      return NSLocalizedString(@"UNKNOWN_FORMAT_FILE_NOT_SAVED_YET", "Database format is unknown since the file is not saved yet");
    }
    else {
      KPKFileVersion version = [[KPKFormat sharedFormat] fileVersionForData:fileData];
      NSDictionary *nameMappings = @{
                                     @(KPKDatabaseFormatKdb): @"Kdb",
                                     @(KPKDatabaseFormatKdbx): @"Kdbx",
                                     @(KPKDatabaseFormatUnknown): NSLocalizedString(@"UNKNOWN_FORMAT", "Unknown database format.")
                                     };
      
      NSUInteger mayor = (version.version >> 16);
      NSUInteger minor = (version.version & 0xFFFF);
      
        return [NSString stringWithFormat:@"%@ (Version %ld.%ld)", nameMappings[@(version.format)], mayor, minor];
        
    }
}


- (void)save {
    
#ifdef USE_KDB
    [KdbWriterFactory persist:self.kdbTree file:self.filename withPassword:self.kdbPassword];
#else
    
        NSError __autoreleasing *error = nil;
        NSData *data = [self.kdbTree encryptWithKey:self.kpkkey format:KPKDatabaseFormatKdbx error:&error];
        
        [data writeToFile:self.filename atomically:YES];
        
        
        [[AppSettings sharedInstance] setfileneedsBackup:self.filename];
    
#endif
    
   /* if (![[AppSettings sharedInstance] backupDisabled]) {
        BOOL cloudIsAvailable = [[iCloud sharedCloud] checkCloudAvailability];
        if (cloudIsAvailable) {
            //YES
            NSLog(@"Apple iCloud available document update will start immediataly");
            [[iCloud sharedCloud] saveAndCloseDocumentWithName:self.filename withContent:[NSData data] completion:^(UIDocument *cloudDocument, NSData *documentData, NSError *error) {
                if (error == nil) {
                    // Code here to use the UIDocument or NSData objects which have been passed with the completion handler
                    NSLog(@"iCloud Error:%@",error);
                }
            }];
        }else{
            NSLog(@"Apple iCloud not available on this device");
        }
    }*/

}


+ (void)searchGroup:(KPKGroup *)group searchText:(NSString *)searchText results:(NSMutableArray *)results {
    for (KPKEntry *entry in group.entries) {
        if ([self matchesEntry:entry searchText:searchText]) {
            [results addObject:entry];
        }
    }

    for (KPKGroup *g in group.groups) {
        if (![g.title isEqualToString:@"Backup"] && ![g.title isEqualToString:NSLocalizedString(@"Backup", nil)]) {
            [self searchGroup:g searchText:searchText results:results];
        }
    }
}

+ (BOOL)matchesEntry:(KPKEntry *)entry searchText:(NSString *)searchText {
    BOOL searchTitleOnly = [[AppSettings sharedInstance] searchTitleOnly];

    if ([entry.title rangeOfString:searchText options:NSCaseInsensitiveSearch].length > 0) {
        return YES;
    }
    if (!searchTitleOnly) {
        if ([entry.username rangeOfString:searchText options:NSCaseInsensitiveSearch].length > 0) {
            return YES;
        }
        if ([entry.url rangeOfString:searchText options:NSCaseInsensitiveSearch].length > 0) {
            return YES;
        }
        if ([entry.notes rangeOfString:searchText options:NSCaseInsensitiveSearch].length > 0) {
            return YES;
        }
    }
    return NO;
}

@end
