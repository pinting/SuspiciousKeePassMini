//
//  ObjcEditorViewController.m
//  Example
//
//  Copyright 2021 Twitter, Inc.
//  SPDX-License-Identifier: Apache-2.0
//


#import "IOSKeePass-Swift.h"
#import "ObjcEditorViewController.h"

@import KeyboardGuide;

NS_ASSUME_NONNULL_BEGIN

@interface ObjcEditorViewController () <TextEditorBridgeViewDelegate>

@property (nonatomic, nullable) TextEditorBridgeView *textEditorView;

@end

@implementation ObjcEditorViewController

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    [self doesNotRecognizeSelector:_cmd];
    abort();
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    [self doesNotRecognizeSelector:_cmd];
    abort();
}

- (instancetype)init
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.title = @"Comment Editor";

        
        
    }
    return self;
}

// MARK: - Actions

- (void)refreshBarButtonItemDidTap:(id)sender
{
    self.textEditorView.isEditing = NO;
    self.textEditorView.text = self.text;
}

- (void)doneBarButtonItemDidTap:(id)sender
{
    self.text = self.textEditorView.text;
    id<ObjcEditorViewControllerDelegate> const delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(ObjcEditorViewControllerDidTapDone:)]) {
        [delegate ObjcEditorViewControllerDidTapDone:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

// MARK: - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UINavigationBar* navbar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];

    UINavigationItem* navItem = [[UINavigationItem alloc] initWithTitle:@"KeePass Notes"];
    
    UIBarButtonItem * const refreshBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                      target:self
                                                      action:@selector(refreshBarButtonItemDidTap:)];
    navItem.leftBarButtonItems = @[refreshBarButtonItem];
    UIBarButtonItem * const doneBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self
                                                      action:@selector(doneBarButtonItemDidTap:)];
    navItem.rightBarButtonItems = @[doneBarButtonItem];
    
    [navbar setItems:@[navItem]];
    [self.view addSubview:navbar];
    
    self.view.backgroundColor = UIColor.defaultBackgroundColor;

    NSMutableArray<NSLayoutConstraint *> * const constraints = [[NSMutableArray alloc] init];

    TextEditorBridgeView * const textEditorView = [[TextEditorBridgeView alloc] init];
    textEditorView.delegate = self;

    textEditorView.layer.borderColor = UIColor.defaultBorderColor.CGColor;
    textEditorView.layer.borderWidth = 0.0;

    textEditorView.font = [UIFont systemFontOfSize:20.0];

    [self.view addSubview:textEditorView];

    textEditorView.translatesAutoresizingMaskIntoConstraints = NO;
    [constraints addObject:[textEditorView.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor constant: 50]];
    [constraints addObject:[textEditorView.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor]];
    [constraints addObject:[textEditorView.bottomAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.bottomAnchor]];
    [constraints addObject:[textEditorView.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor]];

    self.textEditorView = textEditorView;

    // This view is used to call `layoutSubviews` when keyboard safe area is changed
    // to manually change scroll view content insets.
    // See `viewDidLayoutSubviews`.
    UIView * const keyboardSafeAreaRelativeLayoutView = [[UIView alloc] init];
    [self.view addSubview:keyboardSafeAreaRelativeLayoutView];
    keyboardSafeAreaRelativeLayoutView.translatesAutoresizingMaskIntoConstraints = NO;
    [constraints addObject:[keyboardSafeAreaRelativeLayoutView.bottomAnchor constraintEqualToAnchor:self.view.kbg_keyboardSafeArea.layoutGuide.bottomAnchor]];

    self.textEditorView.text =self.text;
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    const CGFloat bottomInset = self.view.kbg_keyboardSafeArea.insets.bottom - self.view.layoutMargins.bottom;

    UIEdgeInsets contentInset = self.textEditorView.scrollView.contentInset;
    contentInset.bottom = bottomInset;
    self.textEditorView.scrollView.contentInset = contentInset;

    if (@available(iOS 11.1, *)) {
        UIEdgeInsets verticalScrollIndicatorInsets = self.textEditorView.scrollView.verticalScrollIndicatorInsets;
        verticalScrollIndicatorInsets.bottom = bottomInset;
        self.textEditorView.scrollView.verticalScrollIndicatorInsets = verticalScrollIndicatorInsets;
    } else {
        UIEdgeInsets scrollIndicatorInsets = self.textEditorView.scrollView.scrollIndicatorInsets;
        scrollIndicatorInsets.bottom = bottomInset;
        self.textEditorView.scrollView.scrollIndicatorInsets = scrollIndicatorInsets;
    }
}

- (void)doneBarButtonItemDidTap {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
// MARK: - TextEditorBridgeViewDelegate

- (void)textEditorBridgeView:(TextEditorBridgeView *)textEditorBridgeView
      updateAttributedString:(NSAttributedString *)attributedString
                  completion:(void (^)(NSAttributedString * _Nullable))completion
{
    NSMutableAttributedString * const text = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
    const NSRange range = NSMakeRange(0, text.string.length);

    [text addAttribute:NSForegroundColorAttributeName value:UIColor.defaultTextColor range:range];

    NSRegularExpression * const regexp = [[NSRegularExpression alloc] initWithPattern:@"#[^\\s]+" options:0 error:nil];
    [regexp enumerateMatchesInString:text.string
                             options:0
                               range:range
                          usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        if (!result) {
            return;
        }
        const NSRange matchedRange = result.range;
        [text addAttribute:NSForegroundColorAttributeName value:UIColor.systemBlueColor range:matchedRange];
    }];

    completion(text);
}

@end

NS_ASSUME_NONNULL_END
