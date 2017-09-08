//
//  ExportDataViewController.m
//  BPTracker
//
//  Created by Robert Saccone on 12/10/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "ExportDataViewController.h"

#import <Foundation/NSKeyValueCoding.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <SLexUtil/DateRangePickerViewController.h>
#import <SLexUtil/DispatchingAlertView.h>
#import <SLexUtil/NSDate+UtilityExtensions.h>
#import <SLexUtil/PlatformHelper.h>
#import <SLexUtil/ErrorMsgBuilder.h>
#import <SLexUtil/SLXDateRangePickerCoordinator.h>
#import <SLexUtil/UIAlertView+Blocks.h>
#import "BPDataStoreEvents.h"
#import "BPFetchRequestBuilderHelper.h"
#import "DataExporterFactory.h"
#import "FetchedResultsControllerFactory.h"

@interface ExportDataViewController () <MFMailComposeViewControllerDelegate, SLXDateRangePickerCoordinatorDelegate, UIDocumentInteractionControllerDelegate>

- (BOOL)exportDataToApplicationHandler;
- (BOOL)exportDataViaMailHandler;
- (BOOL)exportDataToFile:(void (^)(NSString *exportFilename))exportCompleteBlock;

- (void)showModalViewController:(UIViewController *)viewController;

- (BOOL)validateDateRange;

- (void)sendMail:(NSString *)filename completion:(void (^)(void))completion;

- (BOOL)updateMinMaxDates;

- (void)setUIState:(BOOL)exportInProgress;


- (void)registerForBPStoreChangdeNotifications;
- (void)unregisterForBPStoreChangedNotifications;

- (void)displayExportFailureAlertWithMessage:(NSString *)msg;
- (void)displayExportFailureAlertWithMessageId:(NSString *)msgId;
- (void)displayExportFailureAlertWithMessageId:(NSString *)msgId andError:(NSError *)error;
- (void)displayExportFailureAlertWithTitleId:(NSString *)titleId andMessageId:(NSString *)msgId;
- (void)displayExportFailureAlertWithTitleId:(NSString *)titleId andMessageId:(NSString *)msgId andError:(NSError *)error;
- (void)displayExportFailureAlertWithTitle:(NSString *)title andMessage:(NSString *)msg;

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;

- (IBAction)buttonPressed:(id)sender;
- (IBAction)doneAction:(id)sender;

@property(nonatomic, weak) IBOutlet UILabel *startDateLabel;
@property(nonatomic, weak) IBOutlet UIButton *exportDataViaMailButton;
@property(nonatomic, weak) IBOutlet UIButton * exportDataToApp;
@property(nonatomic, weak) IBOutlet UITextField *startDateField;
@property(nonatomic, weak) IBOutlet UITextField *endDateField;
@property(nonatomic, weak) IBOutlet UIProgressView *exportProgress;
@property(nonatomic, strong) NSDate *startDate;
@property(nonatomic, strong) NSDate *endDate;

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) NSDate *minDate;
@property(nonatomic, strong) NSDate *maxDate;
@property(nonatomic, strong) SLXDateRangePickerCoordinator *dateRangePickerCoordinator;
@property(nonatomic, strong) NSFetchRequest *minMaxDateFetchRequest;
@property(nonatomic, strong) UIDocumentInteractionController *docInteractionController;
@property(nonatomic, assign) BOOL firstViewAppearsMsg;
@property(nonatomic, assign) BOOL bpReadingStoreChangedEventReceived;
@property(nonatomic, weak) id bpReadingStoreChangedObserver;

@end

@implementation ExportDataViewController
{
@private
    UILabel * __weak _startDateLabel_;
    UITextField * __weak startDateField_;
    UITextField * __weak endDateField_;
    UIButton * __weak exportDataViaMailButton_;
    UIButton * __weak exportDataToApp_;
	NSManagedObjectContext *managedObjectContext_;
    ExportDataViewControllerCompletionCallback completionCallback_;
    NSFetchRequest *minMaxDateFetchRequest_;
    NSDate *startDate_;
    NSDate *endDate_;
    NSDate *minDate_;
    NSDate *maxDate_;
    SLXDateRangePickerCoordinator *dateRangePickerCoordinator_;
    BOOL firstViewAppearsMsg_;
    BOOL bpReadingStoreChangedEventReceived_;
}

