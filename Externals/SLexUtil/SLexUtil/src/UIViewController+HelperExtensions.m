//
//  NSObject+UIVCAdditions.m
//  BPTracker
//
//  Created by Robert Saccone on 4/1/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "UIViewController+HelperExtensions.h"

@implementation UIViewController (HelperExtensions)

- (BOOL)isVisible
{
    return (self.isViewLoaded && self.view.window); 
}

- (CGFloat)topOfViewOffset
{
    CGFloat top = 0;
    if ([self respondsToSelector:@selector(topLayoutGuide)])
    {
        top = self.topLayoutGuide.length;
    }
    return top;
}

@end
