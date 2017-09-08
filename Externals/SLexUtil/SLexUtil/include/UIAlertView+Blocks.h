//
//  UIAlertView_UIAlertView_Blocks.h
//  SLexUtil
//
//  Created by Robert Saccone on 11/29/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^WillPresentBlock)(UIAlertView *alertView);
typedef void (^DidPresentBlock)(UIAlertView *alertView);
typedef void (^DidCancelBlock)(UIAlertView *alertView);
typedef void (^ClickedButtonBlock)(UIAlertView *alertView, NSInteger buttonIndex);
typedef void (^WillDismissBlock)(UIAlertView *alertView, NSInteger buttonIndex);
typedef void (^DidDismissBlock)(UIAlertView *alertView, NSInteger buttonIndex);

@interface UIAlertView (Blocks)

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
    clickedButtonBlock:(ClickedButtonBlock)block
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSString *)otherButtonTitles, ...;

@property (nonatomic, copy) WillPresentBlock willPresentBlock;
@property (nonatomic, copy) DidPresentBlock didPresentBlock;
@property (nonatomic, copy) DidCancelBlock didCancelBlock;
@property (nonatomic, copy) ClickedButtonBlock clickedButtonBlock;
@property (nonatomic, copy) WillDismissBlock willDismissBlock;
@property (nonatomic, copy) DidDismissBlock didDismissBlock;

@end
