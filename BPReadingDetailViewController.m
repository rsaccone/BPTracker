//
//  BPReadingDetailView.m
//  BPTracker
//
//  Created by Robert Saccone on 1/30/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BPReadingDetailViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <SLexUtil/DispatchingAlertView.h>
#import <SLexUtil/NSDate+UtilityExtensions.h>
#import <SLexUtil/NumericUtil.h>
#import <SLexUtil/PlatformHelper.h>
#import <SLexUtil/UIAlertView+Blocks.h>
#import <SLexUtil/UIViewController+HelperExtensions.h>
#import <SLexUtil/ViewHelper.h>
#import "DatePickerViewController.h"
#import "BloodPressureReading.h"
#import "BloodPressureDataAnalyzer.h"
#import "NoteTakerViewController.h"
#import "UserSettingKeys.h"


typedef enum NotesFieldContentState
{
    SetPlaceHolderText,
    PlaceHolderText,
    UserText
} NOTESFIELDCONTENTSTATE;

static NSString * const NotesPlaceHolderText = @"Notes";

#define EXTRA_VISIBILITY_HEIGHT     5   // Extra height buffer when scrolling a field into view
                                        // so the edge of the field doesn't end up right at the
                                        // bottom or top of the visible area.

@interface InvalidDataEntryContext : NSObject
{
}

@property(nonatomic, strong) UIView *field;
@property(nonatomic, assign) BPComponent errorComponent;

@end

@implementation InvalidDataEntryContext

@synthesize field;
@synthesize errorComponent;

@end

// Class extension using anonymous category to hide
// currBloodPressureReading property from consumers
// of the class.
@interface BPReadingDetailViewController () <NoteTakerViewControllerDelegate, DatePickerViewControllerDelegate>

- (id)init:(BloodPressureReading *)bloodPressureReading newReading:(BOOL)newBPReading
                                            setDefaultsFromReading:(BOOL)defaultFromReading
                                            viewControllerDelegate:(id<BPReadingDetailViewControllerDelegate>)vcDelegate
                                            doneUpdatingReadingBlock:(DoneUpdatingBloodPressureReadingBlock)doneBlock;

- (void)registerForNotifications;
- (void)unregisterForNotifications;

- (NSNumber *)validateBPComponentFromText:(NSString *)text bpComponent:(BPComponent)component;
- (void)displayInvalidBPComponentAlert:(BPComponent)component field:(UIView *)field;

- (NSString *)getTextViewName:(UITextView *)textView;
- (NSString *)getTextFieldName:(UITextField *)textField;

- (void)setNotesPlaceHolderText;
- (void)setNotesTextFromReading;
- (void)setWeightFieldFromDefaults;
- (void)setFieldsFromDefaults;
- (void) setDateTextFieldFromDate:(NSDate *)date setDatePicker:(BOOL)setPicker;
- (void)setFieldsFromReading;
- (void)makeFieldFirstResponder:(UIView *)field;

- (void)restoreInsets;
- (void)scrollViewToCenterOfScreen:(UIView *)theView; 
- (void)ensureViewIsVisible:(UIView *)theView;

- (void)showModalViewController:(UIViewController *)viewController;

- (void)switchMode:(BOOL)editMode;
- (void)cancelEditMode;

- (NSNumber *)validateTextFieldData:(UITextField *)textField bloodPressureComponent:(BPComponent)bpComponent;

- (IBAction)cancelAction:(id)sender;
- (IBAction)doneAction:(id)sender;
- (IBAction)editAction:(id)sender;

- (void)sendDoneNotification:(BOOL)saved;

// Properties for IB.
@property(nonatomic, weak) IBOutlet UITextField   *systolicField;
@property(nonatomic, weak) IBOutlet UITextField   *diastolicField;
@property(nonatomic, weak) IBOutlet UITextField   *readingDateField;
@property(nonatomic, weak) IBOutlet UITextField   *pulseField;
@property(nonatomic, weak) IBOutlet UITextField   *weightField;
@property(nonatomic, weak) IBOutlet UITextView    *notesField;
@property(nonatomic, weak) IBOutlet UIScrollView  *scrollView;
@property(nonatomic, weak) IBOutlet UIView *contentView;

@property(nonatomic, weak) id<BPReadingDetailViewControllerDelegate> delegate;
@property(nonatomic, copy) DoneUpdatingBloodPressureReadingBlock doneUpdatingReadingBlock;
@property(nonatomic, strong) NSArray *entryFields;
@property(nonatomic, strong) NSDate *originalReadingDate;
@property(nonatomic, strong) NSDate *readingDate;
@property(nonatomic, strong) UIView *firstResponder;
@property(nonatomic, strong) NSDateFormatter *dateFormatter;
@property(nonatomic, strong) UIColor *noteViewUserTextColor;
@property(nonatomic, assign) CGRect kbBounds;
@property(nonatomic, assign) BOOL keyboardVisible;
@property(nonatomic, assign) BOOL editMode;
@property(nonatomic, assign) BOOL newReading;
@property(nonatomic, weak) id keyboardDidShowObserver;
@property(nonatomic, weak) id keyboardWillHideObserver;

