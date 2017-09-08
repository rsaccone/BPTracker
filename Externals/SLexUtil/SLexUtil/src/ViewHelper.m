//
//  ViewHelper.m
//  BPTracker
//
//  Created by Robert Saccone on 9/20/11.
//  Copyright (c) 2017 __MyCompanyName__. All rights reserved.
//

#import "ViewHelper.h"

@implementation ViewHelper

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

/* 
 Returns an array of all data entry fields in the view. 
 Fields are ordered by tag, and only fields with tag > 0 are included. 
 Returned fields are guaranteed to be a subclass of UIResponder. 
 */  
+ (NSArray *)viewEntryFields:(UIView *)view;
{
    NSMutableArray *entryFields = [[NSMutableArray alloc] init];
    NSInteger tag = 1;  
    UIView *aView;  
    while ((aView = [view viewWithTag:tag])) 
    {  
        if (aView && [[aView class] isSubclassOfClass:[UIResponder class]]) 
        {  
            [entryFields addObject:aView];  
        }  
        
        ++tag;  
    }  

    return entryFields;  
}  

+ (BOOL)textFieldShouldReturn:(UITextField *)textField viewEntryFields:(NSArray *)entryFields 
{  
    // Find the next entry field  
    for (UIView *view in entryFields) 
    {  
        if (view.tag == (textField.tag + 1)) 
        {  
            [view becomeFirstResponder];  
            break;  
        }  
    }  
    
    return NO;  
}  

@end
