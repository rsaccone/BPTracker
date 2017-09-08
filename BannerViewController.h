//
//  BannerViewController.h
//  BPTracker
//
//  Created by Robert Saccone on 4/24/13.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <iAd/iAd.h>

extern NSString * const BannerViewActionWillBegin;
extern NSString * const BannerViewActionDidFinish;

@interface BannerViewController : UIViewController

- (instancetype)initWithContentViewController:(UIViewController *)contentController;

@property(nonatomic, retain) UIViewController *contentController;

@end
