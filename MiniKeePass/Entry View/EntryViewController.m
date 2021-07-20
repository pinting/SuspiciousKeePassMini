/*
 * Copyright 2011-2013 Jason Rush and John Flanagan. All rights reserved.
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

#import "EntryViewController.h"
//#import "Kdb4Node.h"
#import "AppSettings.h"
#import "ImageFactory.h"
#import "IOSKeePass-Swift.h"
#import "MBProgressHUD.h"

//#import "AutoFillKeyChain.h"


#define SECTION_HEADER_HEIGHT 46.0f

enum {
    SECTION_DEFAULT_FIELDS,
    SECTION_CUSTOM_FIELDS,
    SECTION_COMMENTS,
    NUM_SECTIONS
};

@interface EntryViewController() {
    TextFieldCell *titleCell;
    TextFieldCell *usernameCell;
    TextFieldCell *passwordCell;
    TextFieldCell *urlCell;
    TextViewCell *commentsCell;
    TextFieldCell *otpCell;
    TextFieldCell *autofillCell;
    TextFieldCell *filesCell;
}

@property (nonatomic) BOOL isKdb4;
@property (nonatomic) UIVisualEffectView *blurEffectView;
@property (nonatomic, readonly) NSMutableArray *editingStringFields;
@property (nonatomic, readonly) NSArray *entryStringFields;
@property (nonatomic, readonly) NSArray *currentStringFields;

@property (nonatomic, readonly) NSArray *filledCells;
@property (nonatomic, readonly) NSArray *defaultCells;

@property (nonatomic, readonly) NSArray *cells;

@end

static NSString *TextFieldCellIdentifier = @"TextFieldCell";

@implementation EntryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"TextFieldCell" bundle:nil] forCellReuseIdentifier:TextFieldCellIdentifier];
    
    
    titleCell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
    titleCell.style = TextFieldCellStyleTitle;
    titleCell.title = NSLocalizedString(@"Title", nil);
    titleCell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    titleCell.titleLabel.adjustsFontForContentSizeCategory = true;
    titleCell.delegate = self;
    titleCell.textField.placeholder = NSLocalizedString(@"Title", nil);
    titleCell.textField.enabled = NO;
    titleCell.textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    titleCell.textField.adjustsFontForContentSizeCategory = true;
    
    titleCell.textField.text = self.entry.title;
    [titleCell.editAccessoryButton addTarget:self action:@selector(imageButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self setSelectedImageIndex:self.entry.iconId];
    
    usernameCell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
    usernameCell.style = TextFieldCellStylePlain;
    usernameCell.title = NSLocalizedString(@"Username", nil);
    usernameCell.delegate = self;
    usernameCell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    usernameCell.titleLabel.adjustsFontForContentSizeCategory = true;
    usernameCell.textField.placeholder = NSLocalizedString(@"Username", nil);
    usernameCell.textField.enabled = NO;
    usernameCell.textField.text = self.entry.username;
    usernameCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    usernameCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    usernameCell.textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    usernameCell.textField.adjustsFontForContentSizeCategory = true;
    
    
    passwordCell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
    passwordCell.style = TextFieldCellStylePassword;
    passwordCell.title = NSLocalizedString(@"Password", nil);
    passwordCell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    passwordCell.titleLabel.adjustsFontForContentSizeCategory = true;
    passwordCell.delegate = self;
    passwordCell.textField.placeholder = NSLocalizedString(@"Password", nil);
    passwordCell.textField.enabled = NO;
    passwordCell.textField.text = self.entry.password;
    passwordCell.textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    passwordCell.textField.adjustsFontForContentSizeCategory = true;
    
    [passwordCell.accessoryButton addTarget:self action:@selector(showPasswordPressed) forControlEvents:UIControlEventTouchUpInside];
    [passwordCell.editAccessoryButton addTarget:self action:@selector(generatePasswordPressed) forControlEvents:UIControlEventTouchUpInside];
    
    urlCell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
    urlCell.style = TextFieldCellStyleUrl;
    urlCell.title = NSLocalizedString(@"URL", nil);
    urlCell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    urlCell.titleLabel.adjustsFontForContentSizeCategory = true;
    urlCell.delegate = self;
    urlCell.textField.placeholder = NSLocalizedString(@"URL", nil);
    urlCell.textField.enabled = NO;
    urlCell.textField.returnKeyType = UIReturnKeyDone;
    urlCell.textField.text = self.entry.url;
    urlCell.textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    urlCell.textField.adjustsFontForContentSizeCategory = true;
    
    [urlCell.accessoryButton addTarget:self action:@selector(openUrlPressed) forControlEvents:UIControlEventTouchUpInside];
    
    commentsCell = [[TextViewCell alloc] init];
    commentsCell.textView.editable = NO;
    commentsCell.textView.text = self.entry.notes;
    commentsCell.textView.scrollEnabled = TRUE;
    commentsCell.textView.userInteractionEnabled = TRUE;
    commentsCell.parentView = self;
    commentsCell.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    commentsCell.textView.adjustsFontForContentSizeCategory = true;
   
    
    otpCell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
    otpCell.style = TextFieldCellStyleOTP;
    otpCell.title = @"OTP";//NSLocalizedString(@"URL", nil);
    otpCell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    otpCell.titleLabel.adjustsFontForContentSizeCategory = true;
    otpCell.delegate = self;
    otpCell.textField.placeholder = @"OneTimePassword";//NSLocalizedString(@"URL", nil)
    otpCell.textField.enabled = NO;
    otpCell.textField.returnKeyType = UIReturnKeyDone;
    otpCell.textField.text = @"";
    [otpCell.editAccessoryButton addTarget:self action:@selector(openScanBarcodePressed) forControlEvents:UIControlEventTouchUpInside];
   
    autofillCell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
    autofillCell.style = TextFieldCellStyleAutoFill;
    autofillCell.title = @"AutoFill";//NSLocalizedString(@"URL", nil);
    autofillCell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    autofillCell.titleLabel.adjustsFontForContentSizeCategory = true;
    autofillCell.delegate = self;
    autofillCell.textField.placeholder = @"On or Off";//NSLocalizedString(@"URL", nil)
    autofillCell.textField.enabled = NO;
    autofillCell.textField.returnKeyType = UIReturnKeyDone;
    autofillCell.textField.text = @"";
    autofillCell.textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    autofillCell.textField.adjustsFontForContentSizeCategory = true;
    
    filesCell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
    filesCell.style = TextFieldCellStylFiles;
    filesCell.title = NSLocalizedString(@"Attachments", nil);
    filesCell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    filesCell.titleLabel.adjustsFontForContentSizeCategory = true;
    filesCell.delegate = self;
    filesCell.textField.placeholder = NSLocalizedString(@"Files", nil);
    filesCell.textField.enabled = NO;
    filesCell.textField.returnKeyType = UIReturnKeyDone;
    filesCell.textField.text = @"";
    filesCell.textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    filesCell.textField.adjustsFontForContentSizeCategory = true;
    
    [filesCell.accessoryButton addTarget:self action:@selector(openFilesPressed) forControlEvents:UIControlEventTouchUpInside];
    
    if ([[AppSettings sharedInstance] autofillEnabled]) {
        autofillCell.editAutoFill.enabled = TRUE;
    }else{
        autofillCell.editAutoFill.enabled = FALSE;
    }
    
    
    
   // [autofillCell.editAutoFill addTarget:self action:@selector(Autofill) forControlEvents:UIControlEventTouchUpInside];
    
    _defaultCells = @[titleCell, usernameCell, passwordCell, urlCell,filesCell,autofillCell,otpCell];
    
    _editingStringFields = [NSMutableArray array];
    
    KPKEntry *kdb4Entry = (KPKEntry *)self.entry;
    
    if (self.isKdb4) {
        NSInteger bcount = kdb4Entry.binaries.count;
        if(bcount >= 0){
            NSString *tt = [[NSString alloc] initWithFormat:@"%ld %@",bcount, NSLocalizedString(@"Attachments", nil)];
            filesCell.textField.text = tt;
        }
        for (NSInteger j = 0; j < bcount; j++) {
            KPKBinary *bf = kdb4Entry.binaries[j];
            NSLog(@"Binarie %@ is valid",bf.name);
          
        }
        NSInteger count = kdb4Entry.attributes.count;
        for (NSInteger i = 0; i < count; i++) {
            KPKAttribute *sf = kdb4Entry.attributes[i];
            if ([sf.key isEqualToString:@"OTPURL:"])
            {
                
                NSURL *url = [[NSURL alloc] initWithString:sf.value];
                Token *tok = [[Token alloc] initWithUrl:url secret:nil error:nil];
                if(tok == nil)
                    break;
                //otpCell.textField.enabled = YES;
                otpCell.textField.text = tok.currentPasswordmoreReadable;
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                   while(1){
                        
                        [NSThread sleepForTimeInterval:1.0f];
                    
                    // update UI on the main thread
                    dispatch_async(dispatch_get_main_queue(), ^{
                       [self doOntimeRefresh:tok];
                    });
                    }
                    
                });
            }
            
            if ([sf.key isEqualToString:@"AutoFill"])
            {
                if([sf.value isEqualToString:@"YES"]){
                    autofillCell.editAutoFill.on = YES;
                }
            }
        }
    
    }
    /*UIBlurEffect *blurEffect = [[UIBlurEffect alloc] init];// (style: UIBlurEffect.Style.light)
    _blurEffectView = [[UIVisualEffectView alloc] init]; // [effect: blurEffect)
    _blurEffectView.effect = blurEffect;
    _blurEffectView.frame = self.view.bounds;
    _blurEffectView.autoresizingMask = self.view.autoresizingMask;
    //.flexibleWidth, self.view.autoresizingMask.flexibleHeight];
    _blurEffectView.tag = 1801;
    // Add a pasteboard notification listener to support clearing the clipboard*/
   
  
}