@synthesize exportDataViaMailButton = exportDataButton_;
@synthesize exportDataToApp = exportDataToApp_;
@synthesize startDateLabel = startDateLabel_;
@synthesize startDateField = startDateField_;
@synthesize endDateField = endDateField_;
@synthesize exportProgress;
@synthesize startDate=startDate_;
@synthesize endDate=endDate_;
@synthesize managedObjectContext = managedObjectContext_;
@synthesize completionCallback = completionCallback_;
@synthesize minDate = minDate_;
@synthesize maxDate = maxDate_;
@synthesize dateRangePickerCoordinator = dateRangePickerCoordinator_;
@synthesize firstViewAppearsMsg = firstViewAppearsMsg_;
@synthesize minMaxDateFetchRequest = minMaxDateFetchRequest_;
@synthesize docInteractionController;

#pragma mark - Initialization

// Designated initializer.
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    // call the superclasses dedicated initializer.
    static NSString * const nibName = @"ExportDataViewController";
    
    self = [super initWithNibName:nibName bundle:nil];
    
    if (self != nil)
    {
        if (managedObjectContext == nil)
        {
            NSLog(@"ExportDataViewController: nil managedObjectContext passed!");
            NSAssert(managedObjectContext != nil, @"managedObjectContext is nil!");
            
            return nil;
        }
        
        UITabBarItem *tbi = [self tabBarItem];
        
        [tbi setTitle:NSLocalizedString(@"EXPORT_DATA_CONTROLLER_TITLE", @"Export Blood Pressure Readings")];
        UIImage *image = [UIImage imageNamed:@"ExportIcon.png"];
        [tbi setImage:image];
        
        startDate_ = [NSDate dateToNearestSecond];
        endDate_ = self.startDate;
        minDate_ = self.startDate;
        maxDate_ = self.startDate;

        managedObjectContext_ = managedObjectContext;
        NSFetchRequest *minMaxDateRequest = [BPFetchRequestBuilderHelper makeFetchRequestToRetrieveDateRangeLimits:managedObjectContext];
        
        if (minMaxDateRequest == nil)
        {
            return nil;
        }
        
        minMaxDateFetchRequest_ = minMaxDateRequest;
    }
    
    return self;
}

- (id)init
{
    return [self initWithManagedObjectContext:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self init];
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
    [self unregisterForBPStoreChangedNotifications];
}

#pragma mark - View lifecycle

- (BOOL)updateMinMaxDates
{
    BOOL updatedMinMax = NO;
    NSError * __autoreleasing error = nil;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:self.minMaxDateFetchRequest error:&error];
    
    if (objects != nil)
    {
        if ([objects count] > 0) 
        {
            id dict = [objects objectAtIndex:0];
            NSDate *date = [dict valueForKey:@"minDate"];
            NSLog(@"Minimum date: %@", date);
            
            if ((date != nil) && (![date isEqualToDate:self.minDate]))
            {
                self.minDate = date;
                updatedMinMax = YES;
            }
            
            date = [dict valueForKey:@"maxDate"];
            
            NSLog(@"Maximum date: %@", date);
            
            if ((date != nil) && (![date isEqualToDate:self.maxDate]))
            {
                self.maxDate = date;
                updatedMinMax = YES;
            }
        }
    }
    else
    {
        // Handle the error.
        NSLog(@"Couldn't retrieve min and max reading dates. %@", [error localizedDescription]);
    }
    
    return updatedMinMax;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
