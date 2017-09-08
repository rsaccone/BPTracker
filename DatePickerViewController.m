//
//  DatePickerViewController.m
//  BPTracker
//
//  Created by Robert Saccone on 4/16/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "DatePickerViewController.h"
#import <SLexUtil/NSDate+UtilityExtensions.h>
#import <SLexUtil/PlatformHelper.h>

// Class extension using anonymous category to hide
// set on pickedDate property from consumers
// of the class.
@interface DatePickerViewController ()

@property(nonatomic, strong) NSDate* pickedDate;
@property(nonatomic, strong) NSDate* minimumDate;
@property(nonatomic, strong) NSDate* maximumDate;

@end

@implementation DatePickerViewController
{
@private
	UIDatePicker * __weak datePicker_;
    NSDate *pickedDate_;
    NSDate *minimumDate_;
    NSDate *maximumDate_;
    BOOL canceled_;
}

@synthesize delegate;
@synthesize datePicker=datePicker_;
@synthesize canceled=canceled_;
@synthesize pickedDate=pickedDate_;
@synthesize minimumDate=minimumDate_;
@synthesize maximumDate=maximumDate_;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    return [self init];
}

- (id)init
{
    return [self initWithDate:nil];
}

- (id)initWithDate:(NSDate *)startingDate
{
    return [self initWithDate:startingDate minimumDate:nil maximumDate:nil];
}

- (id)initWithDate:(NSDate *)startingDate minimumDate:(NSDate *)minDate maximumDate:(NSDate *)maxDate
{
    static NSString * const nibName = @"DatePickerViewController";
    
    self = [super initWithNibName:nibName bundle:nil];
    if (self) 
    {
        // Custom initialization.
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

        if (startingDate == nil)
        {
            startingDate = [NSDate dateToNearestSecond];
        }
        
        [self setPickedDate:startingDate];
        minimumDate_ = minDate;
        maximumDate_ = maxDate;
    }
    
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    self.datePicker.minimumDate = self.minimumDate;
    self.datePicker.maximumDate = self.maximumDate;
    [self.datePicker setDate:self.pickedDate animated:NO];
}



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender
{
    NSLog(@"cancel pressed...");
    
    canceled_ = YES;
    
    [self setPickedDate:nil];
    
    [self.delegate datePickerViewControllerReadyToBeDismissed:self pickedDate:nil];   
}

- (IBAction)done:(id)sender
{
    NSLog(@"done pressed...");
    
    canceled_ = NO;
    
    UIDatePicker *datePicker = [self datePicker];
    
    [self setPickedDate:[datePicker date]];
    
    [self.delegate datePickerViewControllerReadyToBeDismissed:self pickedDate:[datePicker date]];;   
}

@end