- (void)appCameToForeground:(NSNotification *)notification {
    NSLog(@"EntryViewController enters foreground");
     
}

- (void)didEnterBackgroundNotification:(NSNotification *)notification {
    NSLog(@"EntryViewController enters background");
    
    /*if ([[AppSettings sharedInstance] closeEnabled]) {
        //Get Time
        
        UIApplication  *app = [UIApplication sharedApplication];
        self.bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            [app endBackgroundTask:self.bgTask];
        }];
        NSLog(@"Closed enabled timout:30sec");
        self.silenceTimer = [NSTimer scheduledTimerWithTimeInterval:[[AppSettings sharedInstance] closeTimeout] target:self
        selector:@selector(startShutdown) userInfo:nil repeats:YES];
    }*/
    
    if ([[AppSettings sharedInstance] pinEnabled]) {
        [self.navigationController popViewControllerAnimated:YES];

    }
    
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    
    // Hide the toolbar
    [self.navigationController setToolbarHidden:YES animated:animated];

    // Add listeners to the keyboard
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [notificationCenter addObserver:self
                            selector:@selector(didEnterBackgroundNotification:)
                               name:UISceneDidEnterBackgroundNotification
                              object:nil];
    [notificationCenter addObserver:self
                            selector:@selector(appCameToForeground:)
                                name:UISceneWillEnterForegroundNotification
                              object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Show the toolbar again
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.isNewEntry) {
        [self setEditing:YES animated:NO];
        [titleCell.textField becomeFirstResponder];
        self.isNewEntry = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // Hide the password HUD if it's visible
    [MBProgressHUD hideHUDForView:self.view animated:NO];

    // Remove listeners from the keyboard
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationWillResignActive:(id)sender {
    // Resign first responder to prevent password being in sight and UI glitchs
    [titleCell.textField resignFirstResponder];
    [usernameCell.textField resignFirstResponder];
    [passwordCell.textField resignFirstResponder];
    [urlCell.textField resignFirstResponder];
    [filesCell.textField resignFirstResponder];
    [commentsCell.textView resignFirstResponder];
    [otpCell.textField resignFirstResponder];
}

- (void)doOntimeRefresh:(Token*)tok {
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
     [dateFormatter setDateFormat:@"ss"];
     // or @"yyyy-MM-dd hh:mm:ss a" if you prefer the time with AM/PM
     //NSLog(@"%@",[dateFormatter stringFromDate:[NSDate date]]);
    
         NSInteger sec = [[dateFormatter stringFromDate:[NSDate date]] integerValue];
         
        if(sec >= 30){
            NSString *tt = [[NSString alloc] initWithFormat:@"%@ (%ldsec)",tok.currentPasswordmoreReadable,60-sec];
            otpCell.textField.text = tt;// tok.currentPassword;
            //NSLog(@"OTP %d valid",60-sec);
         }else{
             NSString *tt = [[NSString alloc] initWithFormat:@"%@ (%ldsec)",tok.currentPasswordmoreReadable,30-sec];
             otpCell.textField.text = tt;// tok.currentPassword;
             //NSLog(@"OTP %d valid",30-sec);
         }
    
        
      
    
}
- (void)setEntry:(KPKEntry *)e {
    _entry = e;
    self.isKdb4 = [self.entry isKindOfClass:[KPKEntry class]];

    // Update the fields
    self.title = self.entry.title;
    titleCell.textField.text = self.entry.title;
    [self setSelectedImageIndex:self.entry.iconId];
    usernameCell.textField.text = self.entry.username;
    passwordCell.textField.text = self.entry.password;
    urlCell.textField.text = self.entry.url;
    commentsCell.textView.text = self.entry.notes;
    //otpCell.textField.text = @"123 456";
}

- (NSArray *)cells {
    return self.editing ? self.defaultCells : self.filledCells;
}

- (NSArray *)filledCells {
    NSMutableArray *filledCells = [NSMutableArray arrayWithCapacity:self.defaultCells.count];
    for (TextFieldCell *cell in self.defaultCells) {
        if (cell.textField.text.length > 0) {
            [filledCells addObject:cell];
        }
    }
    return filledCells;
}

- (NSArray *)currentStringFields {
    if (!self.isKdb4) {
        return nil;
    }

    if (self.editing) {
        return self.editingStringFields;
    } else {
        return ((KPKEntry *)self.entry).customAttributes;
        //((Kdb4Entry *)self.entry).stringFields;
    }
}

- (NSArray *)entryStringFields {
    if (self.isKdb4) {
        KPKEntry *entry = (KPKEntry *)self.entry;
        return entry.customAttributes;
    } else {
        return nil;
    }
}

- (void)cancelPressed {
    [self setEditing:NO animated:YES canceled:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
   
    [self setEditing:editing animated:animated canceled:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated canceled:(BOOL)canceled {
    [super setEditing:editing animated:animated];
    
    
    // Ensure that all updates happen at once
    [self.tableView beginUpdates];

    if (editing == NO) {
        if (canceled) {
            [self setEntry:self.entry];
        } else {
            
            self.entry.title = titleCell.textField.text;
            self.entry.iconId = self.selectedImageIndex;
            self.entry.username = usernameCell.textField.text;
            self.entry.password = passwordCell.textField.text;
            self.entry.url = urlCell.textField.text;
            self.entry.notes = commentsCell.textView.text;
            self.entry.timeInfo.modificationDate  = [NSDate date];

            if (self.isKdb4) {
                // Ensure any textfield currently being edited is saved
                NSInteger count = [self.tableView numberOfRowsInSection:SECTION_CUSTOM_FIELDS] - 1;
                for (NSInteger i = 0; i < count; i++) {
                    TextFieldCell *cell = (TextFieldCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:SECTION_CUSTOM_FIELDS]];
                    
                    [cell.textField resignFirstResponder];
                }
 
                KPKEntry *kdb4Entry = (KPKEntry *)self.entry;
                
                if ([[AppSettings sharedInstance] autofillEnabled]) {
                    AutoFillDB *adb = [[AutoFillDB alloc] init];
                   
                    NSString *u;
                    if(self.entry.url.length <=1)
                        u = self.entry.title;
                    else
                        u = self.entry.url;
                    
                    
                    if(autofillCell.editAutoFill.on == YES)
                    {
                       
                        
                        [adb AddOrUpdateEntryWithUser:self.entry.username secret:self.entry.password url:u];
                        
                        NSInteger count = kdb4Entry.attributes.count;
                        BOOL autofillfound = FALSE;
                        for (NSInteger i = 0; i < count; i++) {
                            KPKAttribute *sf = kdb4Entry.attributes[i];
                            if ([sf.key isEqualToString:@"AutoFill"])
                            {
                                sf.value = @"YES";
                                autofillfound = TRUE;
                            }
                        }
                        if(autofillfound == FALSE){
                            KPKAttribute *afill = [[KPKAttribute alloc] initWithKey:@"AutoFill" value:@"YES" isProtected:NO];
                            [self.editingStringFields addObject:afill];
                            
                        }  
                        
                    }else{
                        NSInteger count = kdb4Entry.attributes.count;
                        for (NSInteger i = 0; i < count; i++) {
                            KPKAttribute *sf = kdb4Entry.attributes[i];
                            if ([sf.key isEqualToString:@"AutoFill"])
                            {
                                sf.value = @"NO";
                            }
                        }
                       [adb RemoveEntryWithUser:self.entry.username url:u];
                    }
                }else{
                    //remove AutoFillDB
                    AutoFillDB *adb = [[AutoFillDB alloc] init];
                    [adb RemoveDB];
                    
                }
                
                
                for (id attr in kdb4Entry.customAttributes) {
                    // do something with object
                    //NSLog(@"%@",attr);
                    [self.entry removeCustomAttribute:attr];
                }
                
                for (id newattr in self.editingStringFields) {
                    // do something with object
                    //NSLog(@"%@",newattr);
                    [self.entry addCustomAttribute:newattr];
                }
                
               
                
                //Kdb4Entry *kdb4Entry = (Kdb4Entry *)self.entry;
                //[kdb4Entry.stringFields removeAllObjects];
                //kdb4Entry.customAttributes = [[NSArray alloc]init];
                //[kdb4Entry.customAttributes addObjectsFromArray:self.editingStringFields];
            }
            [AppDelegate showGlobalProgressHUDWithTitle:@"saving..."];
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                
                [[AppDelegate getDelegate].databaseDocument save];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [AppDelegate dismissGlobalHUD];
                        });
                    });
           
            
        }
    }

    // Index paths for cells to be added or removed
    NSMutableArray *paths = [NSMutableArray array];

    // Manage default cells
    for (TextFieldCell *cell in self.defaultCells) {
        cell.textField.enabled = editing;

        // Add empty cells to the list of cells that need to be added/deleted when changing between editing
        if (cell.textField.text.length == 0) {
            [paths addObject:[NSIndexPath indexPathForRow:[self.defaultCells indexOfObject:cell] inSection:0]];
        }
    }

    [self.editingStringFields removeAllObjects];
    [self.editingStringFields addObjectsFromArray:[self.entryStringFields copy]];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_CUSTOM_FIELDS] withRowAnimation:UITableViewRowAnimationFade];

    if (editing) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
        self.navigationItem.leftBarButtonItem = cancelButton;

        commentsCell.textView.editable = YES;
        
        //commentsCell.textView.userInteractionEnabled = true;

        [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
    } else {
        self.navigationItem.leftBarButtonItem = nil;

        commentsCell.textView.editable = NO;

        [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
    }

    // Commit all updates
    [self.tableView endUpdates];
   
}