//    self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeRight | UIRectEdgeBottom;
    self.title = NSLocalizedString(@"EXPORT_DATA_CONTROLLER_TITLE", @"Export Blood Pressure Readings");

    self.exportProgress.progress = 0.0f;
    self.startDate = self.minDate;
    self.endDate = self.maxDate;
    self.firstViewAppearsMsg = YES;
    self.bpReadingStoreChangedEventReceived = YES;
    
    self.dateRangePickerCoordinator = [[SLXDateRangePickerCoordinator alloc] initWithStartRangeTextField:self.startDateField
                                                                                       endRangeTextField:self.endDateField];
    
    self.dateRangePickerCoordinator.delegate = self;
    
    UINavigationItem *navItem = [self navigationItem];
    
    if (navItem)
    {
        [navItem  setHidesBackButton:YES animated:NO];
        
        UIBarButtonItem *bbi;
        
        bbi = [[UIBarButtonItem alloc]
               initWithBarButtonSystemItem:UIBarButtonSystemItemDone
               target:self
               action:@selector(doneAction:)];
        
        [navItem setRightBarButtonItem:bbi];
    }
 }

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    BOOL bpStoreUpdated = NO;
    
    [self unregisterForBPStoreChangedNotifications];
    
    @synchronized(self)
    {
        bpStoreUpdated = self.bpReadingStoreChangedEventReceived;
        self.bpReadingStoreChangedEventReceived = NO;
    }
    
    if (bpStoreUpdated && [self updateMinMaxDates])
    {
        NSTimeInterval interval = [self.endDate timeIntervalSinceDate:self.minDate];
        
        if (interval <= 0)
        {
            self.endDate = self.maxDate;
            if (!self.firstViewAppearsMsg)
            {
                [self displayExportFailureAlertWithTitleId:@"EXPORT_RANGE_AUTO_UPDATED"
                                              andMessageId:@"AUTO_UPDATED_END_DATE"];
            }
        }
        else
        {
            interval = [self.startDate timeIntervalSinceDate:self.maxDate];
            
            if (interval >= 0)
            {
                self.startDate = self.minDate;
                if (!self.firstViewAppearsMsg)
                {
                    [self displayExportFailureAlertWithTitleId:@"EXPORT_RANGE_AUTO_UPDATED"
                                                  andMessageId:@"AUTO_UPDATED_START_DATE"];

                }
            }
        }
        
        self.dateRangePickerCoordinator.minDate = self.minDate;
        self.dateRangePickerCoordinator.maxDate = self.maxDate;
        self.dateRangePickerCoordinator.startDate = self.startDate;
        self.dateRangePickerCoordinator.endDate = self.endDate;
    }
    
    if (self.firstViewAppearsMsg)
    {
        [self setUIState:NO];

        self.firstViewAppearsMsg = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self registerForBPStoreChangdeNotifications];
}

