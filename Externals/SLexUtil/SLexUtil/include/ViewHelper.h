//
//  ViewHelper.h
//  BPTracker
//
//  Created by Robert Saccone on 9/20/11.
//  Copyright (c) 2017 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIView.h>
#import <UIKit/UITextField.h>

@interface ViewHelper : NSObject
{
}

+ (NSArray *)viewEntryFields:(UIView *)view;
+ (BOOL)textFieldShouldReturn:(UITextField *)textField viewEntryFields:(NSArray *)entryFields;

@end