#pragma mark - TextFieldCell delegate

- (void)textFieldCellDidEndEditing:(TextFieldCell *)textFieldCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:textFieldCell];

    switch (indexPath.section) {
        case SECTION_DEFAULT_FIELDS: {
            if (textFieldCell.style == TextFieldCellStyleTitle) {
                self.title = textFieldCell.textField.text;
            }
            break;
        }
        case SECTION_CUSTOM_FIELDS: {
            if (indexPath.row < self.editingStringFields.count) {
                KPKAttribute *stringField = [self.editingStringFields objectAtIndex:indexPath.row];
                stringField.value = textFieldCell.textField.text;
            }
            break;
        }
        default:
            break;
    }
}

- (void)textFieldCellWillReturn:(TextFieldCell *)textFieldCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:textFieldCell];

    switch (indexPath.section) {
        case SECTION_DEFAULT_FIELDS: {
            NSInteger nextIndex = indexPath.row + 1;
            if (nextIndex < [self.defaultCells count]) {
                TextFieldCell *nextCell = [self.defaultCells objectAtIndex:nextIndex];
                [nextCell.textField becomeFirstResponder];
            } else {
                [self setEditing:NO animated:YES];
            }
            break;
        }
        case SECTION_CUSTOM_FIELDS: {
            [textFieldCell.textField resignFirstResponder];
        }
        default:
            break;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUM_SECTIONS;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SECTION_DEFAULT_FIELDS:
            return nil;
        case SECTION_CUSTOM_FIELDS:
            if (self.isKdb4) {
                if ([self tableView:tableView numberOfRowsInSection:1] > 0) {
                    return NSLocalizedString(@"Custom Fields", nil);
                } else {
                    return nil;
                }
            } else {
                return nil;
            }
        case SECTION_COMMENTS:
            if (self.editing == NO) {
                return NSLocalizedString(@"Comments", nil);
            }else{
                return NSLocalizedString(@"Comments_Edit", nil);
            }
         
    }

    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SECTION_DEFAULT_FIELDS:
            return [self.cells count];
        case SECTION_CUSTOM_FIELDS:
            if (self.isKdb4) {
                NSUInteger numCells = self.currentStringFields.count;
                // Additional cell for Add cell
                return self.editing ? numCells + 1 : numCells;
            } else {
                return 0;
            }
        case SECTION_COMMENTS:
            return 1;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *AddFieldCellIdentifier = @"AddFieldCell";

    switch (indexPath.section) {
        case SECTION_DEFAULT_FIELDS: {
            return [self.cells objectAtIndex:indexPath.row];
        }
        case SECTION_CUSTOM_FIELDS: {
            if (indexPath.row == self.currentStringFields.count) {
                // Return "Add new..." cell
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AddFieldCellIdentifier];
                if (cell == nil) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                                  reuseIdentifier:AddFieldCellIdentifier];
                    cell.textLabel.textAlignment = NSTextAlignmentLeft;
                    cell.textLabel.text = NSLocalizedString(@"Add new…", nil);

                    // Add new cell when this cell is tapped
                    [cell addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(addPressed)]];
                }

                return cell;
            } else {
                TextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:TextFieldCellIdentifier];
                if (cell == nil) {
                    cell = [[TextFieldCell alloc] initWithStyle:UITableViewCellStyleValue2
                                                reuseIdentifier:TextFieldCellIdentifier];
                    cell.delegate = self;
                    cell.textField.returnKeyType = UIReturnKeyDone;
                }

                KPKAttribute *stringField = [self.currentStringFields objectAtIndex:indexPath.row];

                cell.style = TextFieldCellStylePlain;
                cell.title = stringField.key;
                if ([stringField.key isEqualToString:@"OTPURL:"])
                {
                    cell.textField.secureTextEntry = true;
                }
                cell.delegate = self;
                cell.textField.text = stringField.value;
                cell.textField.enabled = self.editing;

                return cell;
            }
        }
        case SECTION_COMMENTS: {
            return commentsCell;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case SECTION_DEFAULT_FIELDS:
            break;
        case SECTION_CUSTOM_FIELDS: {
            switch (editingStyle) {
                case UITableViewCellEditingStyleInsert: {
                    [self addPressed];
                    break;
                }
                case UITableViewCellEditingStyleDelete: {
                    TextFieldCell *cell = (TextFieldCell *)[tableView cellForRowAtIndexPath:indexPath];
                    [cell.textField resignFirstResponder];

                    [self.editingStringFields removeObjectAtIndex:indexPath.row];
                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case SECTION_COMMENTS:
            break;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)addPressed {
    
    KPKAttribute *stringField = [[KPKAttribute alloc] initWithKey:@"" value:@""];
    //KPKAttribute *stringField = [KPKAttribute initWithKey:@"" value:@""];
    
    // Display the Rename Database view
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"CustomField" bundle:nil];
    UINavigationController *navigationController = [storyboard instantiateInitialViewController];
    
    CustomFieldViewController *customFieldViewController = (CustomFieldViewController *)navigationController.topViewController;
    customFieldViewController.donePressed = ^(CustomFieldViewController *customFieldViewController) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.editingStringFields.count inSection:1];
        [self.editingStringFields addObject:customFieldViewController.stringField];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

        [customFieldViewController dismissViewControllerAnimated:YES completion:nil];
    };
    customFieldViewController.cancelPressed = ^(CustomFieldViewController *customFieldViewController) {
        [customFieldViewController dismissViewControllerAnimated:YES completion:nil];
    };
    
    customFieldViewController.stringField = stringField;
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

# pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    // Special case for top section with no section title
    if (section == 0) {
        return 10.0f;
    }

    return [self tableView:tableView titleForHeaderInSection:section] == nil ? 0.0f : SECTION_HEADER_HEIGHT;;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
        case SECTION_DEFAULT_FIELDS:
        case SECTION_CUSTOM_FIELDS:
            return 40.0f;
        case SECTION_COMMENTS:
        {
           
            return commentsCell.getCellHeight; //2048.0f; //calculate dynamic
        }
    }

    return 40.0f;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAt:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
        case SECTION_DEFAULT_FIELDS:
        case SECTION_CUSTOM_FIELDS:
            return 40.0f;
        case SECTION_COMMENTS:
            return 2048.0f;
    }

    return 40.0f;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case SECTION_DEFAULT_FIELDS:
            return UITableViewCellEditingStyleNone;
        case SECTION_CUSTOM_FIELDS:
            if (self.isKdb4 && self.editing) {
                if (indexPath.row < self.currentStringFields.count) {
                    return UITableViewCellEditingStyleDelete;
                } else {
                    return UITableViewCellEditingStyleInsert;
                }
            }
            return UITableViewCellEditingStyleNone;
        case SECTION_COMMENTS:
            return UITableViewCellEditingStyleNone;
    }
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == SECTION_CUSTOM_FIELDS;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing && indexPath.section == SECTION_DEFAULT_FIELDS) {
        return nil;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) {
        if (indexPath.section != SECTION_CUSTOM_FIELDS) {
            return;
        }

        [self editStringField:indexPath];
    } else {
        [self copyCellContents:indexPath];
    }
}

