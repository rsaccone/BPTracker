//
//  BPGraphViewController.m
//  BPTracker
//
//  Created by Robert Saccone on 6/30/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BPGraphViewController.h"

#import <SLexUtil/ErrorMsgBuilder.h>
#import <SLexUtil/NSDate+UtilityExtensions.h>
#import <SLexUtil/PlatformHelper.h>
#import <SLexUtil/UIAlertView+Blocks.h>
#import "BPGraphOptionsViewController.h"
#import "BPDataStoreEvents.h"
#import "BPFetchRequestBuilderHelper.h"
#import "BPGraphSettings.h"
#import "FetchedResultsControllerFactory.h"
#import "UserSettingKeys.h"
#import "ScatterPlotGraph.h"

@interface BPGraphViewController ()<BPGraphOptionsViewControllerDelegate, UIPopoverControllerDelegate>

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil; 
- (id)init;
- (void)initNavigationItem;
- (BOOL)fetchDateRange;
- (NSArray*) fetchBPReadingDataWithRangeStarting:(NSDate *)startDate andEnding:(NSDate *)endDate;
- (void)registerForBPStoreChangdeNotifications;
- (void)unregisterForBPStoreChangedNotifications;
- (void)bpReadingStoreChanged:(NSNotification *)notification;
- (BPGraphSettings *)populateGraphSettings:(BPGraphSettings *)bpGraphSettings;
- (void)saveGraphSettings:(BPGraphSettings *)bpGraphSettings;
- (void)createGraphFromSettings;
- (void)displayGraphOptions:(id)sender;
- (void)graphLegendPressed:(id)sender;

@property(nonatomic, strong) ScatterPlotGraph *scatterPlot;
@property(nonatomic, strong) NSDate *dateRangeMin;
@property(nonatomic, strong) NSDate *dateRangeMax;
@property(nonatomic, strong) BPGraphSettings *graphSettings;
@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) NSFetchRequest *minMaxDateFetchRequest;
@property(nonatomic, strong) UIPopoverController *graphOptionsPopover;
@property(nonatomic, assign) BOOL bpReadingStoreChangedEventReceived;

@end

@implementation BPGraphViewController
{
@private
    CPTGraphHostingView *graphHostView_;
    ScatterPlotGraph *scatterPlot_;
    NSDate *dateRangeMin_;
    NSDate *dateRangeMax_;
    BPGraphSettings *graphSettings_;
    NSManagedObjectContext *managedObjectContext_;
    NSFetchRequest *minMaxDateFetchRequest_;
    UIPopoverController *graphOptionsPopover_;
    BOOL bpReadingStoreChangedEventReceived_;
}

@synthesize graphHostView = graphHostView_;
@synthesize scatterPlot = scatterPlot_;
@synthesize dateRangeMin = dateRangeMin_;
@synthesize dateRangeMax = dateRangeMax_;
@synthesize graphSettings = graphSettings_;
@synthesize managedObjectContext = managedObjectContext_;
@synthesize minMaxDateFetchRequest = minMaxDateFetchRequest_;
@synthesize graphOptionsPopover = graphOptionsPopover_;
@synthesize bpReadingStoreChangedEventReceived = bpReadingStoreChangedEventReceived_;

