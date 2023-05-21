//
//  ObjcEditorViewController.h
//  Example
//
//  Copyright 2021 Twitter, Inc.
//  SPDX-License-Identifier: Apache-2.0
//

@import Foundation;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@class ObjcEditorViewController;

@protocol ObjcEditorViewControllerDelegate <NSObject>

@optional
- (void)ObjcEditorViewControllerDidTapDone:(ObjcEditorViewController *)ObjcEditorViewController;

@end

@interface ObjcEditorViewController : UIViewController

@property (nonatomic, weak, nullable) id<ObjcEditorViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString *text;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