- (void)copyCellContents:(NSIndexPath *)indexPath {
    self.tableView.allowsSelection = NO;

    TextFieldCell *cell = (TextFieldCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    
    
    if([cell isKindOfClass:[TextFieldCell class]]){
        if ([cell.title isEqualToString:@"OTP"])
        {
            //Remove Blank from otp
            NSString *otpwithoutspace = [[cell.textField.text substringToIndex:7]
               stringByReplacingOccurrencesOfString:@" " withString:@""];
            pasteboard.string = otpwithoutspace;
        }else{
            pasteboard.string = cell.textField.text;
        }
        if ([cell.title isEqualToString:NSLocalizedString(@"Attachments", nil)])
        {
            //[self openFilesPressed];
            return;
        }
        
        if ([cell.title isEqualToString:@"OTPURL:"])
        {
            NSString *title = NSLocalizedString(@"Forbidden", comment: "");
            NSString *message = NSLocalizedString(@"There is a potential risk to Copy OTP URL to ClipBoard", comment: "");
            
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }
    }
   
    
    
    UIColor *col=[UIColor whiteColor];
    UIColor *back=[UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:0.4];
    if (![[AppSettings sharedInstance] darkEnabled]) {
        
        col =[UIColor blackColor];
        back=[UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:0.4];
    }
   
    // Construct label
    UILabel *copiedLabel = [[UILabel alloc] initWithFrame:cell.bounds];
    copiedLabel.text = NSLocalizedString(@"Copied", nil);
    copiedLabel.font = [UIFont boldSystemFontOfSize:18];
    copiedLabel.textAlignment = NSTextAlignmentCenter;

    copiedLabel.textColor = col;
    copiedLabel.backgroundColor = back;
    // Put cell into "Copied" state
    [cell addSubview:copiedLabel];

    int64_t delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [UIView animateWithDuration:0.5 animations:^{
            // Return to normal state
            copiedLabel.alpha = 0;
            [cell setSelected:NO animated:YES];
        } completion:^(BOOL finished) {
            [copiedLabel removeFromSuperview];
            self.tableView.allowsSelection = YES;
        }];
    });
}

