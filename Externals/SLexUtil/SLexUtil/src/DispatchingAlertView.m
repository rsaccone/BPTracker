//
//  DispatchingAlertView.m
//  BPTracker
//
//  Created by Robert Saccone on 11/13/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "DispatchingAlertView.h"

#import <objc/message.h> 

#if 0

@interface DispatchingAlertView ()<UIAlertViewDelegate>

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@property(nonatomic, strong) id mySelf;
@property(nonatomic, strong) NSMutableDictionary *buttons;
@property(nonatomic, strong) UIAlertView *alertView;

@end

@implementation DispatchingAlertView
{
@private
    UIAlertView *alertView_;
    NSMutableDictionary *buttons_;
    id mySelf_;
}

@synthesize mySelf = mySelf_;
@synthesize buttons = buttons_;
@synthesize alertView = alertView_;

- (id)initWithTitle:(NSString *)title message:(NSString *)message
{
    if (self = [super init]) 
    {      
        buttons_ = [[NSMutableDictionary alloc] init];
        alertView_ = [[UIAlertView alloc] initWithTitle:title 
                                                message:message 
                                               delegate:self 
                                      cancelButtonTitle:nil 
                                      otherButtonTitles:nil];
    }
    
    return self;
}

+ (id)alertViewWithTitle:(NSString *)title message:(NSString *)message
/* All this does is call the constructor, but the reason to have this method 
 is that it looks like a factory method and so the caller doesn't think 
 that they need to release the object they get. */
{
    return [[DispatchingAlertView alloc] initWithTitle:title message:message];
}


- (void)addButtonWithTitle:(NSString *)title
                    target:(id)target
                    action:(SEL)action
                   context:(id)context
            isCancelButton:(BOOL)isCancelButton
{
    NSInteger buttonIndex = [alertView_ addButtonWithTitle:title];
    
    if (isCancelButton)
    {
        [self.alertView setCancelButtonIndex:buttonIndex];
    }
    
    [self.buttons setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                         target, @"target",
                         [NSValue valueWithPointer:action], @"action", context, @"context", nil]
                 forKey:[NSNumber numberWithInteger:buttonIndex]];
}

- (void)show
{
    self.mySelf = self;
    [self.alertView show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex 
{
    NSDictionary *buttonProperties = [self.buttons objectForKey:[NSNumber numberWithInteger:buttonIndex]];
    id target = [buttonProperties objectForKey:@"target"];
    SEL action = [[buttonProperties objectForKey:@"action"] pointerValue];
    id context = [buttonProperties objectForKey:@"context"];
    
    objc_msgSend(target, action, context);
    self.mySelf = nil;
}

@end

#endif