@end

#pragma mark - Properties

@implementation BPReadingDetailViewController
{
@private
    id<BPReadingDetailViewControllerDelegate> __weak delegate_;
    DoneUpdatingBloodPressureReadingBlock __strong doneUpdatingReadingBlock_;
    
	UITextField     * __weak systolicField_;
    UITextField     * __weak diastolicField_;
    UITextField     * __weak readingDateField_;
    UITextField     * __weak pulseField_;
    UITextField     * __weak weightField_;
    UITextView      * __weak notesField_;
    UIScrollView    * __weak scrollView_;
    UIView          * __strong firstResponder_;
    UIView          * __weak contentView_;
    UIColor         * __strong notesViewUserTextColor_;
    
    BloodPressureReading *bloodPressureReading_;
    
    NSArray         *entryFields_;
    NSDate          *originalReadingDate_;
    NSDate          *readingDate_;
    NSDateFormatter *dateFormatter_;
    BOOL            canceled_;
    BOOL            keyboardVisible_;
    BOOL            allowEditing_;
    BOOL            editMode_;
    BOOL            updated_;
    BOOL            newReading_;
    BOOL            setDefaultsFromReading_;
    CGPoint         oldContentOffset_;
    UIEdgeInsets    oldContentInset_;
    UIEdgeInsets    oldIndicatorInset_;
    CGRect          kbBounds_;
    
    NOTESFIELDCONTENTSTATE notesFieldContentState_;
}

@synthesize delegate = delegate_;
@synthesize doneUpdatingReadingBlock = doneUpdatingReadingBlock_;
@synthesize bloodPressureReading=bloodPressureReading_;
@synthesize canceled=canceled_;
@synthesize keyboardVisible = keyboardVisible_;
@synthesize allowEditing=allowEditing_;
@synthesize editMode=editMode_;
@synthesize newReading=newReading_;
@synthesize updated=updated_;
@synthesize systolicField=systolicField_;
@synthesize diastolicField=diastolicField_;
@synthesize originalReadingDate=originalReadingDate_;
@synthesize readingDateField=readingDateField_;
@synthesize pulseField=pulseField_;
@synthesize weightField=weightField_;
@synthesize entryFields=entryFields_;
@synthesize readingDate=readingDate_;
@synthesize notesField=notesField_;
@synthesize scrollView=scrollView_;
@synthesize firstResponder=firstResponder_;
@synthesize contentView=contentView_;
@synthesize dateFormatter=dateFormatter_;
@synthesize noteViewUserTextColor = noteViewUserTextColor_;
@synthesize kbBounds=kbBounds_;
@synthesize keyboardWillHideObserver;
@synthesize keyboardDidShowObserver;

#pragma mark - Initialization

- (id)init:(BloodPressureReading *)bloodPressureReading newReading:(BOOL)newBPReading
                                            setDefaultsFromReading:(BOOL)defaultFromReading
                                            viewControllerDelegate:(id<BPReadingDetailViewControllerDelegate>)vcDelegate
                                            doneUpdatingReadingBlock:(DoneUpdatingBloodPressureReadingBlock)doneBlock
{
    // Must pass a blood pressure reading!.
    NSAssert(bloodPressureReading != nil, @"bloodPressureReading is nil!");
    NSAssert((vcDelegate != nil || doneBlock != nil), @"vcDelegate or doneBlock must be non-nil!");
    NSAssert(vcDelegate == nil || doneBlock == nil, @"Only one of vcDelegate or doneBlock can be nil!");
    
    static NSString * const nibName = @"BPReadingDetailViewController";
    
    self = [super initWithNibName:nibName bundle:nil];
    
    if (self)
    {
        newReading_ = newBPReading;
        allowEditing_ = YES;
        editMode_ = newReading_;
        bloodPressureReading_ = bloodPressureReading;
        delegate_ = vcDelegate;
        
        if (doneBlock != nil)
        {
            doneUpdatingReadingBlock_ = [doneBlock copy];
        }
        
        setDefaultsFromReading_ = defaultFromReading;

        if (!setDefaultsFromReading_ || !bloodPressureReading.readingDate)
        {
            originalReadingDate_ = [NSDate dateToNearestSecond];
            readingDate_ = originalReadingDate_;
        }
        else
        {
            originalReadingDate_ = bloodPressureReading.readingDate;
            readingDate_ = bloodPressureReading.readingDate;
        }
        
        // If this is a new item then start out in editing mode.
        //[self switchMode:newBPReading_];
    }
    
    return self;
}

