//
//  DispatchingAlertView.h
//  BPTracker
//
//  Created by Robert Saccone on 11/13/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIAlertView.h>

__attribute__((deprecated))
@interface DispatchingAlertView : NSObject 
{
}

+ (id)alertViewWithTitle:(NSString *)title message:(NSString *)message;

- (id)initWithTitle:(NSString *)title message:(NSString *)message;
- (void)addButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action context:(id)context isCancelButton:(BOOL)isCancelButton;
- (void)show;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex; 

@end
