//
//  BPGraphOptionsViewController.m
//  BPTracker
//
//  Created by Robert Saccone on 8/29/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BPGraphOptionsViewController.h"

#import <SLexUtil/PlatformHelper.h>
#import <SLexUtil/NSDate+UtilityExtensions.h>
#import <SLexUtil/SLXDateRangePickerCoordinator.h>

#import "BPGraphSettings.h"

@interface BPGraphOptionsViewController ()<UITextFieldDelegate, SLXDateRangePickerCoordinatorDelegate>

- (void)setFieldsFromProperties;
- (void)updateGraphSettingsFromFields;
- (void)showModalViewController:(UIViewController *)viewController;

@property(nonatomic, strong) NSDate *dateRangeMin;
@property(nonatomic, strong) NSDate *dateRangeMax;
@property(nonatomic, strong) SLXDateRangePickerCoordinator *dateRangePickerCoordinator;
@property(nonatomic, copy)   BPGraphSettings *bpGraphSettings;
@property(nonatomic, weak) id<BPGraphOptionsViewControllerDelegate> delegate;

@end

@implementation BPGraphOptionsViewController
{
@private
	UITextField     * __weak startDateField_;
    UITextField     * __weak endDateField_;
    UISwitch        * __weak systolicDataSwitch_;
    UISwitch        * __weak diastolicDataSwitch_;
    UISwitch        * __weak pulseDataSwitch_;
    UISwitch        * __weak legendDataSwitch_;
    NSDate          *dateRangeMin_;
    NSDate          *dateRangeMax_;
    SLXDateRangePickerCoordinator *dateRangePickerCoordinator_;
    BPGraphSettings *bpGraphSettings_;
    id<BPGraphOptionsViewControllerDelegate> __weak delegate_;
    BOOL            canceled_;
    BOOL            saved_;
}

@synthesize startDateField = startDateField_;
@synthesize endDateField = endDateField_;
@synthesize systolicDataSwitch = systolicDataSwitch_;
@synthesize diastolicDataSwitch = diastolicDataSwitch_;
@synthesize pulseDataSwitch = pulseDataSwitch_;
@synthesize legendDataSwitch = legendDataSwitch_;
@synthesize dateRangeMin = dateRangeMin_;
@synthesize dateRangeMax = dateRangeMax_;
@synthesize dateRangePickerCoordinator = dateRangePickerCoordinator_;
@synthesize bpGraphSettings = bpGraphSettings_;
@synthesize canceled = canceled_;
@synthesize saved = saved_;
@synthesize delegate = delegate_;


// The designated initializer of the base.  Override if you create the controller programmatically and want to perform customization
// that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithStartDateRangeMin:nil endDateRangeMax:nil graphSettings:nil viewControllerDelegate:nil];
}

static void validateAndSetGraphRangePoints(NSDate *dateRangeStart,
                                           NSDate *dateRangeEnd,
                                           BPGraphSettings *graphSettings)
{
    if (!graphSettings.graphDateRangeStart ||
        ([graphSettings.graphDateRangeStart compare:dateRangeStart] == NSOrderedAscending))
    {
        graphSettings.graphDateRangeStart = dateRangeStart;
    }
    
    if (!graphSettings.graphDateRangeEnd ||
        ([graphSettings.graphDateRangeEnd compare:dateRangeEnd] == NSOrderedDescending))
    {
        graphSettings.graphDateRangeEnd = dateRangeEnd;
    }
    
    if ([graphSettings.graphDateRangeStart compare:dateRangeEnd] == NSOrderedDescending)
    {
        graphSettings.graphDateRangeStart = dateRangeStart;
    }
    
    if ([graphSettings.graphDateRangeEnd compare:dateRangeStart] == NSOrderedAscending)
    {
        graphSettings.graphDateRangeEnd = dateRangeEnd;
    }
}