// Designated initializer for this class.
- (id)init:(BloodPressureReading *)bloodPressureReading newReading:(BOOL)newBPReading
                                            setDefaultsFromReading:(BOOL)defaultsFromReading
                                                    doneCallback:(DoneUpdatingBloodPressureReadingBlock)doneCallbackBlock
{
    return [self init:bloodPressureReading newReading:newBPReading
                               setDefaultsFromReading:defaultsFromReading
                               viewControllerDelegate:nil
                             doneUpdatingReadingBlock:doneCallbackBlock];
}

- (id)init:(BloodPressureReading *)bloodPressureReading newReading:(BOOL)newBPReading
                                            setDefaultsFromReading:(BOOL)defaultFromReading
                                            viewControllerDelegate:(id<BPReadingDetailViewControllerDelegate>)vcDelegate
{
    return [self init:bloodPressureReading newReading:newBPReading
                               setDefaultsFromReading:defaultFromReading
                               viewControllerDelegate:vcDelegate
                             doneUpdatingReadingBlock:nil];
}

// The designated initializer of the base.  Override if you create the controller programmatically
// and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    return [self init:nil newReading:YES setDefaultsFromReading:YES viewControllerDelegate:nil];
}

#pragma mark - Various Field and Utility Methods

- (void) setDateTextFieldFromDate:(NSDate *)date setDatePicker:(BOOL)setPicker
{
    NSString *formattedDateString = [self.dateFormatter stringFromDate:date];
    
    [[self readingDateField] setText:formattedDateString];

    if (setPicker)
    {
        UIDatePicker *picker = (UIDatePicker*)self.readingDateField.inputView;
        picker.date = date;
    }
}

- (void)setWeightFieldFromDefaults
{
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:weightEntryDefaultValueKey];
    
    if (value)
    {
        if ([value shortValue] > 0)
        {
            [[self weightField] setText:[value stringValue]];
        }
    }
}

- (void)setNotesPlaceHolderText
{
    self.notesField.textColor = [UIColor lightGrayColor];
    self.notesField.text = NSLocalizedString(@"BP_READING_NOTES_PLACEHOLDER_TEXT", @"Notes");;
    
    if (self.notesField.isFirstResponder)
    {
        self.notesField.selectedRange = NSMakeRange(0, 0);
    }
    
    notesFieldContentState_ = PlaceHolderText;
}

- (void)setNotesTextFromReading
{
    if ((self.bloodPressureReading.note != nil) && (self.bloodPressureReading.note.length > 0))
    {
        self.notesField.textColor = self.noteViewUserTextColor;
        self.notesField.text = self.bloodPressureReading.note;
        notesFieldContentState_ = UserText;
    }
    else
    {
        [self setNotesPlaceHolderText];
    }
}

- (void)setFieldsFromDefaults
{
    [self setDateTextFieldFromDate:[self readingDate] setDatePicker:YES];
    [self setWeightFieldFromDefaults];
    [self setNotesPlaceHolderText];
}

- (void)setFieldsFromReading
{
    [self setDateTextFieldFromDate:[self readingDate] setDatePicker:YES];
    [[self systolicField] setText:[[[self bloodPressureReading] systolic] stringValue]];
    [[self diastolicField] setText:[[[self bloodPressureReading] diastolic] stringValue]];
    [[self pulseField] setText:[[[self bloodPressureReading] pulse] stringValue]];
    [[self weightField] setText:[[[self bloodPressureReading] weight] stringValue]];
    [self setNotesTextFromReading];
}

- (void)clearTextFields
{
    [[self readingDateField] setText:nil];
    [[self systolicField] setText:nil];
    [[self diastolicField] setText:nil];
    [[self pulseField] setText:nil];
    [[self weightField] setText:nil];
    [self setNotesPlaceHolderText];
}

- (void)switchMode:(BOOL)editMode
{
    UINavigationItem *navItem = [self navigationItem];
    
    if (!navItem)
    {
        return;
    }
    
    if (editMode && allowEditing_)
    {
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
            
        editMode_ = YES;
    }
    else
    {
        UISplitViewController *splitViewController = self.splitViewController;
        
        if (!splitViewController)
        {
            [navItem setLeftBarButtonItem:nil];
            
            [navItem setHidesBackButton:NO animated:YES];
        }
        else
        {
            [navItem setLeftBarButtonItem:nil];
            
            [navItem setHidesBackButton:YES animated:NO];
        }
        
        UIBarButtonItem *bbi = nil;

        // Creating new item
        bbi = [[UIBarButtonItem alloc]
               initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
               target:self
               action:@selector(editAction:)];

        bbi.enabled = allowEditing_;
        
        [navItem setRightBarButtonItem:bbi];
        
        // If the keyboard is showing then hide it.
        UIView *firstResp = [self firstResponder];
        
        if (firstResp != nil)
        {
            [firstResp resignFirstResponder];
            [self setFirstResponder:nil];
        }
            
        editMode_ = NO;
    }
    
    if (self.delegate)
    {
        [self.delegate modeChanged:editMode];
    }
}

