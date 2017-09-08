//
//  SLXDateRangePickerCoordinator.m
//  SLexUtil
//
//  Created by Robert Saccone on 7/13/14.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "SLXDateRangePickerCoordinator.h"

@interface SLXDateRangePickerCoordinator ()

- (void)updateDateRangeField:(id)sender;
- (void)updateDateTextField:(UITextField *)textField fromDate:(NSDate *)date updateInputDatePicker:(BOOL)updateDatePicker;

- (void)doneClickedForStartRange:(id)sender;
- (void)doneClickedForEndRange:(id)sender;

@property(nonatomic, weak) UITextField *startRangeTextField;
@property(nonatomic, weak) UITextField *endRangeTextField;

@end

@implementation SLXDateRangePickerCoordinator
{
    NSDateFormatter *_dateFormatter;
}

- (instancetype)initWithStartRangeTextField:(UITextField *)startRangeTextField endRangeTextField:(UITextField *)endRangeTextField
{
    self = [super init];
    
    if (self != nil)
    {
        if (startRangeTextField == nil)
        {
            NSLog(@"SLXDateRangePickerCoordinator: nil startRangeTextField passed!");
            NSAssert(startRangeTextField != nil, @"startRangeTextField is nil!");
            
            return nil;
        }
        
        if (endRangeTextField == nil)
        {
            NSLog(@"SLXDateRangePickerCoordinator: nil endRangeTextField passed!");
            NSAssert(endRangeTextField != nil, @"endRangeTextField is nil!");
            
            return nil;
        }
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        
        if (_dateFormatter == nil)
        {
            NSLog(@"SLXDateRangePickerCoordinator: couldn't create NSDateFormatter!");
            return nil;
        }
        
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        
        _startRangeTextField = startRangeTextField;
        _endRangeTextField = endRangeTextField;
        
        UIDatePicker *datePicker = [[UIDatePicker alloc] init];
        
        if (datePicker == nil)
        {
            NSLog(@"SLXDateRangePickerCoordinator: couldn't create UIDatePicker for start range test field!");
            return nil;
        }
        
        [datePicker addTarget:self action:@selector(updateDateRangeField:) forControlEvents:UIControlEventValueChanged];
        [_startRangeTextField setInputView:datePicker];
        
        UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
        keyboardDoneButtonView.barStyle = UIBarStyleDefault;
        keyboardDoneButtonView.translucent = YES;
        keyboardDoneButtonView.tintColor = nil;
        [keyboardDoneButtonView sizeToFit];
        
        
        UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(doneClickedForStartRange:)];
        
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];

        keyboardDoneButtonView.items = [NSArray arrayWithObjects:flex, doneButton, nil];
        
        // Plug the keyboardDoneButtonView into the text field...
        _startRangeTextField.inputAccessoryView = keyboardDoneButtonView;
        
        datePicker = [[UIDatePicker alloc] init];
        
        if (datePicker == nil)
        {
            NSLog(@"SLXDateRangePickerCoordinator: couldn't create UIDatePicker for end range test field!");
            return nil;
        }

        [datePicker addTarget:self action:@selector(updateDateRangeField:) forControlEvents:UIControlEventValueChanged];
        [_endRangeTextField setInputView:datePicker];
        
        keyboardDoneButtonView = [[UIToolbar alloc] init];
        keyboardDoneButtonView.barStyle = UIBarStyleDefault;
        keyboardDoneButtonView.translucent = YES;
        keyboardDoneButtonView.tintColor = nil;
        [keyboardDoneButtonView sizeToFit];
        
        
        doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                   target:self
                                                                   action:@selector(doneClickedForEndRange:)];
        
        keyboardDoneButtonView.items = [NSArray arrayWithObjects:flex, doneButton, nil];
        
        // Plug the keyboardDoneButtonView into the text field...
        _endRangeTextField.inputAccessoryView = keyboardDoneButtonView;
    }
    
    return self;
}

#pragma mark - Text Field Update Method.

- (void)updateDateTextField:(UITextField *)textField fromDate:(NSDate *)date updateInputDatePicker:(BOOL)updateDatePicker
{
    NSAssert(textField != nil, @"textField is nil!");
    NSAssert(date != nil, @"date is nil!");
    
    textField.text = [_dateFormatter stringFromDate:date];
    
    if (updateDatePicker)
    {
        UIDatePicker *datePicker = (UIDatePicker *)textField.inputView;
        
        NSAssert(datePicker != nil, @"datePicker is nil!");
        
        datePicker.date = date;
    }
}