// Designated initializer for this class.
- (id)initWithStartDateRangeMin:(NSDate *)startDateMin
                endDateRangeMax:(NSDate *)endDateMax
                   graphSettings:(BPGraphSettings *)bpGraphSettings
         viewControllerDelegate:(id<BPGraphOptionsViewControllerDelegate>)vcDelegate;
{
    if (startDateMin == nil)
    {
        NSLog(@"BPGraphOptionsViewController: nil startDateMin passed!");
        return nil;
    }
    
    if (endDateMax == nil)
    {
        NSLog(@"BPGraphOptionsViewController: nil endDateMax passed!");
        
        return nil;
    }
    
    if (bpGraphSettings == nil)
    {
        NSLog(@"BPGraphOptionsViewController: nil bpGraphSettings passed!");
        return nil;
    }
    
    if (vcDelegate == nil)
    {
        NSLog(@"BPGraphOptionsViewController: nil vcDelegate passed!");
        return nil;
    }
    
    if ([startDateMin compare:endDateMax] == NSOrderedDescending)
    {
        NSLog(@"BPGraphOptionsViewController: startDateMin > endDateMax!");
        return nil;
    }
    
    static NSString * const nibName = @"BPGraphOptionsViewController";
    
    self = [super initWithNibName:nibName bundle:nil];
    
    if (self)
    {
        saved_ = NO;
        canceled_ = NO;
        
        dateRangeMin_ = startDateMin;
        dateRangeMax_ = endDateMax;
        bpGraphSettings_ = bpGraphSettings;
        delegate_ = vcDelegate;
        
        validateAndSetGraphRangePoints(self.dateRangeMin, self.dateRangeMax, self.bpGraphSettings);

        UINavigationItem *navItem = [self navigationItem];
        
        [navItem  setHidesBackButton:YES animated:NO];
        
        UIBarButtonItem *bbi;
        
        bbi = [[UIBarButtonItem alloc]
               initWithBarButtonSystemItem:UIBarButtonSystemItemDone
               target:self
               action:@selector(doneAction:)];
        
        [navItem setRightBarButtonItem:bbi];
        
        // Cancel item
        bbi = [[UIBarButtonItem alloc]
               initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
               target:self
               action:@selector(cancelAction:)];
        
        [navItem setLeftBarButtonItem:bbi];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"BPGRAPH_OPTIONS_TITLE", nil);
    
    self.dateRangePickerCoordinator = [[SLXDateRangePickerCoordinator alloc] initWithStartRangeTextField:self.startDateField
                                                                                       endRangeTextField:self.endDateField];
    
    self.dateRangePickerCoordinator.delegate = self;
    
    self.dateRangePickerCoordinator.minDate = self.dateRangeMin;
    self.dateRangePickerCoordinator.maxDate = self.dateRangeMax;
    
    [self setFieldsFromProperties];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Data Transfer To/From Fields

- (void)setFieldsFromProperties
{
    self.dateRangePickerCoordinator.startDate = self.bpGraphSettings.graphDateRangeStart;
    self.dateRangePickerCoordinator.endDate = self.bpGraphSettings.graphDateRangeEnd;
    [self.systolicDataSwitch setOn:self.bpGraphSettings.systolicData];
    [self.diastolicDataSwitch setOn:self.bpGraphSettings.diasotlicData];
    [self.pulseDataSwitch setOn:self.bpGraphSettings.pulseData];
    [self.legendDataSwitch setOn:self.bpGraphSettings.legend];
}

- (void)updateGraphSettingsFromFields
{
    self.bpGraphSettings.systolicData = self.systolicDataSwitch.on;
    self.bpGraphSettings.diasotlicData = self.diastolicDataSwitch.on;
    self.bpGraphSettings.pulseData = self.pulseDataSwitch.on;
    self.bpGraphSettings.legend = self.legendDataSwitch.on;
}

#pragma mark - UITextField Notifications

- (void)showModalViewController:(UIViewController *)viewController
{
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    [self presentViewController:navController animated:YES completion:NULL];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

#pragma mark - Actions

- (IBAction)cancelAction:(id)sender
{
    NSLog(@"cancel pressed...");
    
    canceled_ = YES;
    
    BOOL dismissed = [self.delegate done:self];
    
    #pragma unused(dismissed)
    
    NSAssert(dismissed, @"dismised expected to be true!");
}

- (IBAction)doneAction:(id)sender
{
    NSLog(@"done button pressed...");
    
    [self updateGraphSettingsFromFields];
    
    saved_ = YES;
    
    BOOL dismissed = [self.delegate done:self];
    
    #pragma unused(dismissed)
    
    NSAssert(dismissed, @"dismised expected to be true!");
}

#pragma mark - SLXDateRangePickerCoordinator delegate methods

- (void)dateRangeUpdated:(SLXDateRangePickerCoordinator *)coordinator componentUpdated:(DateRangeComponent)updatedComponent
{
    if ((updatedComponent == Start) || (updatedComponent == Both))
    {
        self.bpGraphSettings.graphDateRangeStart = coordinator.startDate;
    }
    
    if ((updatedComponent == End) || (updatedComponent == Both))
    {
        self.bpGraphSettings.graphDateRangeEnd = coordinator.endDate;
    }
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

@end