// Designated initializer.
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    if (managedObjectContext == nil)
    {
        NSLog(@"ExportDataViewController: nil managedObjectContext passed!");
        NSAssert(managedObjectContext != nil, @"managedObjectContext is nil!");
        
        
        return nil;
    }
    
    static NSString * const nibName = @"BPGraphViewController";
    
    self = [super initWithNibName:nibName bundle:nil];
    
    if (self)
    {
        dateRangeMin_ = [NSDate dateToNearestSecond];
        dateRangeMax_ = self.dateRangeMin;
        managedObjectContext_ = managedObjectContext;
        NSFetchRequest *minMaxDateRequest = [BPFetchRequestBuilderHelper makeFetchRequestToRetrieveDateRangeLimits:managedObjectContext];
        
        if (minMaxDateRequest == nil)
        {
            return nil;
        }
        
        minMaxDateFetchRequest_ = minMaxDateRequest;
        
        UITabBarItem *tbi = [self tabBarItem];
        
        [tbi setTitle:NSLocalizedString(@"BP_GRAPH_CONTROLLER_TITLE", @"Pressure Graph")];
        UIImage *image = [UIImage imageNamed:@"line-chart.png"];
        [tbi setImage:image];
        
        [self initNavigationItem];
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

- (void)initNavigationItem
{
    UINavigationItem *navItem = self.navigationItem;
    
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *barButton        = [[UIBarButtonItem alloc]
                                         initWithTitle:NSLocalizedString(@"BPGRAPH_OPTIONS_BUTTON", nil)
                                         style:UIBarButtonItemStyleBordered
                                         target:self
                                         action:@selector(displayGraphOptions:)];
    
    navItem.rightBarButtonItem = barButton;
    
    
    barButton = [[UIBarButtonItem alloc]
                 initWithTitle:NSLocalizedString(@"BPGRAPH_LEGEND_BUTTON", nil)
                 style:UIBarButtonItemStyleBordered
                 target:self
                 action:@selector(graphLegendPressed:)];
    
    navItem.leftBarButtonItem = barButton;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
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
    [self displayExportFailureAlertWithTitleId:@"BPGRAPH_FAILURE_ALERT_TITLE" andMessageId:msgId andError:error];
}

- (void)displayExportFailureAlertWithMessageId:(NSString *)msgId
{
    [self displayExportFailureAlertWithTitleId:@"BPGRAPH_FAILURE_ALERT_TITLE" andMessageId:msgId andError:nil];
}

- (void)displayExportFailureAlertWithMessage:(NSString *)msg
{
    [self displayExportFailureAlertWithTitle:NSLocalizedString(@"BPGRAPH_FAILURE_ALERT_TITLE", nil) andMessage:msg];
}

#pragma mark - Core Data Related Methods

- (BOOL)fetchDateRange
{
    NSError * __autoreleasing error = nil;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:self.minMaxDateFetchRequest 
                                                                error:&error];
    
    if ((objects != nil) && ([objects count] > 0))
    {
        id dict = [objects objectAtIndex:0];
        NSDate *dateMin = [dict valueForKey:@"minDate"];
        NSDate *dateMax = [dict valueForKey:@"maxDate"];
        
        if ((dateMin != nil) && (dateMax != nil))
        {
            // Round the min date down and the max date up
            // because the date picker only goes out to minutes.
            // This prevents readings from NOT being included
            // in the graph.
            dateMin = [NSDate dropSeconds:dateMin];
            dateMax = [NSDate roundUpDate:dateMax toNearestIntervalInMinutes:1];
            NSLog(@"Minimum date: %@", dateMin);
            NSLog(@"Maximum date: %@", dateMax);
            
            self.dateRangeMin = dateMin;
            self.dateRangeMax = dateMax;
            
            return YES;
        }
        else 
        {
            NSLog(@"Couldn't retrieve min and/or max date from dictionary.");
        }
    }
    
    // Handle the error.
    NSLog(@"Couldn't retrieve min and max reading dates. %@", [error localizedDescription]);
    
    return NO;
}

- (NSArray*) fetchBPReadingDataWithRangeStarting:(NSDate *)startDate andEnding:(NSDate *)endDate
{
    FetchedResultsControllerFactory *factory = [FetchedResultsControllerFactory instance];
    
    NSFetchedResultsController *fetchedResultsController = 
    [factory makeBPFetchedResultsControllerWithManagedObjectContext:self.managedObjectContext 
                                                          startDate:startDate 
                                                            endDate:endDate 
                                                 sectionNameKeyPath:nil 
                                                          cacheName:nil batchSize:0];
    
    NSError * __autoreleasing error = nil;

    if (![fetchedResultsController performFetch:&error])
    {
        [self displayExportFailureAlertWithMessageId:@"EXPORT_DATA_FETCH_FAILURE_MSG" andError:error];
        return nil;
    }
    
    NSArray *readings = [fetchedResultsController fetchedObjects];
    
    if (readings == nil)
    {
        // TBD Can this happen? If so what should be done if it does?
        NSLog(@"fetchedResultsController fetchedObjects returned nil!");
        
        return nil;
    }
    
    return readings;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
//    self.edgesForExtendedLayout = UIRectEdgeNone;
//    self.automaticallyAdjustsScrollViewInsets = YES;

    self.title = NSLocalizedString(@"BP_GRAPH_CONTROLLER_TITLE", @"Pressure Graph");
    
    self.bpReadingStoreChangedEventReceived = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self registerForBPStoreChangdeNotifications];
}

