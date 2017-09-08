//
//  DatePickerViewController.h
//  BPTracker
//
//  Created by Robert Saccone on 4/16/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DatePickerViewController;

@protocol DatePickerViewControllerDelegate <NSObject>

- (void)datePickerViewControllerReadyToBeDismissed:(DatePickerViewController *)viewController pickedDate:(NSDate *)date;

@end

@interface DatePickerViewController : UIViewController 
{
}

- (id)init;
- (id)initWithDate:(NSDate *)startingDate;
- (id)initWithDate:(NSDate *)startingDate minimumDate:(NSDate *)minDate maximumDate:(NSDate *)maxDate;
- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@property(nonatomic, weak) id<DatePickerViewControllerDelegate> delegate;
@property(nonatomic, readonly, assign) BOOL canceled;
@property(nonatomic, weak) IBOutlet UIDatePicker *datePicker;
@property(nonatomic, strong, readonly) NSDate* pickedDate;

@end
