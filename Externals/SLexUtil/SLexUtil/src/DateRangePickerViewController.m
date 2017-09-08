//
//  DateRangePickerViewController.m
//  SLexUtil
//
//  Created by Robert Saccone on 9/10/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "DateRangePickerViewController.h"

#import "NSBundle+SLexUtilResBundle.h"
#import "PlatformHelper.h"

@interface DateRangePickerViewController ()

@property(nonatomic, strong) NSDate *dateRangeStart;
@property(nonatomic, strong) NSDate *dateRangeEnd;

@end

@implementation DateRangePickerViewController
{
@private
    UIDatePicker * __weak startDatePicker_;
    UIDatePicker *__weak endDatePicker_;
    NSDate *dateRangeStart_;
    NSDate *dateRangeEnd_;
    NSDate *startDatePicked_;
    NSDate *endDatePicked_;
    BOOL canceled_;
}

@synthesize dateRangeStart = dateRangeStart_;
@synthesize dateRangeEnd = dateRangeEnd_;
@synthesize startDatePicker = startDatePicker_;
@synthesize endDatePicker = endDatePicker_;
@synthesize startDatePicked = startDatePicked_;
@synthesize endDatePicked = endDatePicked_;
@synthesize delegate = delegate_;
@synthesize canceled = canceled_;

#pragma mark - Initialization

- (id)initWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate dateRangeStart:(NSDate *)dateRangeStart dateRangeEnd:(NSDate *)dateRangeEnd
{
    if (!dateRangeStart || !dateRangeEnd)
    {
        NSLog(@"dateRangeStart, or dateRangeEnd is nil!");
        return nil;
    }
    
    if ([dateRangeStart compare:startDate] == NSOrderedDescending)
    {
        NSLog(@"dateRangeStart(%@) > startDate(%@)", dateRangeStart, startDate);
        return nil;
    }

    if (!startDate)
    {
        startDate = dateRangeStart;
    }
    
    if (!endDate)
    {
        endDate = dateRangeEnd;
    }
    
    if ([dateRangeEnd compare:endDate] == NSOrderedAscending)
    {
        NSLog(@"dateRangeEnd(%@) < endDate(%@)", dateRangeEnd, endDate);
        return nil;
    }
    
    if ([startDate compare:endDate] == NSOrderedDescending)
    {
        NSLog(@"startDate(%@) > endDate(%@)", startDate, endDate);
        return nil;
    }

    NSString *nibName = @"DateRangePickerViewController";
 
    self = [super initWithNibName:[PlatformHelper addSuffixToResourceName:nibName] bundle:[NSBundle slexUtilResourcesBundle]];
    
    if (self)
    {
        // Create item
        UIBarButtonItem *bbi = [[UIBarButtonItem alloc]
                                initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                target:self
                                action:@selector(done:)];
        
        [[self navigationItem] setRightBarButtonItem:bbi];
        
        // Cancel item
        bbi = [[UIBarButtonItem alloc]
               initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
               target:self
               action:@selector(cancel:)];
        
        [[self navigationItem] setLeftBarButtonItem:bbi];
        
        startDatePicked_ = startDate;
        endDatePicked_ = endDate;
        dateRangeStart_ = dateRangeStart;
        dateRangeEnd_ = dateRangeEnd;
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithStartDate:nil endDate:nil dateRangeStart:nil dateRangeEnd:nil];
}

- (id)init
{
    return [self initWithStartDate:nil endDate:nil dateRangeStart:nil dateRangeEnd:nil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = SLEXUTIL_LocalizedString(@"DATE_RANGE_PICKER_TITLE");
    
    // Do any additional setup after loading the view from its nib.
    self.startDatePicker.minimumDate = self.dateRangeStart;
    self.startDatePicker.maximumDate = self.dateRangeEnd;
    self.startDatePicker.date = self.startDatePicked;
    
    self.endDatePicker.minimumDate = self.dateRangeStart;
    self.endDatePicker.maximumDate = self.dateRangeEnd;
    self.endDatePicker.date = self.endDatePicked;
    
    [self.startDatePicker addTarget:self action:@selector(pickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.endDatePicker addTarget:self action:@selector(pickerValueChanged:) forControlEvents:UIControlEventValueChanged];
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#if 0 // TBD Remove this.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
#endif


#pragma mark - Actions

- (IBAction)pickerValueChanged:(id)sender
{
    if (sender == self.startDatePicker)
    {
        NSDate *datePicked = self.startDatePicker.date;
        
        if ([self.endDatePicker.date compare:datePicked] == NSOrderedAscending)
        {
            [self.endDatePicker setDate:datePicked animated:YES];
        }
    }
    else
    {
        NSDate *datePicked = self.endDatePicker.date;
        
        if ([self.startDatePicker.date compare:datePicked] == NSOrderedDescending)
        {
            [self.startDatePicker setDate:datePicked animated:YES];
        }
    }
}

- (IBAction)cancel:(id)sender
{
    NSLog(@"cancel pressed...");
    
    canceled_ = YES;
    self.startDatePicked = nil;
    self.endDatePicked = nil;
    
    [self.delegate dateRangePickerViewControllerReadyToBeDismissed:self];
}

- (IBAction)done:(id)sender
{
    NSLog(@"done pressed...");
    
    canceled_ = NO;
    self.startDatePicked = self.startDatePicker.date;
    self.endDatePicked = self.endDatePicker.date;
    
    [self.delegate dateRangePickerViewControllerReadyToBeDismissed:self];
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


@end
