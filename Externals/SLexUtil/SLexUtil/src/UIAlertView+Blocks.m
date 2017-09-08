//
//  UIAlertView_UIAlertView_Blocks.h
//  SLexUtil
//
//  Created by Robert Saccone on 11/29/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "UIAlertView+Blocks.h"
#import <objc/runtime.h>

static const char * const WillPresentBlockKey   = "WillPresentBlock";
static const char * const DidPresentBlockKey    = "DidPresentBlock";
static const char * const DidCancelBlockKey     = "DidCancelBlock";
static const char * const ClickedButtonBlockKey = "ClickedButtonBlock";
static const char * const WillDismissBlockKey   = "WillDismissBlock";
static const char * const DidDismissBlockKey    = "DidDismissBlock";

@implementation UIAlertView (Blocks)

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
    clickedButtonBlock:(ClickedButtonBlock)block
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSString *)otherButtonTitles, ...
{
    self = [self initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    
	if (self != nil)
    {
        if (block != nil)
        {
            objc_setAssociatedObject(self, ClickedButtonBlockKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
        }
        
		if (cancelButtonTitle)
        {
			[self addButtonWithTitle:cancelButtonTitle];
			self.cancelButtonIndex = [self numberOfButtons] - 1;
		}
        
		va_list argumentList;
		if (otherButtonTitles)
        {
			[self addButtonWithTitle:otherButtonTitles];
            
			va_start(argumentList, otherButtonTitles);
            
            id eachObject;
            
			while ((eachObject = va_arg(argumentList, id)))
            {
				[self addButtonWithTitle:eachObject];
			}
			va_end(argumentList);
		}
	}
	
	return self;
}

#pragma mark - Property methods

- (WillPresentBlock)willPresentBlock
{
    return objc_getAssociatedObject(self, WillPresentBlockKey);
}

- (void)setWillPresentBlock:(WillPresentBlock)willPresentBlock
{
	objc_setAssociatedObject(self, WillPresentBlockKey, willPresentBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (DidPresentBlock)didPresentBlock
{
    return objc_getAssociatedObject(self, DidPresentBlockKey);
}

- (void)setDidPresentBlock:(DidPresentBlock)didPresentBlock
{
	objc_setAssociatedObject(self, DidPresentBlockKey, didPresentBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (DidCancelBlock)didCancelBlock
{
    return objc_getAssociatedObject(self, DidCancelBlockKey);
}

- (void)setDidCancelBlock:(DidCancelBlock)didCancelBlock
{
	objc_setAssociatedObject(self, DidCancelBlockKey, didCancelBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (ClickedButtonBlock)clickedButtonBlock
{
    return objc_getAssociatedObject(self, ClickedButtonBlockKey);
}

- (void)setClickedButtonBlock:(ClickedButtonBlock)clickedButtonBlock
{
	objc_setAssociatedObject(self, ClickedButtonBlockKey, clickedButtonBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (WillDismissBlock)willDismissBlock
{
    return objc_getAssociatedObject(self, WillDismissBlockKey);
}

- (void)setWillDismissBlock:(WillDismissBlock)willDismissBlock
{
	objc_setAssociatedObject(self, WillDismissBlockKey, willDismissBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (DidDismissBlock)didDismissBlock
{
    return objc_getAssociatedObject(self, DidDismissBlockKey);
}

- (void)setDidDismissBlock:(DidDismissBlock)didDismissBlock
{
	objc_setAssociatedObject(self, DidDismissBlockKey, didDismissBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - UIAlertView delegate methods.

- (void) willPresentAlertView:(UIAlertView *)alertView
{
    WillPresentBlock willPresentBlock = self.willPresentBlock;
    
	if (willPresentBlock != nil)
    {
		willPresentBlock(alertView);
	}
}

- (void) didPresentAlertView:(UIAlertView *)alertView
{
    DidPresentBlock didPresentBlock = self.didPresentBlock;
    
    if (didPresentBlock != nil)
    {
		didPresentBlock(alertView);
	}
}

- (void) alertViewCancel:(UIAlertView *)alertView
{
    DidCancelBlock didCancelBlock = self.didCancelBlock;
    
	if (didCancelBlock != nil)
    {
		didCancelBlock(alertView);
	}
}

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    ClickedButtonBlock clickedButtonBlock = self.clickedButtonBlock;
    
	if (clickedButtonBlock != nil)
    {
		clickedButtonBlock(alertView, buttonIndex);
	}
}

- (void) alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    WillDismissBlock willDismissBlock = self.willDismissBlock;
    
	if (willDismissBlock != nil)
    {
		willDismissBlock(alertView, buttonIndex);
	}
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    DidDismissBlock didDismissBlock = self.didDismissBlock;
    
	if (didDismissBlock != nil)
    {
		didDismissBlock(alertView, buttonIndex);
	}
}

@end