- (void)cancelEditMode
{
    NSLog(@"cancelEditMode");
    
    if (self.editMode)
    {
        canceled_ = YES;
        
        if (newReading_)
        {
            [self sendDoneNotification:NO];
        }
        else
        {
            self.readingDate = self.originalReadingDate;
            
            if (setDefaultsFromReading_)
            {
                [self setFieldsFromReading];
            }
            else
            {
                [self clearTextFields];
                [self setDateTextFieldFromDate:[self originalReadingDate] setDatePicker:YES];
                [self setWeightFieldFromDefaults];
            }
            
            [self switchMode:NO];
        }
    }
}

- (void)makeFieldFirstResponder:(UIView *)field
{
    UIView *currFirstResponder = [self firstResponder];
    
    if (currFirstResponder != field)
    {
        if (currFirstResponder != nil)
        {
            if (![currFirstResponder resignFirstResponder])
            {
                NSLog(@"makeFieldFirstResponder: %@ resignFirstResponder returned NO", currFirstResponder); 
                return;
            }
        }
        
        if (field != nil)
        {
            if (![field becomeFirstResponder])
            {
                NSLog(@"makeFieldFirstResponder: %@ becomeFirstResponder returned NO", field); 
                field = nil;
            }
        }
        
        [self setFirstResponder:field];
    }
}

- (NSNumber *)validateTextFieldData:(UITextField *)textField bloodPressureComponent:(BPComponent)bpComponent
{
    NSNumber *value = [self validateBPComponentFromText:[textField text] bpComponent:bpComponent];
    
    if (value == nil)
    {
        [self displayInvalidBPComponentAlert:bpComponent field:textField];
        
        return nil;
    }
    
    return value;
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    if (newReading_)
    {
        self.title = NSLocalizedString(@"NEW_BPREADING_DETAIL_VC_TITLE", nil);
    }
    else
    {
        self.title = NSLocalizedString(@"BPREADING_DETAIL_VC_TITLE", nil);
    }
    
    // Capture the text color of the UITextView for the notes field
    // as it will be changed when the place holder text is put in place.
    self.noteViewUserTextColor = self.notesField.textColor;
    
    
//    [[[self notesField] layer] setBorderWidth:1.0f];
//    [[[self notesField] layer] setBorderColor:[[UIColor grayColor] CGColor]];

    // In order to handle device rotation correctly for views that are located inside
    // of scroll views, leading and trailing constraints must be set between the
    // the content view and the view above the scroll view in the hierarchy (self.view).
#if 0
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:0
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1.0
                                                                       constant:0];
    [self.view addConstraint:leftConstraint];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:0
                                                                          toItem:self.view
                                                                       attribute:NSLayoutAttributeRight
                                                                      multiplier:1.0
                                                                        constant:0];
    [self.view addConstraint:rightConstraint];
    
#else
    
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:0
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeLeading
                                                                     multiplier:1.0
                                                                       constant:0];
    [self.view addConstraint:leftConstraint];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:0
                                                                          toItem:self.view
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1.0
                                                                        constant:0];
    [self.view addConstraint:rightConstraint];
    
#endif
    
    self.automaticallyAdjustsScrollViewInsets = YES;

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];

    self.dateFormatter = dateFormatter;
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
    [datePicker addTarget:self action:@selector(updateReadingDateField:) forControlEvents:UIControlEventValueChanged];
    [self.readingDateField setInputView:datePicker];

    if (setDefaultsFromReading_)
    {
        [self setFieldsFromReading];
    }
    else
    {
        [self setFieldsFromDefaults];
    }
    
    [self switchMode:self.editMode];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Initially the keyboard is hidden.
    self.keyboardVisible = NO;
    
    [self registerForNotifications];
    
    UISplitViewController *splitViewController = self.splitViewController;
    
    // If the view is in a split view controller than hide the back button.
    if (splitViewController)
    {
        [self.navigationItem  setHidesBackButton:YES animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self unregisterForNotifications];
    
    UIView *firstResp = [self firstResponder];
    
    if (firstResp != nil)
    {
        [firstResp resignFirstResponder];
        [self setFirstResponder:nil];
    }
    
    if (!self.presentedViewController && self.editMode)
    {
        [self cancelEditMode];
    }
    
    [super viewDidDisappear:animated];
}

#pragma mark - Ensure View Visibility

