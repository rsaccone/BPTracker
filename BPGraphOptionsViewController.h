//
//  BPGraphOptionsViewController.h
//  BPTracker
//
//  Created by Robert Saccone on 8/29/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BPGraphOptionsViewController;
@class BPGraphSettings;

@protocol BPGraphOptionsViewControllerDelegate <NSObject>

- (BOOL)done:(BPGraphOptionsViewController *)viewController;

@end

@interface BPGraphOptionsViewController : UIViewController

@property(nonatomic, weak) IBOutlet UITextField   *startDateField;
@property(nonatomic, weak) IBOutlet UITextField   *endDateField;
@property(nonatomic, weak) IBOutlet UISwitch      *systolicDataSwitch;
@property(nonatomic, weak) IBOutlet UISwitch      *diastolicDataSwitch;
@property(nonatomic, weak) IBOutlet UISwitch      *pulseDataSwitch;
@property(nonatomic, weak) IBOutlet UISwitch      *legendDataSwitch;

@property(nonatomic, copy, readonly) BPGraphSettings *bpGraphSettings;
@property(nonatomic, assign, readonly) BOOL canceled;
@property(nonatomic, assign, readonly) BOOL saved;

// Designated initializer for this class.
- (id)initWithStartDateRangeMin:(NSDate *)startDateMin
                endDateRangeMax:(NSDate *)endDateMax
                   graphSettings:(BPGraphSettings *)bpGraphSettings
         viewControllerDelegate:(id<BPGraphOptionsViewControllerDelegate>)delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;


@end
