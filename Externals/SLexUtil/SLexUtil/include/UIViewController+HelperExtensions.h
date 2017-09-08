//
//  NSObject+UIVCAdditions.h
//  BPTracker
//
//  Created by Robert Saccone on 4/1/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIViewController.h>

@interface UIViewController (HelperExtensions)

- (BOOL)isVisible;

- (CGFloat)topOfViewOffset;

@end