#pragma mark - StringField related

- (void)editStringField:(NSIndexPath *)indexPath {
    KPKAttribute *stringField = [self.editingStringFields objectAtIndex:indexPath.row];
    
    // Display the custom field editing view
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"CustomField" bundle:nil];
    UINavigationController *navigationController = [storyboard instantiateInitialViewController];
    
    CustomFieldViewController *customFieldViewController = (CustomFieldViewController *)navigationController.topViewController;
    customFieldViewController.donePressed = ^(CustomFieldViewController *customFieldViewController) {
        //NSIndexPath *indexPath = (NSIndexPath *)indexPAthstringFieldController.object;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [customFieldViewController dismissViewControllerAnimated:YES completion:nil];
    };
    customFieldViewController.cancelPressed = ^(CustomFieldViewController *customFieldViewController) {
        [customFieldViewController dismissViewControllerAnimated:YES completion:nil];
    };
    
    customFieldViewController.stringField = stringField;
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - Image Selection

- (void)setSelectedImageIndex:(NSUInteger)index {
    _selectedImageIndex = index;

    UIImage *image = [[ImageFactory sharedInstance] imageForIndex:index];
    [titleCell.accessoryButton setImage:image forState:UIControlStateNormal];
    [titleCell.editAccessoryButton setImage:image forState:UIControlStateNormal];
}