- (void)viewDidLayoutSubviews
{
    UILabel *startDateLabel = self.startDateLabel;
    
    [startDateLabel setTranslatesAutoresizingMaskIntoConstraints: NO];
    
    id topGuide = self.topLayoutGuide;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(startDateLabel, topGuide);
    
    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat: @"V:[topGuide]-20-[startDateLabel]"
                                             options: 0
                                             metrics: nil
                                               views: viewsDictionary]];
     [self.view layoutSubviews]; // You must call this method here or the system raises an exception
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)showModalViewController:(UIViewController *)viewController
{
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    [self presentViewController:navController animated:YES completion:NULL];
    
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

#pragma mark - UI Interactions

- (void)setUIState:(BOOL)exportInProgress
{
    if (exportInProgress)
    {
        self.exportProgress.hidden = NO;
        self.exportDataViaMailButton.enabled = NO;
        self.exportDataToApp.enabled = NO;
    }
    else
    {
        self.exportProgress.hidden = YES;
        self.exportDataViaMailButton.enabled = YES;
        self.exportDataToApp.enabled = YES;
    }
}

- (void)buttonPressed:(id)sender
{
    self.exportProgress.hidden = NO;
    self.exportDataViaMailButton.enabled = NO;
    self.exportDataToApp.enabled = NO;
    
    BOOL exportStarted = NO;
    
    // And now you can check which button is the sender
    if (sender == self.exportDataViaMailButton)
    {
        exportStarted = [self exportDataViaMailHandler];
    }
    else if (sender == self.exportDataToApp)
    {
        exportStarted = [self exportDataToApplicationHandler];
    }
    
    if (!exportStarted)
    {
        self.exportProgress.hidden = YES;
        self.exportDataViaMailButton.enabled = YES;
        self.exportDataToApp.enabled = YES;
    }
}

- (IBAction)doneAction:(id)sender
{
    NSLog(@"done button pressed...");
    
    ExportDataViewControllerCompletionCallback callback = self.completionCallback;
    
    self.completionCallback = nil;
    
    if (callback != nil)
    {
        callback();
    }
}

- (BOOL)exportDataToApplicationHandler
{
    ExportDataViewController * __weak weakSelf = self;
    
    return [self exportDataToFile:^(NSString *exportFilename)
                                   {
                                       [weakSelf sendFileToApplication:exportFilename];
                                   }];
}

- (BOOL)exportDataViaMailHandler
{
    if (![MFMailComposeViewController canSendMail])
    {
        NSLog(@"exportDataViaMailHandler -> Device not configured to send mail.");
        
        [self displayExportFailureAlertWithTitleId:NSLocalizedString(@"EXPORT_DATA_USER_ERROR_TITLE", nil) andMessageId:NSLocalizedString(@"EXPORT_DATA_DEVICE_CANNOT_SENDMAIL", nil)];
        
        return NO;
    }
    
    ExportDataViewController * __weak weakSelf = self;
    
    return [self exportDataToFile:^(NSString *exportFilename)
                                   {
                                       if (exportFilename != nil)
                                       {
                                           [weakSelf sendMail:exportFilename
                                                   completion:^()
                                                   {
                                                       [weakSelf setUIState:NO];
                                                   }];
                                       }
                                       else
                                       {
                                           [weakSelf setUIState:NO];
                                       }
                                   }];
}

#pragma mark - Data Export Methods

- (BOOL)exportDataToFile:(void (^)(NSString *exportFilename))exportCompleteBlock
{
    self.exportProgress.progress = 0.0f;
    
    if (![self validateDateRange])
    {
        return NO;
    }
    
    NSString *tempDir = NSTemporaryDirectory();
    NSUInteger tempDirLength = (tempDir != nil) ? [tempDir length] : 0;
    
    if ((tempDir == nil)  || (tempDirLength == 0))
    {
        NSLog(@"NSTemporaryDirectory returned nil or length is 0!");
        
        NSString *msgId = @"TEMPORARY_DIR_NAME_RETRIEVAL_FAILURE_MSG";
        
        [self displayExportFailureAlertWithMessageId:msgId];
        
        return NO;
    }
    
    // create writer MOC
    NSManagedObjectContext *privateExporterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [privateExporterContext setPersistentStoreCoordinator:self.managedObjectContext.persistentStoreCoordinator];
    
    ExportDataViewController *__weak weakSelf = self;

    [privateExporterContext performBlock:^{
        FetchedResultsControllerFactory *factory = [FetchedResultsControllerFactory instance];
        
        NSFetchedResultsController *fetchedResultsController
            = [factory makeBPFetchedResultsControllerWithManagedObjectContext:privateExporterContext
                                                                    startDate:weakSelf.startDate
                                                                      endDate:weakSelf.endDate
                                                           sectionNameKeyPath:nil
                                                                    cacheName:nil
                                                                    batchSize:0];
        
        NSMutableString *exportFilename = [[NSMutableString alloc] init];
        
        if ([tempDir characterAtIndex:tempDirLength - 1] == '/')
        {
            [exportFilename appendFormat:@"%@BPExportFile.csv", tempDir];
        }
        else
        {
            [exportFilename appendFormat:@"%@/BPExportFile.csv", tempDir];
        }
        
        id<DataExporter> dataExporter = [[DataExporterFactory instance] dataExporterForType:CSV_Data_Exporter filename:exportFilename];
        
        NSError * error = nil;
        
        if (![fetchedResultsController performFetch:&error])
        {
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               exportCompleteBlock(nil);
                               [weakSelf displayExportFailureAlertWithMessageId:@"EXPORT_DATA_FETCH_FAILURE_MSG" andError:error];
                           });
            
            return;
        }
        
        NSArray *readings = [fetchedResultsController fetchedObjects];
        
        if (readings == nil)
        {
            // TBD Can this happen? If so what should be done if it does?
            NSLog(@"fetchedResultsController fetchedObjects returned nil!");
            
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               exportCompleteBlock(nil);
                           });
            
            return;
        }
        
        [dataExporter addReadings:readings
                   updateProgress:^(float progress)
                    {
                        if (progress < 1.0f)
                        {
                            dispatch_async(dispatch_get_main_queue(),
                                           ^{
                                               [weakSelf.exportProgress setProgress:progress animated:YES];
                                           });
                        }
                        else
                        {
                            dispatch_sync(dispatch_get_main_queue(),
                                          ^{
                                              [weakSelf.exportProgress setProgress:progress animated:YES];
                                          });
                        }
                    }];
        
        [dataExporter done];

        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           exportCompleteBlock(exportFilename);
                       });
        
    }];
    
    return YES;
}

