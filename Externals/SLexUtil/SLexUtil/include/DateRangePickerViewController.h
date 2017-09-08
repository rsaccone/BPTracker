//
//  DateRangePickerViewController.h
//  SLexUtil
//
//  Created by Robert Saccone on 9/10/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DateRangePickerViewController;

@protocol DateRangePickerViewControllerDelegate <NSObject>

- (void)dateRangePickerViewControllerReadyToBeDismissed:(DateRangePickerViewController *)viewController;

@end


@interface DateRangePickerViewController : UIViewController

- (id)initWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate dateRangeStart:(NSDate *)dateRangeStart dateRangeEnd:(NSDate *)dateRangeEnd;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@property(nonatomic, weak) IBOutlet UIDatePicker *startDatePicker;
@property(nonatomic, weak) IBOutlet UIDatePicker *endDatePicker;
@property(nonatomic, strong) NSDate *startDatePicked;
@property(nonatomic, strong) NSDate *endDatePicked;
@property(nonatomic, weak) id<DateRangePickerViewControllerDelegate> delegate;
@property(nonatomic, readonly, assign) BOOL canceled;

@end