- (void)imageButtonPressed {
    if (self.tableView.isEditing) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ImageSelector" bundle:nil];
        ImageSelectorViewController *imageSelectorViewController = [storyboard instantiateInitialViewController];
        imageSelectorViewController.selectedImage = _selectedImageIndex;
        imageSelectorViewController.imageSelected = ^(ImageSelectorViewController *imageSelectorViewController, NSInteger selectedImage) {
            self.selectedImageIndex = selectedImage;
        };
        
        [self.navigationController pushViewController:imageSelectorViewController animated:YES];
    }
}


#pragma mark - Password Display

- (void)showPasswordPressed {
    

	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

	hud.mode = MBProgressHUDModeText;
    hud.detailsLabel.text = self.entry.password;
    hud.detailsLabel.font = [UIFont fontWithName:@"Andale Mono" size:24];
	hud.margin = 10.f;
	hud.removeFromSuperViewOnHide = YES;
    [hud addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:hud action:@selector(hideAnimated:)]];
}

#pragma mark - Password Generation

- (void)generatePasswordPressed {
    // Display the password generator
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PasswordGenerator" bundle:nil];
    UINavigationController *navigationController = [storyboard instantiateInitialViewController];
    
    PasswordGeneratorViewController *passwordGeneratorViewController = (PasswordGeneratorViewController *)navigationController.topViewController;
    passwordGeneratorViewController.donePressed = ^(PasswordGeneratorViewController *passwordGeneratorViewController, NSString *password) {
        self->passwordCell.textField.text = password;
        [passwordGeneratorViewController dismissViewControllerAnimated:YES completion:nil];
    };
    passwordGeneratorViewController.cancelPressed = ^(PasswordGeneratorViewController *passwordGeneratorViewController) {
        [passwordGeneratorViewController dismissViewControllerAnimated:YES completion:nil];
    };
    

    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)openFilesPressed {
    // Display the password generator
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"AttachmentList" bundle:nil];
    //UINavigationController *navigationController = [storyboard instantiateInitialViewController];
    
    AttachmentListViewController *attachmentViewController = [storyboard instantiateInitialViewController];//(AttachmentListViewController *)navigationController.topViewController;
    
    attachmentViewController.entry = self.entry;
    attachmentViewController.fcell = filesCell;
    
    
    /*attachmentViewController.donePressed = ^(AttachmentListViewController *attachmentViewController, NSString *password) {
        self->passwordCell.textField.text = password;
        [attachmentViewController dismissViewControllerAnimated:YES completion:nil];
    };*/
    
    [self.navigationController pushViewController:attachmentViewController animated:YES];
    
   /* attachmentViewController.cancelPressed = ^(AttachmentListViewController *attachmentViewController) {
        [attachmentViewController dismissViewControllerAnimated:YES completion:nil];
    };
    

    [self presentViewController:navigationController animated:YES completion:nil];*/
}

