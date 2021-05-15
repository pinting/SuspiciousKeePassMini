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
#import "ObjcEditorViewController.h"

@interface TextViewCell : UITableViewCell <UITextViewDelegate,ObjcEditorViewControllerDelegate> {
	UITextView *textView;
    UITableViewController *parentView;
    UILongPressGestureRecognizer *longPress;
    UITapGestureRecognizer *normalPress;
   
}

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UITableViewController *parentView;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic, strong) UITapGestureRecognizer *normalPress;

- (CGFloat)getCellHeight;
@end