- (void)ensureViewIsVisible:(UIView *)theView
{
    // If theView is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGSize kbSize = self.kbBounds.size;
    CGRect detailViewFrameRect = self.view.frame;
    
    detailViewFrameRect = [self.view convertRect:detailViewFrameRect fromView:self.view.superview];
    
    if (CGRectIntersectsRect(detailViewFrameRect, self.kbBounds))
    {
        detailViewFrameRect.size.height -= kbSize.height;
    }
    
    CGRect viewFrameRect = [theView frame];
    CGPoint scrollContentOffset = self.scrollView.contentOffset;
    
    CGPoint origin = viewFrameRect.origin;
    origin.y -= scrollContentOffset.y;
    viewFrameRect.origin.x -= scrollContentOffset.x;
    viewFrameRect.origin.y -= scrollContentOffset.y;
    
    if (!CGRectContainsRect(detailViewFrameRect, viewFrameRect))
    {
        // Is the field hidden by the keyboard on the bottom
        // of the screen?
        if (origin.y >= detailViewFrameRect.origin.y)
        {
            // Scroll the view into view.  Note that the height of the view is subtracted off detailViewFrameRect
            // (plus some additional buffer) so the whole field will be visible.
            CGPoint scrollPoint = CGPointMake(0.0, theView.frame.origin.y - detailViewFrameRect.origin.y - self.topOfViewOffset);

            [self.scrollView setContentOffset:scrollPoint animated:YES];
        }
        else
        {
            // Keyboard is scrolled off the top of the screen.
            CGPoint scrollPoint = CGPointMake(0.0, theView.frame.origin.y - EXTRA_VISIBILITY_HEIGHT);
            [self.scrollView setContentOffset:scrollPoint animated:YES];
        }
    }
}

- (void)scrollViewToCenterOfScreen:(UIView *)theView
{
    return;
#if 0
	CGFloat viewCenterY = theView.center.y;
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
    
	CGFloat availableHeight = applicationFrame.size.height - self.kbBounds.size.height;	// Remove area covered by keyboard
    
	CGFloat y = viewCenterY - availableHeight / 2.0;
	if (y < 0)
    {
		y = 0;
	}
	self.scrollView.contentSize = CGSizeMake(applicationFrame.size.width, applicationFrame.size.height + self.kbBounds.size.height);
	[self.scrollView setContentOffset:CGPointMake(0, y) animated:YES];
#endif
}

#pragma mark - Keyboard Related Notifications

- (void) restoreInsets
{
    [[self scrollView] setScrollIndicatorInsets:oldIndicatorInset_];
    [[self scrollView] setContentInset:oldContentInset_];
    [[self scrollView] setScrollEnabled:NO];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark - Notification Management

- (void)registerForNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    BPReadingDetailViewController * __weak weakSelf = self;
    
    self.keyboardDidShowObserver = [center addObserverForName:UIKeyboardDidShowNotification
                                                       object:nil
                                                        queue:mainQueue
                                                   usingBlock:^(NSNotification *notification)
                                    {
                                        BPReadingDetailViewController *strongSelf = weakSelf;
                                        
                                        if (strongSelf)
                                        {
                                            if (strongSelf.keyboardVisible)
                                            {
                                                NSLog(@"Keyboard is already visible.  Ignoring notification.");
                                                return;
                                            }
                                            
                                            NSDictionary* info = [notification userInfo];
                                            
                                            NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
                                            
                                            CGRect screenRectKBFrame = [kbFrame CGRectValue];
                                            CGRect windowRectKBFrame = [self.view.window convertRect:screenRectKBFrame fromWindow:nil];
                                            CGRect viewRectKBFrame = [self.view convertRect:windowRectKBFrame fromView:nil];
             
                                            strongSelf.kbBounds = viewRectKBFrame;
                                            CGSize kbSize = viewRectKBFrame.size;
                                            oldContentInset_ = strongSelf.scrollView.contentInset;
                                            
                                            CGRect detailViewFrameRect = strongSelf.view.frame;
                                            
                                            detailViewFrameRect = [strongSelf.view convertRect:detailViewFrameRect fromView:strongSelf.view.superview];
                                            
                                            if (CGRectIntersectsRect(detailViewFrameRect, strongSelf.kbBounds))
                                            {
                                                UIEdgeInsets contentInsets = UIEdgeInsetsMake(oldContentInset_.top,
                                                                                              oldContentInset_.left,
                                                                                              oldContentInset_.bottom + kbSize.height,
                                                                                              oldContentInset_.right);
                                                
                                                strongSelf.scrollView.contentInset = contentInsets;
                                                strongSelf.scrollView.scrollIndicatorInsets = contentInsets;
                                            }
                                            
                                            // Make sure the first responder is visible on the screen.
                                            
                                            if (strongSelf.firstResponder != nil)
                                            {
                                                [strongSelf ensureViewIsVisible:strongSelf.firstResponder];
                                            }
                                            
                                            strongSelf.keyboardVisible = YES;
                                        }
                                    }];
    
    
    self.keyboardWillHideObserver = [center addObserverForName:UIKeyboardWillHideNotification
                                                        object:nil
                                                         queue:mainQueue
                                                    usingBlock:^(NSNotification *notification)
                                     {
                                         BPReadingDetailViewController * strongSelf = weakSelf;
                                         
                                         if (strongSelf)
                                         {
                                             if (!strongSelf.keyboardVisible)
                                             {
                                                 NSLog(@"Keyboard already hidden.  Ignoring notification.");
                                                 return;
                                             }
                                             
                                             NSLog(@"Resetting the content offset to the old value.");
                                             
                                             [[strongSelf scrollView] setContentInset:oldContentInset_];
                                             [[strongSelf scrollView] setScrollIndicatorInsets:oldContentInset_];
                                             
                                             strongSelf.keyboardVisible = NO;
                                         }
                                     }];
}