- (void)passwordGeneratorViewController:(PasswordGeneratorViewController *)controller password:(NSString *)password {
    passwordCell.textField.text = password;
}

/*- (void)Autofill {
    AutoFillDB *adb = [[AutoFillDB alloc] init];
    
    NSString *u;
    if(self.entry.url.length <=1)
        u = self.entry.title;
    else
        u = self.entry.url;
    
    if(autofillCell.editAutoFill.on == YES)
    { 
        [adb AddEntryWithUser:self.entry.username secret:self.entry.password url:u];
        
    }else{
        [adb RemoveEntryWithUser:self.entry.username url:u];
    }
}*/

- (void)openScanBarcodePressed {
    // Display the qr scanner
  
    //QRCode scanner without Camera switch and Torch
    QRCodeScannerController *scanner = [[QRCodeScannerController alloc] init]; //[QRCodeScannerController: in];
   
    scanner.delegate = self;
  
    [self presentViewController:scanner animated:YES completion:nil];
   
    
}

- (void)qrScannerDidFail:(UIViewController * _Nonnull)controller error:(NSString * _Nonnull)error {
    NSLog(@"%@",error);
}

- (void)qrScanner:(UIViewController * _Nonnull)controller scanDidComplete:(NSString * _Nonnull)result {
    //This comes back
    
    
    if (!self.isKdb4) {
        
        [controller dismissViewControllerAnimated:YES completion:^{

            NSString *title = NSLocalizedString(@"Not Supported", nil);
            NSString *message = NSLocalizedString(@"This is an KDB in Version 1, and has no support for One Time Passwords", nil);
               
               UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
               [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
               [self presentViewController:alertController animated:YES completion:nil];
        }];
        
           
    }else{
        NSURL *url = [[NSURL alloc] initWithString:result];
         
         Token *tok = [[Token alloc] initWithUrl:url secret:nil error:nil];

        if(tok == nil){
            [controller dismissViewControllerAnimated:YES completion:^{

                       NSString *title = NSLocalizedString(@"Not Supported", nil);
                       NSString *message = NSLocalizedString(@"This is OTP Metod is not supported", nil);
                          
                          UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
                          [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                          [self presentViewController:alertController animated:YES completion:nil];
                   }];
            return;
        }
         KPKAttribute *issuerField = [[KPKAttribute alloc] initWithKey:@"OTP Aussteller:" value:tok.issuer isProtected:NO];
         KPKAttribute *nameField = [[KPKAttribute alloc] initWithKey:@"Name:" value:tok.name isProtected:NO];
         KPKAttribute *secretField = [[KPKAttribute alloc] initWithKey:@"OTPURL:" value:result isProtected:YES];
        
         //[self.editingStringFields addObject:nameField];
         //[self.editingStringFields addObject:secretField];
         
         NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.editingStringFields.count inSection:1];
         [self.editingStringFields addObject:issuerField];
         [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
         
         indexPath = [NSIndexPath indexPathForRow:self.editingStringFields.count inSection:1];
         [self.editingStringFields addObject:nameField];
         [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
         
         indexPath = [NSIndexPath indexPathForRow:self.editingStringFields.count inSection:1];
         [self.editingStringFields addObject:secretField];
         [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    
    
    //NSLog(@"%@",result);
}

- (void)qrScannerDidCancel:(UIViewController * _Nonnull)controller{
    NSLog(@"Cancel");
}

- (void)openUrlPressed {
    NSString *text = urlCell.textField.text;
    
    NSURL *url = [NSURL URLWithString:text];
    if (url.scheme == nil) {
        url = [NSURL URLWithString:[@"http://" stringByAppendingString:text]];
    }

    BOOL isHttp = [url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"];

    BOOL webBrowserIntegrated = [[AppSettings sharedInstance] webBrowserIntegrated];
    if (webBrowserIntegrated && isHttp) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"WebBrowser" bundle:nil];
        UINavigationController *navigationController = [storyboard instantiateInitialViewController];
        
        WebBrowserViewController *webBrowserViewController = (WebBrowserViewController *)navigationController.topViewController;
        webBrowserViewController.url = url;
        webBrowserViewController.entry = self.entry;
        
        [self presentViewController:navigationController animated:YES completion:nil];
    } else {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success){
            
        }];
    }
}


    
   


@end
