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

#import "KeePassMini-Swift.h"
#import "AppDelegate.h"
#import "AppSettings.h"
#import "ObjcEditorViewController.h"
#import "TextViewCell.h"


@implementation TextViewCell

@synthesize textView;
@synthesize longPress;
@synthesize normalPress;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        
        [self addGestureRecognizer:self.longPress];
        
      self.normalPress = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(normalPress:)];
        
        [self addGestureRecognizer:self.normalPress];
                
        

        textView = [[UITextView alloc] initWithFrame:CGRectZero];
        textView.font = [UIFont systemFontOfSize:16];
        textView.alwaysBounceVertical = TRUE;
        textView.delegate = self;
        [self addSubview:textView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.frame;
    
    textView.frame = CGRectMake(rect.origin.x + 3, rect.origin.y + 3, rect.size.width - 6, rect.size.height - 6);
}

- (CGFloat)getCellHeight{

    CGSize maximumTextViewSize = CGSizeMake(textView.frame.size.width, CGFLOAT_MAX);
    NSStringDrawingOptions options = NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:60]};
    //NSDictionary *attr = @{[NSFontAttributeName: [UIFont systemFontOfSize:16]]};
    CGRect textViewBounds = [textView.text boundingRectWithSize:maximumTextViewSize
                                                        options:options
                                                     attributes:attributes
                                                        context:nil];
    CGFloat height = ceilf(textViewBounds.size.height);
    
    return height;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  BOOL shouldChangeText = YES;
      
  if ([text isEqualToString:@"\n"]) {
    // Find the next entry field
      id view = [self superview];

      while (view && [view isKindOfClass:[UITableView class]] == NO) {
          view = [view superview];
      }

      
      // Calculate layout for full document, so scrolling is smooth.
      [[self.textView layoutManager]ensureLayoutForCharacterRange:range];
       
       //[ensureLayout: [forCharacterRange: NSRange(location: 0, length: self.textView.text.count]];
      UITableView *tableView = (UITableView *)view;
      [tableView beginUpdates];
      [tableView endUpdates];
     
      
  }
      
  return shouldChangeText;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    UITouch *touch = [[event allTouches] anyObject];
    
    
    if ([textView isFirstResponder] && [touch view] != textView) {
        [textView resignFirstResponder];
    }else{
        [textView becomeFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

    UITouch *touch = [[event allTouches] anyObject];
    
    //textView.editable = YES;
    textView.dataDetectorTypes = UIDataDetectorTypeNone;
    [textView becomeFirstResponder];

    //Consider replacing self.view here with whatever view you want the point within
    CGPoint point = [touch locationInView:self.contentView];
    UITextPosition * position=[textView closestPositionToPoint:point];
    [textView setSelectedTextRange:[textView textRangeFromPosition:position toPosition:position]];
    
    
    [super touchesBegan:touches withEvent:event];
}

- (void) normalPress:(UIGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        NSLog(@"Tap press");
    }
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        if(!self.textView.isEditable){
            /*UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = self.textView.text;
            UIColor *col=[UIColor whiteColor];
            UIColor *back=[UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:0.4];
            if (![[AppSettings sharedInstance] darkEnabled]) {
                
                col =[UIColor blackColor];
                back=[UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:0.4];
            }
           
            // Construct label
            UILabel *copiedLabel = [[UILabel alloc] initWithFrame:self.bounds];
            copiedLabel.text = NSLocalizedString(@"Copied", nil);
            copiedLabel.font = [UIFont boldSystemFontOfSize:18];
            copiedLabel.textAlignment = NSTextAlignmentCenter;

            copiedLabel.textColor = col;
            copiedLabel.backgroundColor = back;

            // Put cell into "Copied" state
            [self addSubview:copiedLabel];

            int64_t delayInSeconds = 1.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [UIView animateWithDuration:0.5 animations:^{
                    // Return to normal state
                    copiedLabel.alpha = 0;
                    [self setSelected:NO animated:YES];
                } completion:^(BOOL finished) {
                    [copiedLabel removeFromSuperview];
                  
                }];
            });*/
          
            [NSUserDefaults standardUserDefaults];
           
            ObjcEditorViewController *textedit =  [[ObjcEditorViewController alloc] init];
            
            //textedit.useCustomDropInteraction=YES;
            textedit.delegate = self;
            textedit.text = self.textView.text;
            textedit.modalPresentationStyle = -2;
            
            [self.parentView presentViewController:textedit animated:YES completion:nil];

           
        }else{
            [NSUserDefaults standardUserDefaults];
           
            ObjcEditorViewController *textedit =  [[ObjcEditorViewController alloc] init];
            
            //textedit.useCustomDropInteraction=YES;
            textedit.delegate = self;
            textedit.text = self.textView.text;
            textedit.modalPresentationStyle = -2;
           // textedit.width = self.parentView.view.frame.size.width;
            //[textedit.delegate self]
            // See `Settings.bundle`.
            //[textedit [useCustomDropInteraction:YES]];

            [self.parentView presentViewController:textedit animated:YES completion:nil];
            //self.present(navController, animated: true, completion: nil)
            /*textView.editable = YES;
            textView.dataDetectorTypes = UIDataDetectorTypeNone;
            [textView becomeFirstResponder];

            //Consider replacing self.view here with whatever view you want the point within
            CGPoint point = [gesture locationInView:self.contentView];
            UITextPosition * position=[textView closestPositionToPoint:point];
            [textView setSelectedTextRange:[textView textRangeFromPosition:position toPosition:position]];*/
        }
    }
}

- (void)ObjcEditorViewControllerDidTapDone:(ObjcEditorViewController *)editor
{
    
    //NSLog(@"String received at FirstVC: %@",editor.text);
    
    self.textView.text = editor.text;
    id<EntryViewControllerDelegate> const delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(saveCommentText:)]) {
            [delegate saveCommentText:self];
    }
}
 
- (void) longPress:(UILongPressGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        NSLog(@"long press");
        
       
            
    }
    
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        UIMenuController *menu = [UIMenuController sharedMenuController];
        if (![menu isMenuVisible])
        {
            [self becomeFirstResponder];
            [menu setTargetRect:self.frame inView:self.superview];
            [menu setMenuVisible:YES animated:YES];
        }
    }
}


/*- (void) editTextRecognizerTabbed:(UITapGestureRecognizer *) aRecognizer
{
    if (aRecognizer.state==UIGestureRecognizerStateEnded)
    {
        //Not sure if you need all this, but just carrying it forward from your code snippet
        textView.editable = YES;
        textView.dataDetectorTypes = UIDataDetectorTypeNone;
        [textView becomeFirstResponder];

        //Consider replacing self.view here with whatever view you want the point within
        CGPoint point = [aRecognizer locationInView:self.contentView];
        UITextPosition * position=[textView closestPositionToPoint:point];
        [textView setSelectedTextRange:[textView textRangeFromPosition:position toPosition:position]];
    }
}*/
@end

// MARK: - ObjcViewControllerDelegate