- (void)unregisterForNotifications
{
    // Unregister from all notifications for this observer.
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    if (self.keyboardDidShowObserver != nil)
    {
        [center removeObserver:self.keyboardDidShowObserver name:UIKeyboardDidShowNotification object:nil];
    }
    
    if (self.keyboardWillHideObserver != nil)
    {
        [center removeObserver:self.keyboardWillHideObserver name:UIKeyboardWillHideNotification object:nil];
    }
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)dealloc
{
    [self unregisterForNotifications];
}

#pragma mark - entryfields get property

- (NSArray *)entryFields
{
    if (entryFields_ == 0)
    {
        [self setEntryFields:[ViewHelper viewEntryFields:[self view]]];
    }
    
    return entryFields_;
}

#pragma mark - allowEditing Property

- (void)setAllowEditing:(BOOL)allowEditing
{
    if (allowEditing_ != allowEditing)
    {
        allowEditing_ = allowEditing;
        
        if (!allowEditing)
        {
            if (self.editMode)
            {
                [self cancelEditMode];
                
                return;
            }
        }
        
        [self switchMode:NO];
    }
}

#pragma mark - UITextField Notifications

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Deleting?
    if ([string length] == 0)
        return YES;
    
    return [NumericUtil stringContainsUnsignedInteger:string];
}

- (NSString *)getTextFieldName:(UITextField *)textField
{
    if (textField == systolicField_)
        return @"Systolic Field";
    
    if (textField == diastolicField_)
        return @"Diastolic Field";
    
    if (textField == readingDateField_)
        return @"Reading Date Field";
    
    if (textField == pulseField_)
        return @"Pulse Field";
    
    if (textField == weightField_)
        return @"Weight Field";
    
    return @"Unknown";
}

- (void)showModalViewController:(UIViewController *)viewController
{
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    [self presentViewController:navController animated:YES completion:NULL];
    
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    NSLog(@"textFieldShouldBeginEditing called for: %@ with text: %@", 
          [self getTextFieldName:textField],[textField text]);

    // Don't allow editing if not in edit mode.
    if (!editMode_)
    {
        return NO;
    }
    
    return YES;
}
                                    
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSLog(@"textFieldDidBeginEditing called for: %@ with text: %@", 
          [self getTextFieldName:textField],[textField text]);
    
    BOOL success = [textField becomeFirstResponder];
    
    NSLog(@"textFieldDidBeginEditing: called for : %@, is first responder = <%@>", 
          [self getTextFieldName:textField], (success ? @"YES" : @"NO"));
    
    if (success)
    {
        [self setFirstResponder:textField];
        
        if (keyboardVisible_)
        {
            NSLog(@"textFieldDidBeginEditing: Keyboard is visible ensuring %@ is visible.",
                  [self getTextFieldName:textField]);
            
            // Make sure the new first responder is visible on the screen.
            [self ensureViewIsVisible:textField];
        }
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    NSLog(@"textFieldShouldEndEditing called for: %@ with text: %@", 
          [self getTextFieldName:textField],[textField text]);
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"textFieldDidEndEditing called for: %@ with text: %@", 
          [self getTextFieldName:textField],[textField text]);
    
    if (self.firstResponder == textField)
    {
        self.firstResponder = nil;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"textFieldShouldReturn called for: %@ with text: %@", 
          [self getTextFieldName:textField],[textField text]);
    
    return [ViewHelper textFieldShouldReturn:textField viewEntryFields:[self entryFields]];
}

- (void)updateReadingDateField:(id)sender
{
    UIDatePicker *picker = (UIDatePicker*)self.readingDateField.inputView;
    NSDate *date = picker.date;
    [self setReadingDate:date];
    [self setDateTextFieldFromDate:date setDatePicker:NO];
}

#pragma mark -
#pragma mark UITextView notifications

