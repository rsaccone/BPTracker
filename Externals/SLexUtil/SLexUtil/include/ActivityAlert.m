//
//  ActivityAlert.m
//  SLexUtil
//
//  Created by Robert Saccone on 2/23/13.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//
//  Erica Sadun, http://ericasadun.com
//  iPhone Developer's Cookbook, 5.x Edition
//  BSD License, Use at your own risk

#import "ActivityAlert.h"

#import <UIKit/UIKit.h>

static UIAlertView *alertView = nil;
static UIActivityIndicatorView *activity = nil;

@implementation ActivityAlert
+ (void) presentWithText: (NSString *) alertText
{
    if (alertView)
    {
        alertView.title = alertText;
        [alertView show];
    }
    else
    {
        alertView = [[UIAlertView alloc] initWithTitle:alertText
                                               message:@"\n\n\n\n\n\n"
                                              delegate:nil cancelButtonTitle:nil
                                     otherButtonTitles: nil];
        
        [alertView show];
        activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activity.center = CGPointMake(CGRectGetMidX(alertView.bounds), CGRectGetMidY(alertView.bounds));
        [alertView addSubview:activity];
        [activity startAnimating];
    }
}

+ (void) setTitle: (NSString *) aTitle
{
    alertView.title = aTitle;
}

+ (void) setMessage: (NSString *) aMessage;
{
    NSString *message = aMessage;
    
    while ([message componentsSeparatedByString:@"\n"].count < 7)
    {
        message = [message stringByAppendingString:@"\n"];
    }
    
    alertView.message = message;
}

+ (void) dismiss
{
    if (alertView)
    {
        [activity stopAnimating];
        [alertView dismissWithClickedButtonIndex:0 animated:YES];
        
        //        [activity removeFromSuperview];
        activity = nil;
        alertView = nil;
    }
}
@end