#pragma mark - Start / End Date custom properties.

- (void)setStartDate:(NSDate *)startDate
{
    if ((startDate != nil) && (startDate != _startDate))
    {
        _startDate = startDate;
        [self updateDateTextField:self.startRangeTextField fromDate:_startDate updateInputDatePicker:YES];
    }
}

- (void)setEndDate:(NSDate *)endDate
{
    if ((endDate != nil) && (endDate != _endDate))
    {
        _endDate = endDate;
        [self updateDateTextField:self.endRangeTextField fromDate:_endDate updateInputDatePicker:YES];
    }
}

#pragma mark - Min / Max Date custom properties

- (void)setMinDate:(NSDate *)minDate
{
    if ((minDate != nil) && (minDate != _minDate))
    {
        UIDatePicker *startDatePicker = (UIDatePicker *)self.startRangeTextField.inputView;
        UIDatePicker *endDatePicker = (UIDatePicker *)self.endRangeTextField.inputView;
        
        NSAssert(startDatePicker != nil, @"startDatePicker is nil!");
        NSAssert(endDatePicker != nil, @"endDatePicker is nil!");
        
        _minDate = minDate;
        startDatePicker.minimumDate = _minDate;
        endDatePicker.minimumDate = _minDate;
        
        if ((_startDate != nil) && ([_minDate compare:_startDate] == NSOrderedDescending))
        {
            self.startDate = _minDate;
        }
        
        if ((_endDate != nil) && ([_minDate compare:_endDate] == NSOrderedDescending))
        {
            self.endDate = _minDate;
        }
    }
}

- (void)setMaxDate:(NSDate *)maxDate
{
    if ((maxDate != nil) && (maxDate != _maxDate))
    {
        UIDatePicker *startDatePicker = (UIDatePicker *)self.startRangeTextField.inputView;
        UIDatePicker *endDatePicker = (UIDatePicker *)self.endRangeTextField.inputView;
        
        NSAssert(startDatePicker != nil, @"startDatePicker is nil!");
        NSAssert(endDatePicker != nil, @"endDatePicker is nil!");
        
        _maxDate = maxDate;
        startDatePicker.maximumDate = _maxDate;
        endDatePicker.maximumDate = _maxDate;

        if ((_startDate != nil) && ([_maxDate compare:_startDate] == NSOrderedDescending))
        {
            self.startDate = _maxDate;
        }
        
        if ((_endDate != nil) && [_maxDate compare:_endDate] == NSOrderedDescending)
        {
            self.endDate = _maxDate;
        }
    }
}

#pragma mark - Date Range Text Field Update Methods

- (void)updateDateRangeField:(id)sender
{
    UIDatePicker *sendingDatePicker = (UIDatePicker *)sender;
    NSDate *datePicked = sendingDatePicker.date;
    
    UIDatePicker *startDatePicker = (UIDatePicker *)self.startRangeTextField.inputView;
    UIDatePicker *endDatePicker = (UIDatePicker *)self.endRangeTextField.inputView;

    DateRangeComponent updatedRangeComponent;
    
    if (sendingDatePicker == startDatePicker)
    {
        self.startDate = datePicked;
        
        if ([endDatePicker.date compare:datePicked] == NSOrderedAscending)
        {
            self.endDate = datePicked;
            updatedRangeComponent = Start;
        }
        else
        {
            updatedRangeComponent = Both;
        }
    }
    else
    {
        self.endDate = datePicked;
        
        if ([startDatePicker.date compare:datePicked] == NSOrderedDescending)
        {
            self.startDate = datePicked;
            updatedRangeComponent = End;
        }
        else
        {
            updatedRangeComponent = Both;
        }
    }
    
    id<SLXDateRangePickerCoordinatorDelegate> delegate = self.delegate;
    
    if (delegate != nil)
    {
        [delegate dateRangeUpdated:self componentUpdated:updatedRangeComponent];
    }
}

#pragma mark - Toolbar Accessory Button Click.

- (void)doneClickedForStartRange:(id)sender
{
    NSLog(@"Done for start range clicked");
    [self.startRangeTextField resignFirstResponder];
}

- (void)doneClickedForEndRange:(id)sender
{
    NSLog(@"Done for end range clicked");
    [self.endRangeTextField resignFirstResponder];
}

@end