- (NSString *)getTextViewName:(UITextView *)textView
{
    if (textView == notesField_)
        return @"Notes Field";
    
    return @"Unknown";
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    NSLog(@"textViewShouldBeginEditing called for: %@ with text: %@", 
          [self getTextViewName:textView],[textView text]);
    
    // Don't allow editing if not in edit mode.
    if (!editMode_)
    {
        return NO;
    }
    
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    NSLog(@"textViewDidBeginEditing called for: %@ with text: %@", 
          [self getTextViewName:textView],[textView text]);
    
    bool success = [textView becomeFirstResponder];
    
    NSLog(@"textViewDidBeginEditing: called for : %@, is first responder = <%@>", 
          [self getTextViewName:textView], (success ? @"YES" : @"NO"));
    
    if (success)
    {
        [self setFirstResponder:textView];

        if (keyboardVisible_)
        {
            // Make sure the new first responder is visible on the screen.
            [self ensureViewIsVisible:textView];
        }
        
        if ((textView == self.notesField) && (notesFieldContentState_ == PlaceHolderText))
        {
            // BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG
            // Some sort of bug where setting the selectedRange while in this
            // delegate method doesn't affect the cursor position. To work around
            // schedule a block to be run on the main queue when the event
            // loop runs again.
            // BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG BUG
            dispatch_async(dispatch_get_main_queue(), ^{
                textView.selectedRange = NSMakeRange(0, 0);
            });
        }
    }
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    NSLog(@"textViewShouldEndEditing called for: %@ with text: %@", 
          [self getTextViewName:textView],[textView text]);
    
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    NSLog(@"textFieldDidEndEditing called for: %@ with text: %@", 
          [self getTextViewName:textView],[textView text]);
}