#pragma mark - Error Message Handling

- (void)displayExportFailureAlertWithTitle:(NSString *)title andMessage:(NSString *)msg
{
    NSString *cancel = NSLocalizedString(@"OK_BUTTON_LABEL", @"OK button label");
    
    UIAlertView * alertView = [[UIAlertView alloc]
                               initWithTitle:title
                               message:msg
                               clickedButtonBlock:^(UIAlertView *alertView, NSInteger buttonIndex)
                               {
                               }
                               cancelButtonTitle:cancel
                               otherButtonTitles:nil];
    
    [alertView show];
}

- (void)displayExportFailureAlertWithTitleId:(NSString *)titleId andMessageId:(NSString *)msgId andError:(NSError *)error
{
    NSString *msg = [ErrorMsgBuilder build:NSLocalizedString(msgId, nil) error:error];
    [self displayExportFailureAlertWithTitle:NSLocalizedString(titleId, nil) andMessage:msg];
}

- (void)displayExportFailureAlertWithTitleId:(NSString *)titleId andMessageId:(NSString *)msgId
{
    [self displayExportFailureAlertWithTitleId:titleId andMessageId:msgId andError:nil];
}

- (void)displayExportFailureAlertWithMessageId:(NSString *)msgId andError:(NSError *)error
{
    [self displayExportFailureAlertWithTitleId:@"EXPORT_DATA_FAILURE_ALERT_TITLE" andMessageId:msgId andError:error];
}

- (void)displayExportFailureAlertWithMessageId:(NSString *)msgId
{
    [self displayExportFailureAlertWithTitleId:@"EXPORT_DATA_FAILURE_ALERT_TITLE" andMessageId:msgId andError:nil];
}

- (void)displayExportFailureAlertWithMessage:(NSString *)msg
{
    [self displayExportFailureAlertWithTitle:NSLocalizedString(@"EXPORT_DATA_FAILURE_ALERT_TITLE", nil) andMessage:msg];
}

#pragma mark - Various Field and Utility Methods

- (BOOL)validateDateRange
{
    NSComparisonResult compare = [self.startDate compare:self.endDate];
    
    // Is start date later than the end date?
    if (compare == NSOrderedDescending)
    {
        [self displayExportFailureAlertWithTitleId:NSLocalizedString(@"EXPORT_DATA_FAILURE_ALERT_TITLE", nil) andMessageId:NSLocalizedString(@"EXPORT_DATA_USER_ERROR_INVALID_DATE_RANGE", nil)];
        
        return NO;
    }
    
    return YES;
}

#pragma mark - Sending Data to Application Methods

- (void)sendFileToApplication:(NSString *)filename
{
    [self setUIState:NO];
    
    if (filename != nil)
    {
        NSURL *filenameUrl = [NSURL fileURLWithPath:filename isDirectory:NO];
        
        self.docInteractionController = [UIDocumentInteractionController interactionControllerWithURL:filenameUrl];
        self.docInteractionController.delegate = self;
        
        CGRect exportAppButtonRect = [self.view convertRect:self.exportDataToApp.bounds fromView:self.exportDataToApp];
        
        if (![self.docInteractionController presentOpenInMenuFromRect:exportAppButtonRect inView:self.view animated:YES])
        {
            UIAlertView * alertView = [[UIAlertView alloc]
                                       initWithTitle:NSLocalizedString(@"EXPORT_READINGS_SEND_TO_APP_TITLE_FAILURE", nil)
                                       message:NSLocalizedString(@"EXPORT_READINGS_SEND_TO_APP_NO_APPS_ON_DEVICE", nil)
                                       delegate:nil
                                       cancelButtonTitle:NSLocalizedString(@"OK_BUTTON_LABEL", nil)
                                       otherButtonTitles:nil];
            
            [alertView show];
        }
    }
}