- (void) viewDidLayoutSubviews
{
    BOOL buildGraphFromData = NO;
    
    [self unregisterForBPStoreChangedNotifications];
    
    @synchronized(self)
    {
        buildGraphFromData = self.bpReadingStoreChangedEventReceived;
        self.bpReadingStoreChangedEventReceived = NO;
    }
    
    if (buildGraphFromData)
    {
        if ([self fetchDateRange])
        {
            self.graphSettings = nil;
        }
        
        [self createGraphFromSettings];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Blood Pressure Store Changed Notification

- (void)registerForBPStoreChangdeNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bpReadingStoreChanged:)
                                                 name:BPStoreChangedNotification
                                               object:nil];
    
    NSLog(@"BPGraphViewController -> Registered for BPStoreChangedNotifcations.");
}

- (void)unregisterForBPStoreChangedNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BPStoreChangedNotification object:nil];
        
    NSLog(@"BPGraphViewController -> Unregistered for BPStoreChangedNotifications.");
}

- (void)bpReadingStoreChanged:(NSNotification *)notification
{
    // Notifications are delivered on the thread that
    // posts them. Locking is required in order to
    // guarantee that the two threads aren't modifying
    // the eventStoreChanged property simultaneously.
    @synchronized(self)
    {
        NSLog(@"BPGraphViewController: Did receive BPStoreChangedNotification");
        
        self.bpReadingStoreChangedEventReceived = YES;
    }
}

#pragma mark - Create Graph

- (void)createGraphFromSettings
{
    BPGraphSettings *graphSettings = self.graphSettings;
    
    NSArray *data = [self fetchBPReadingDataWithRangeStarting:graphSettings.graphDateRangeStart
                                                    andEnding:graphSettings.graphDateRangeEnd];

    // Grab the bottom and top bar offsets so the graph can be presented without
    // being clipped.
    CGFloat bottomBarOffset = self.bottomLayoutGuide.length;
    CGFloat topBarOffset = self.topLayoutGuide.length;
    
    self.scatterPlot = [[ScatterPlotGraph alloc] initWithHostingView:self.graphHostView
                                                       graphSettings:graphSettings
                                                         graphValues:data
                                                         topBarOffet:topBarOffset
                                                     bottomBarOffset:bottomBarOffset];
    [self.scatterPlot initialisePlot];
}

#pragma mark - Graph Settings Defaults

- (BPGraphSettings *)populateGraphSettings:(BPGraphSettings *)bpGraphSettings
{
    NSAssert(bpGraphSettings != nil, @"bpGraphSettings == nil");
    
    NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:bpGraphStartDateKey];
    
    if (!date || ([date compare:self.dateRangeMin] == NSOrderedAscending))
    {
        bpGraphSettings.graphDateRangeStart = self.dateRangeMin;
    }
    else
    {
        bpGraphSettings.graphDateRangeStart = date;
    }
    
    date = [[NSUserDefaults standardUserDefaults] objectForKey:bpGraphEndDateKey];
    
    if (!date || ([date compare:self.dateRangeMax] == NSOrderedDescending))
    {
        bpGraphSettings.graphDateRangeEnd = self.dateRangeMax;
    }
    else
    {
        bpGraphSettings.graphDateRangeEnd = date;
    }
    
    bpGraphSettings.systolicData    = [[NSUserDefaults standardUserDefaults] boolForKey:bpGraphSystolicDataKey];
    bpGraphSettings.diasotlicData   = [[NSUserDefaults standardUserDefaults] boolForKey:bpGraphDiastolicDataKey];
    bpGraphSettings.pulseData       = [[NSUserDefaults standardUserDefaults] boolForKey:bpGraphPulseDataKey];
    bpGraphSettings.legend          = [[NSUserDefaults standardUserDefaults] boolForKey:bpGraphLegendKey];
    
    return bpGraphSettings;
}