- (BOOL)textViewShouldReturn:(UITextView *)textView
{
    NSLog(@"textViewShouldReturn called for: %@ with text: %@", 
          [self getTextViewName:textView],[textView text]);
    
    [textView resignFirstResponder];
    
    [self setFirstResponder:nil];
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (textView == self.notesField)
    {
        if (notesFieldContentState_ == PlaceHolderText)
        {
            self.notesField.textColor = self.noteViewUserTextColor;
            self.notesField.text = text;
            notesFieldContentState_ = UserText;
            return NO;
        }
    }
    
    return YES;
}
- (void)textViewDidChange:(UITextView *)textView
{
    if (textView == self.notesField)
    {
        NSString *text = textView.text;
        
        if ((text == nil) || (text.length == 0))
        {
            [self setNotesPlaceHolderText];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSLog(@"scrollViewDidScroll called for: %@", scrollView);
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"scrollViewDidEndDecelerating called for: %@", scrollView);
}

#pragma mark - Touch Notifications

-(void)touchesBegan: (NSSet *)touches withEvent:(UIEvent *)event
{
    if (keyboardVisible_)
    {
        UIView *firstResp = [self firstResponder];
        
        if (firstResp != nil)
        {
            if ([firstResp resignFirstResponder] == YES)
            {
                [self setFirstResponder:nil];
            }
        }
    }
}

#pragma mark - Vailidate User's BP Component Entry

- (NSNumber *)validateBPComponentFromText:(NSString *)text bpComponent:(BPComponent)component
{
    NSNumber *number = [NumericUtil convertStringToNSNumber:text];
    
    if ((number != nil) && ([NumericUtil numberContainsShort:number]))
    {
        BOOL inRange = NO;
        
        switch (component)
        {
            case SystolicComponent:
                inRange = [[BloodPressureDataAnalyzer instance] isSystolicInRange:[number shortValue]]; 
                break;
                
            case DiastolicComponent:
                inRange = [[BloodPressureDataAnalyzer instance] isDiastolicInRange:[number shortValue]];
                break;
                
            case PulseComponent:
                inRange = [[BloodPressureDataAnalyzer instance] isPulseInRange:[number shortValue]];
                break;
                
            case WeightComponent:
                inRange = [[BloodPressureDataAnalyzer instance] isWeightInRange:[number shortValue]];
                break;
                
            default:
                NSAssert1(NO, @"Invalid Blood Pressure Component %d", component);
                break;
        }
        
        return inRange ? number : nil;
    }
    
    return nil;
}

- (void)fieldValidationErrorDismissed:(id)context
{
    NSAssert(context != nil, @"context == nil");
    
    InvalidDataEntryContext *idc = (InvalidDataEntryContext *)context;
    
    NSAssert(idc.field != nil, @"context->field == nil");
    
    [self makeFieldFirstResponder:idc.field];
}

- (void)displayInvalidBPComponentAlert:(BPComponent)component field:(UIView *)field
{
    BloodPressureDataAnalyzer *bpValidator = [BloodPressureDataAnalyzer instance];
    NSString *compNameKey = nil;
    BPValidationResult valResult;
    
    switch (component)
    {
        case SystolicComponent:
            valResult = BPValSystolicInvalid;
            compNameKey = @"SYSTOLIC_COMPONENT_NAME";
            break;
            
        case DiastolicComponent:
            valResult = BPValDiastolicInvalid;
            compNameKey = @"DIASTOLIC_COMPONENT_NAME";
            break;
            
        case PulseComponent:
            valResult = BPValPulseInvalid;
            compNameKey = @"PULSE_COMPONENT_NAME";
            break;
            
        case WeightComponent:
            valResult = BPValWeightInvalid;
            compNameKey = @"WEIGHT_COMPONENT_NAME";
            break;
            
        default:
            ALog(@"Unexpected component %u", component);
            return;
    }
    
    NSString *bpComponentName = NSLocalizedString(compNameKey, nil);
    
    NSString *msg = [bpValidator buildMsgFromValidationResults:valResult];
    
    NSString *formatTitle = NSLocalizedString(@"INVALID_BP_READING_COMPONENT_ALERT_TITLE", nil);
    NSString *cancel = NSLocalizedString(@"OK_BUTTON_LABEL", @"OK button label");
    
    NSString *title = [NSString localizedStringWithFormat:formatTitle, bpComponentName];
    
    InvalidDataEntryContext *  __block idc = [[InvalidDataEntryContext alloc] init];
    
    idc.errorComponent = component;
    idc.field = field;
    
    [self setFirstResponder:nil];
    
    BPReadingDetailViewController* __weak weakSelf = self;
   
    UIAlertView * alertView = [[UIAlertView alloc]
                               initWithTitle:title
                               message:msg
                               clickedButtonBlock:^(UIAlertView *alertView, NSInteger buttonIndex)
                               {
                                   NSAssert(idc.field != nil, @"idc-field == nil");
                                   [weakSelf makeFieldFirstResponder:idc.field];
                                   idc = nil;
                               }
                               cancelButtonTitle:cancel
                               otherButtonTitles:nil];
    
    [alertView show];
}

#pragma mark -
#pragma mark Actions

- (IBAction)cancelAction:(id)sender
{
    NSLog(@"cancel pressed...");
    
    [self cancelEditMode];
}

- (IBAction)editAction:(id)sender
{
    NSLog(@"edit button pressed...");
    
    [self switchMode:YES];
}

- (IBAction)doneAction:(id)sender
{
    NSLog(@"done button pressed...");
    
    NSNumber *systolic = [self validateTextFieldData:self.systolicField bloodPressureComponent:SystolicComponent];
        
    if (systolic == nil)
    {
        return;
    }
    
    NSNumber *diastolic = [self validateTextFieldData:self.diastolicField bloodPressureComponent:DiastolicComponent];
    
    if (diastolic == nil)
    {
        return;
    }
    
    NSNumber *pulse = [self validateTextFieldData:self.pulseField bloodPressureComponent:PulseComponent];
    
    if (pulse == nil)
    {
        return;
    }

    NSNumber *weight = [self validateTextFieldData:self.weightField bloodPressureComponent:WeightComponent];
    
    if (weight == nil)
    {
        return;
    }
    
    BloodPressureReading *bpReading = self.bloodPressureReading;
    
    bpReading.systolic = systolic;
    bpReading.diastolic = diastolic;
    bpReading.pulse = pulse;
    bpReading.weight = weight;
    bpReading.readingDate = [self readingDate];
    
    if (notesFieldContentState_ == UserText)
    {
        bpReading.note = [[self notesField] text];
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:weight
                     forKey:weightEntryDefaultValueKey];
    
    [userDefaults synchronize];

    
    updated_ = YES;
    
    [self sendDoneNotification:YES];
}

#pragma mark - Send done notification.

- (void)sendDoneNotification:(BOOL)saved
{
    BOOL viewDismissed = NO;
    
    if (self.delegate != nil)
    {
        viewDismissed = [self.delegate doneUpdatingBloodPressureReading:self
                                                   bloodPressureReading:self.bloodPressureReading
                                                                  saved:saved
                                                             newReading:newReading_];
    }
    else if (doneUpdatingReadingBlock_ != nil)
    {
        viewDismissed = doneUpdatingReadingBlock_(saved);
    }
    
    newReading_ = NO;
    
    if (!viewDismissed)
    {
        // Not a new reading, switch back to non-edit mode.
        [self switchMode:NO];
    }
}

#pragma mark - NoteTakerViewControllerDelegate protocol implementation

- (void)noteTakerViewControllerShouldBeDismissed:(NoteTakerViewController *)viewController
{
    NSAssert(viewController != nil, @"noteTakerViewControllerShouldBeDismissed: viewController == nil!");
    
    if (![viewController canceled])
    {
        NSString *text = [viewController noteText];
        
        [[self notesField] setText:text];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - DatePickerViewControllerDelegate protocol implementation

- (void)datePickerViewControllerReadyToBeDismissed:(DatePickerViewController *)viewController pickedDate:(NSDate *)date
{
    NSAssert(viewController != nil, @"datePickerViewControllerReadyToBeDismissed: viewController == nil!");
    
    if (date != nil)
    {
        [self setReadingDate:date];
        
        [self setDateTextFieldFromDate:date setDatePicker:NO];
    }
    
//    [self.systolicField becomeFirstResponder];

//    [self dismissViewControllerAnimated:YES completion:NULL];
    [self dismissViewControllerAnimated:YES completion:^ { [self.systolicField becomeFirstResponder]; }];
}

@end