#pragma mark -  UIDocumentInteractionControllerDelegate methods

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self;
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    self.docInteractionController = nil;
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    self.docInteractionController = nil;
}

#pragma mark - eMail Related Methods.

- (void)sendMail:(NSString *)filename completion:(void (^)(void))completion
{
    NSAssert(filename != nil, @"filename == nil");

    NSString *msgBody = nil;

    @try 
    {
        MFMailComposeViewController *mailComposeVC = [[MFMailComposeViewController alloc] init];

        if (!mailComposeVC)
        {
            NSLog(@"Couldn't create instance of MFMailComposeViewController");
            
            [self displayExportFailureAlertWithMessageId:NSLocalizedString(@"EXPORT_DATA_CANNOT_CREATE_COMPOSE_MAIL_VIEW", nil)];
            
            return;
        }

        NSError * __autoreleasing error = nil;

        NSData *exportData = [NSData dataWithContentsOfFile:filename options:NSDataReadingUncached error:&error];

        [mailComposeVC addAttachmentData:exportData mimeType:@"text/csv" fileName:@"BloodPressureReadings.csv"];
        [mailComposeVC setSubject:NSLocalizedString(@"EXPORT_DATA_MAIL_SUBJECT", nil)];
        mailComposeVC.mailComposeDelegate = self;

        NSString *startDateString = [NSDateFormatter localizedStringFromDate:self.startDate dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
        
        NSString *endDateString = [NSDateFormatter localizedStringFromDate:self.endDate dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];

        msgBody = [NSString stringWithFormat:NSLocalizedString(@"EXPORT_DATA_MAIL_MESSAGE_BODY", nil), startDateString, endDateString];

        [mailComposeVC setMessageBody:msgBody isHTML:NO];
        
        [self presentViewController:mailComposeVC animated:YES completion:completion];
        
    }
    @finally 
    {
    }
}
    
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if (error != nil)
    {
        [self displayExportFailureAlertWithTitleId:@"EXPORT_DATA_FAILURE_ALERT_TITLE" andMessageId:@"EXPORT_DATA_COMPOSE_MAIL_VIEW_ERROR" andError:error];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - SLXDateRangePickerCoordinator delegate methods

- (void)dateRangeUpdated:(SLXDateRangePickerCoordinator *)coordinator componentUpdated:(DateRangeComponent)updatedComponent
{
    if ((updatedComponent == Start) || (updatedComponent == Both))
    {
        self.startDate = coordinator.startDate;
    }
    
    if ((updatedComponent == End) || (updatedComponent == Both))
    {
        self.endDate = coordinator.endDate;
    }
}


#pragma mark - Blood Pressure Store Changed Notification

- (void)registerForBPStoreChangdeNotifications
{
    ExportDataViewController * __weak weakSelf = self;
    
    self.bpReadingStoreChangedObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:BPStoreChangedNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *notification)
                                    {
                                        NSLog(@"ExportDataViewController: Did receive BPStoreChangedNotification");
                                        
                                        weakSelf.bpReadingStoreChangedEventReceived = YES;
                                    }];
    
    NSLog(@"ExportDataViewController -> Registered for BPStoreChangedNotifcations.");
}

- (void)unregisterForBPStoreChangedNotifications
{
    if (self.bpReadingStoreChangedObserver != nil)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self.bpReadingStoreChangedObserver
                                                        name:BPStoreChangedNotification
                                                      object:nil];
    }
    
    NSLog(@"ExportDataViewController -> Unregistered for BPStoreChangedNotifications.");
}

@end