- (void)saveGraphSettings:(BPGraphSettings *)bpGraphSettings
{
    NSAssert(bpGraphSettings != nil, @"bpGraphSettings == nil");
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:bpGraphSettings.graphDateRangeStart forKey:bpGraphStartDateKey];
    [defaults setObject:bpGraphSettings.graphDateRangeEnd forKey:bpGraphEndDateKey];
    [defaults setBool:bpGraphSettings.systolicData forKey:bpGraphSystolicDataKey];
    [defaults setBool:bpGraphSettings.diasotlicData forKey:bpGraphDiastolicDataKey];
    [defaults setBool:bpGraphSettings.pulseData forKey:bpGraphPulseDataKey];
    [defaults setBool:bpGraphSettings.legend forKey:bpGraphLegendKey];
    
    [defaults synchronize];
}

#pragma mark - graphSettings Get Property

- (BPGraphSettings *)graphSettings
{
    if (graphSettings_ == nil)
    {
        BPGraphSettings *bpGraphSettings = [[BPGraphSettings alloc] init];
        
        self.graphSettings = [self populateGraphSettings:bpGraphSettings];
        
    }
    
    return graphSettings_;
}

#pragma mark - Button Press Handlers

- (void)displayGraphOptions:(id)sender
{
    BPGraphSettings *bpGraphSettings = [[BPGraphSettings alloc] init];
    
    [self populateGraphSettings:bpGraphSettings];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        BPGraphOptionsViewController *bpGraphOptionsViewCtrlr =
        [[BPGraphOptionsViewController alloc] initWithStartDateRangeMin:self.dateRangeMin
                                                        endDateRangeMax:self.dateRangeMax
                                                          graphSettings:bpGraphSettings
                                                 viewControllerDelegate:self];
        
        
        [bpGraphOptionsViewCtrlr setHidesBottomBarWhenPushed:YES];
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:bpGraphOptionsViewCtrlr];
        
        [self presentViewController:navController animated:YES completion:NULL];
    }
    else
    {
        if (self.graphOptionsPopover == nil)
        {
            BPGraphOptionsViewController *bpGraphOptionsViewCtrlr =
            [[BPGraphOptionsViewController alloc] initWithStartDateRangeMin:self.dateRangeMin
                                                            endDateRangeMax:self.dateRangeMax
                                                              graphSettings:bpGraphSettings
                                                     viewControllerDelegate:self];
            
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:bpGraphOptionsViewCtrlr];
            
            self.graphOptionsPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
            [self.graphOptionsPopover presentPopoverFromBarButtonItem:(UIBarButtonItem *)sender
                                                permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        }
        else
        {
            // Graph option popover is showing.  Hide it.
            [self.graphOptionsPopover dismissPopoverAnimated:YES];
            self.graphOptionsPopover = nil;
        }
    }
}

- (void)graphLegendPressed:(id)sender
{
    self.graphSettings.legend = !self.graphSettings.legend;
    self.scatterPlot.displayLegend = self.graphSettings.legend;
    
    [self saveGraphSettings:self.graphSettings];
}

#pragma mark - BPGraphOptionsViewControllerDelegate implementation

- (BOOL)done:(BPGraphOptionsViewController *)viewController;
{
    if (viewController.saved)
    {
        BPGraphSettings *newGraphSettings = viewController.bpGraphSettings;
        
        NSAssert(newGraphSettings != nil, @"newGraphSettings == nil");
        
        [self saveGraphSettings:newGraphSettings];
        
        self.graphSettings = newGraphSettings;
    
        [self createGraphFromSettings];
    }
    
    if (self.graphOptionsPopover != nil)
    {
        [self.graphOptionsPopover dismissPopoverAnimated:YES];
        self.graphOptionsPopover = nil;
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    
    return YES;
}

#pragma mark UIPopoverDelegate Methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.graphOptionsPopover = nil;
}

@end
