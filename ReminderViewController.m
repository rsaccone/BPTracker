//
//  ReminderViewController.m
//  BPTracker
//
//  Created by Robert Saccone on 1/30/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "ReminderViewController.h"

#import <EventKitUI/EKCalendarChooser.h>
#import <EventKitUI/EKEventEditViewController.h>
#import <EventKitUI/EKEventViewController.h>
#import <SLexUtil/NSDate+UtilityExtensions.h>
#import <SLexUtil/PlatformHelper.h>
#import <SLexUtil/UIViewController+HelperExtensions.h>

#import <SLexUtil/PlatformHelper.h>
#import <SLexUtil/ErrorMsgBuilder.h>
#import <SLexUtil/UIAlertView+Blocks.h>
#import "EventViewAndEditController.h"
#import "TakeReadingCalendarEventMetaData.h"
#import "TableViewUserDefaultsHelper.h"
#import "UserSettingKeys.h"

@interface ReminderViewController () <EKEventEditViewDelegate, EventViewAndEditDelegate, EKCalendarChooserDelegate, UIPopoverControllerDelegate>

- (void)addEvent:(id)sender;
- (void)displayAddEventView;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)configureBarButtons:(BOOL)editMode;
- (void)registerForEventStoreChangeNotifications;
- (void)unregisterForEventStoreChangeNotifications;
- (void)reloadEventDataAndTableView;
- (void)registerForApplicationStateChangeNotifications;
- (void)unregisterForApplicationStateChangeNotifications;
- (void)actOnEventStoreUpdatesTimerMethod:(NSTimer*)theTimer;
- (void)displayPendingError;
- (void)selectAndScrollIntoView:(NSIndexPath *)selection;
- (BOOL)processCompletedEditAction;

@property(nonatomic, strong) id<TakeReadingRemindersStore> takeReadingRemindersStore;
@property(nonatomic, strong) UIBarButtonItem *addNewItemButton;
@property(nonatomic, strong) NSDateFormatter *shortStyleDateTimeFormatter;
@property(nonatomic, strong) NSDateFormatter *shortStyleDateNoTimeFormatter;
@property(nonatomic, strong) NSTimer *actOnEventStoreUpdatesTimer;
@property(nonatomic, strong) NSError *pendingErrorToBeProcessed;
@property(nonatomic, strong) TableViewUserDefaultsHelper *tableViewUserDefaultsHelper;
@property(nonatomic, strong) UIPopoverController *eventPopoverController;
@property(nonatomic, assign) BOOL inBackgroundState;
@property(nonatomic, assign) BOOL eventStoreChanged;
@property(nonatomic, assign) BOOL editingEvent;
@property(nonatomic, assign) BOOL registeredEventStoreChangeNotifications;
@property(nonatomic, assign) BOOL registeredApplicationStateNotifications;
@property(nonatomic, assign) BOOL restoreSelectionFromDefaults;

@property(nonatomic, weak) id eventStoreChangeObserver;
@property(nonatomic, weak) id appDidEnterBackgroundObserver;
@property(nonatomic, weak) id appDidBecomeActiveObserver;

@end

@implementation ReminderViewController
{
@private
	id<TakeReadingRemindersStore> takeReadingRemindersStore_;
    NSDateFormatter *shortStyleDateTimeFormatter_;
    NSDateFormatter *shortStyleDateNoTimeFormatter_;
    NSTimer *coalesceEventUpdatesTimer_;
    NSError *pendingErrorToBeProcessed_;
    TableViewUserDefaultsHelper *tableViewUserDefaultsHelper_;
    BOOL restoreSelectionFromDefaults_;
}

@synthesize takeReadingRemindersStore = takeReadingRemindersStore_;
@synthesize addNewItemButton = addNewItemButton_;
@synthesize shortStyleDateTimeFormatter = shortStyleDateTimeFormatter_;
@synthesize shortStyleDateNoTimeFormatter = shortStyleDateNoTimeFormatter_;
@synthesize actOnEventStoreUpdatesTimer = coalesceEventUpdatesTimer_;
@synthesize pendingErrorToBeProcessed = pendingErrorToBeProcessed_;
@synthesize tableViewUserDefaultsHelper = tableViewUserDefaultsHelper_;
@synthesize inBackgroundState;
@synthesize eventStoreChanged;
@synthesize editingEvent;
@synthesize registeredEventStoreChangeNotifications;
@synthesize registeredApplicationStateNotifications;
@synthesize restoreSelectionFromDefaults = restoreSelectionFromDefaults_;

// Designated initializer.
-(id)initWithTakeReadingRemindersStore:(id<TakeReadingRemindersStore>)takeReadingRemindersStore;
{
    if (takeReadingRemindersStore == nil)
    {
        NSLog(@"BPReadingListViewController: nil id<takeReadingRemindersStore> passed!");
        NSAssert(takeReadingRemindersStore != nil, @"managedObjectContext is nil!");
        
        
        return nil;
    }
    
    NSString *nibName = @"ReminderViewController";
    
    self = [super initWithNibName:nibName bundle:nil];
    
    if (self != nil)
    {
        takeReadingRemindersStore_ = takeReadingRemindersStore;
        
        NSArray *keyNames = [NSArray arrayWithObjects:reminderTableViewSectionSelectedKey, reminderTableViewRowSelectedKey, reminderTableViewEditSelectedKey, reminderTableViewSortAscendingKey, nil];
        
        tableViewUserDefaultsHelper_ = [[TableViewUserDefaultsHelper alloc] initWithKeyNames:keyNames];
        restoreSelectionFromDefaults_ = YES;
        
        UITabBarItem *tbi = [self tabBarItem];
        
        [tbi setTitle:NSLocalizedString(@"REMINDER_CONTROLLER_TITLE", nil)];
        UIImage *image = [UIImage imageNamed:@"calendar.png"];
        [tbi setImage:image];
        
        [self configureBarButtons:NO];
    }
    
    return self;
}

- (id)init
{
    return [self initWithTakeReadingRemindersStore:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self init];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    NSLog(@"ReminderViewController: viewDidLoad.");

    [super viewDidLoad];
//    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.tableView.rowHeight = 60.0;

    self.title = NSLocalizedString(@"REMINDER_CONTROLLER_TITLE", nil);
    
    [self configureBarButtons:NO];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    self.shortStyleDateTimeFormatter = dateFormatter;
    
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    self.shortStyleDateNoTimeFormatter = dateFormatter;
    
    
    self.editingEvent = NO;
    self.eventStoreChanged = NO;
    self.inBackgroundState = NO;
    
    [self registerForApplicationStateChangeNotifications];
    
    [self.tableView reloadData];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)selectAndScrollIntoView:(NSIndexPath *)selection;
{
    NSAssert(selection != nil, @"selection == nil");
    
    UITableView *tv = self.tableView;
    [tv selectRowAtIndexPath:selection animated:NO scrollPosition:UITableViewScrollPositionNone];
    [tv scrollToRowAtIndexPath:selection atScrollPosition:UITableViewScrollPositionNone animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"ReminderViewController: viewWillAppear.");

    [super viewWillAppear:animated];

    if (![self processCompletedEditAction] && self.restoreSelectionFromDefaults)
    {
        self.restoreSelectionFromDefaults = NO;
        
        NSIndexPath *selection = [self.tableViewUserDefaultsHelper getSavedSelection];
        
        if (selection != nil)        
        {
            NSInteger row = selection.row;
            NSUInteger count = self.takeReadingRemindersStore.count;
            
            if (row < count)
            {
                EKEvent *event = [self.takeReadingRemindersStore reminderEventAtIndex:row];
                
                NSString *savedId = [[NSUserDefaults standardUserDefaults] objectForKey:reminderTableViewSelectionIdKey];
                
                if (savedId && ([event.eventIdentifier compare:savedId] == NSOrderedSame))
                {
                    [self selectAndScrollIntoView:selection];
                    
                    if ([self.tableViewUserDefaultsHelper getSavedEditingFlag])
                    {
                        // Don't resume editing if on iPad because the view may not be attached
                        // to a window which will result in an error when the popover that is
                        // used on the iPad is displayed.
                        if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
                        {
                            [self tableView:self.tableView didSelectRowAtIndexPath:selection];
                        }
                    }
                }
            }
        }
    }
    
    if (!self.registeredEventStoreChangeNotifications)
    {
        [self registerForEventStoreChangeNotifications];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"ReminderViewController: viewDidDAppear.");
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"ReminderViewController: viewWillDisappear.");
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"ReminderViewController: viewDidDisappear.");
}

#pragma mark - Prcoess Completed Edit Action

- (BOOL)processCompletedEditAction
{
    if (self.editingEvent)
    {
        if (!self.pendingErrorToBeProcessed)
        {
            self.editingEvent = NO;
            
            [self.tableViewUserDefaultsHelper saveEditingFlag:NO];
        }
        else
        {
            [self displayPendingError];
        }
        
        return YES;
    }
    
    return NO;
}

#pragma mark - Error Display and Handling.
                                                                    
- (void)displayPendingError
{
    NSString *title = NSLocalizedString(@"READING_REMINDER_FAILURE_TITLE", nil);
    NSString *msg = [ErrorMsgBuilder build:nil error:self.pendingErrorToBeProcessed];
    NSString *cancel = NSLocalizedString(@"OK_BUTTON_LABEL", @"OK button label");
    
    self.pendingErrorToBeProcessed = nil;
    
    UIAlertView * alertView = [[UIAlertView alloc]
                               initWithTitle:title
                               message:msg
                               clickedButtonBlock:^(UIAlertView *alertView, NSInteger buttonIndex)
                               {
                                   abort();
                               }
                               cancelButtonTitle:cancel
                               otherButtonTitles:nil];
    
    [alertView show];
}
                                                                       
#pragma mark - Refresh View

- (void)reloadEventDataAndTableView;
{
    [self.takeReadingRemindersStore forceDataReload];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Add a new event

// If event is nil, a new event is created and added to the specified event store. New events are 
// added to the default calendar. An exception is raised if set to an event that is not in the 
// specified event store.
- (void)addEvent:(id)sender 
{
#if 0
    EKCalendarChooser *calendarChooser = [[EKCalendarChooser alloc] 
                                          initWithSelectionStyle:EKCalendarChooserSelectionStyleSingle 
                                          displayStyle:EKCalendarChooserDisplayWritableCalendarsOnly 
                                          eventStore:self.takeReadingRemindersStore.eventStore];
    
    calendarChooser.delegate = self;
    
    calendarChooser.showsDoneButton = YES;
    calendarChooser.showsCancelButton = YES;

    UINavigationController *cntrol = [[UINavigationController alloc] initWithRootViewController:calendarChooser];
    
    [self presentViewController:cntrol animated:YES completion:nil];
    
    [calendarChooser release];
    [cntrol release];
#endif
    
    [self displayAddEventView];
}

- (void)displayAddEventView
{
    const NSTimeInterval appointmentInterval = 15 * 60;
    
    NSDate *startDate = [NSDate roundUpDate:[NSDate date] toNearestIntervalInMinutes:30];
    NSDate *endDate = [startDate dateByAddingTimeInterval:appointmentInterval];
    
    EKEvent *newEvent = [EKEvent eventWithEventStore:self.takeReadingRemindersStore.eventStore];
    
    newEvent.startDate = startDate;
    newEvent.endDate = endDate;
    
    // When add button is pushed, create an EKEventEditViewController to display the event.
    EKEventEditViewController *addController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
    
    // set the addController's event store to the current event store.
    addController.eventStore = self.takeReadingRemindersStore.eventStore;
    addController.editViewDelegate = self;
    addController.event = newEvent;
    
    self.editingEvent = YES;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        self.eventPopoverController = [[UIPopoverController alloc] initWithContentViewController:addController];
        
        [self.eventPopoverController presentPopoverFromBarButtonItem:self.addNewItemButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
        self.eventPopoverController.delegate = self;
    }
    else
    {
        [self presentViewController:addController animated:YES completion:NULL];
    }
    
}

#pragma mark -EKEventEditViewDelegate

// Overriding EKEventEditViewDelegate method to update event store according to user actions
// when a new event has been created.
- (void)eventEditViewController:(EKEventEditViewController *)controller 
          didCompleteWithAction:(EKEventEditViewAction)action                                                                                                                               
{
    BOOL opSucceeded = YES;
    NSError * __autoreleasing error = nil;
    EKEvent *thisEvent = controller.event;
    
    switch (action) 
    {
        case EKEventEditViewActionCanceled:                                                                                                                                                                                             
            // Edit action canceled, do nothing. 
            break;
            
        case EKEventEditViewActionSaved:
            // When user hit "Done" button, save the newly created event to the event store, 
            // and reload table view.
            // If the new event is being added to the default calendar, then update its 
            // eventsList.
            opSucceeded = [self.takeReadingRemindersStore addReminderEvent:thisEvent eventStore:nil error:&error];
            break;
            
        case EKEventEditViewActionDeleted:
            // When deleting an event, remove the event from the event store, 
            // and reload table view.
            // If deleting an event from the currenly default calendar, then update its 
            // eventsList.
            opSucceeded = [self.takeReadingRemindersStore deleteReminderEvent:thisEvent eventStore:nil error:&error];
            break;
            
        default:
            break;
    }
    
    if (!opSucceeded)
    {
        self.pendingErrorToBeProcessed = error;
    }
    
    if (self.eventPopoverController)
    {
        [self.eventPopoverController dismissPopoverAnimated:YES];
        self.eventPopoverController = nil;
        [self processCompletedEditAction];
    }
    else
    {
        // Dismiss the modal view controller
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Popover Delegate methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.eventPopoverController = nil;
    [self processCompletedEditAction];
}

#pragma mark - EventViewAndEditDelegate

// Method called when EventViewAndEditController informs that the user has finished editing an event
// that already exists in the store.  Changes in event data will be picked up through event
// change notifications that are registered for via the notification center.
-(void)eventViewAndEditController:(EventViewAndEditController *)controller
            didCompleteWithAction:(EventViewAndEditAction)action
{
    BOOL opSucceeded = YES;
    BOOL popViewController = NO;
    NSError * __autoreleasing error = nil;
    EKEvent *thisEvent = controller.event;
    
    NSString *origEventId = ((EventViewAndEditController *)controller).origEventId;
    
    switch (action) 
    {
        case EventViewAndEditActionDone:
            // User pressed the "Done" button. 
            opSucceeded = [self.takeReadingRemindersStore saveReminderEvent:thisEvent eventStore:nil originalEventId:origEventId error:&error];
            popViewController = YES;
            break;
            
        case EventViewAndEditActionSaved:
            // Don't pop the view controller on a save because the user 
            // is still viewing the event.
            opSucceeded = [self.takeReadingRemindersStore saveReminderEvent:thisEvent eventStore:nil originalEventId:origEventId error:&error];
            if (self.eventPopoverController != nil)
            {
                popViewController = YES;
            }
            break;
            
        case EventViewAndEditActionResponded:
            // The user responded to a pending event invitation and saved it.
            opSucceeded = [self.takeReadingRemindersStore saveReminderEvent:thisEvent eventStore:nil originalEventId:origEventId error:&error];
            break;
            
        case EventViewAndEditActionDeleted:
            // The event was deletede when deleting an event, remove the event from the event store.
            opSucceeded = [self.takeReadingRemindersStore deleteReminderEvent:thisEvent eventStore:nil error:&error];
            popViewController = YES;
            break;
            
        case EventViewAndEditActionCanceled:
            // Editing was canceled.  This event will only come in on the iPad
            // because the view is presented in a popover.
            popViewController = YES;
            break;
            
        default:
            break;
    }
    
    popViewController = (!opSucceeded) ? YES : popViewController;
    
    if (!opSucceeded)
    {
        self.pendingErrorToBeProcessed = error;
    }
    
    if (popViewController)
    {
        if (self.eventPopoverController)
        {
            [self.eventPopoverController dismissPopoverAnimated:YES];
            self.eventPopoverController = nil;
            [self processCompletedEditAction];
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

#pragma mark - EKCalendarChooserDelegate 

// These are called when the corresponding button is pressed to dismiss the
// controller. It is up to the recipient to dismiss the chooser.
- (void)calendarChooserDidFinish:(EKCalendarChooser *)calendarChooser
{
    if (self.eventPopoverController)
    {
        [self.eventPopoverController dismissPopoverAnimated:YES];
        self.eventPopoverController = nil;
    }
    else
    {
        // Dismiss the modal view controller
        [self dismissViewControllerAnimated:YES completion:^(void) { [self displayAddEventView]; }];
    }
}

- (void)calendarChooserDidCancel:(EKCalendarChooser *)calendarChooser
{
    if (self.eventPopoverController)
    {
        [self.eventPopoverController dismissPopoverAnimated:YES];
        self.eventPopoverController = nil;
    }
    else
    {
        // Dismiss the modal view controller
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return (NSInteger)1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    // Return the number of rows in the section.
    if (section != 0)
    {
        return 0;
    }
    return self.takeReadingRemindersStore.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    
    static NSString *CellIdentifier = @"ReminderCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

static NSString *getRepeatIntervalDesc(NSInteger interval,
                                       EKRecurrenceFrequency freq)
{
    NSString *result;

    if (interval == 1)
    {
        NSString *resId = nil;
        
        switch (freq)
        {
            case EKRecurrenceFrequencyDaily:
                resId = @"DAY";
                break;
                
            case EKRecurrenceFrequencyWeekly:
                resId = @"WEEK";
                break;
                
            case EKRecurrenceFrequencyMonthly:
                resId = @"MONTH";
                break;
                
            case EKRecurrenceFrequencyYearly:
                resId = @"YEAR";
                break;
                
            default:
                resId = @"DAY";
                NSLog(@"Unexpected event repeat frequency: <%ld>, assuming <%@>", (long)freq, resId);
                break;
        }
        
        result = [NSString stringWithFormat:NSLocalizedString(@"MULTI-INTERVAL_SINGLE-FREQUENCY_RECURRENCE", nil), NSLocalizedString(resId, nil)];
    }
    else
    {
        NSString *resId = nil;
        
        switch (freq)
        {
            case EKRecurrenceFrequencyDaily:
                resId = @"DAYS";
                break;
                
            case EKRecurrenceFrequencyWeekly:
                resId = @"WEEKS";
                break;
                
            case EKRecurrenceFrequencyMonthly:
                resId = @"MONTHS";
                break;
                
            case EKRecurrenceFrequencyYearly:
                resId = @"YEARS";
                break;
                
            default:
                resId = @"DAYS";
                NSLog(@"Unexpected event repeat frequency: <%ld>, assuming <%@>", (long)freq, resId);
                break;
        }
        
        result = [NSString stringWithFormat:NSLocalizedString(@"MULTI-INTERVAL_MULTI-FREQUENCY_RECURRENCE", nil), interval, NSLocalizedString(resId, nil)];
    }
    
    return result;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSAssert(cell != nil, @"cell == nil");
  
    // Configure the cell...
    NSInteger row = indexPath.row;
    NSUInteger count = self.takeReadingRemindersStore.count;
    
    if (row >= count)
        return;
    
    EKEvent *event = [self.takeReadingRemindersStore reminderEventAtIndex:row];

    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    /* The title text of the cell will be the title of the event */
    cell.textLabel.text = event.title;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0f];
    cell.detailTextLabel.numberOfLines = 2;
    
    BOOL alldayEvent = event.allDay;

    NSString *detailText = nil;
    
    if (!event.hasRecurrenceRules)
    {
        if (alldayEvent)
        {
            NSString *startDateString = [self.shortStyleDateNoTimeFormatter stringFromDate:event.startDate];
            detailText = [NSString stringWithFormat:NSLocalizedString(@"ALL_DAY_REMINDER_EVENT", nil), startDateString];
        } 
        else 
        {
            NSString *startDateString = [self.shortStyleDateTimeFormatter stringFromDate:event.startDate];
            NSDateComponents *deltaDateComp = [NSDate deltaFromDate:event.startDate toDate:event.endDate];
            NSString *apptDuration = [NSDate durationFromDateComponents:deltaDateComp];
            
            detailText = [NSString stringWithFormat:NSLocalizedString(@"REMINDER_EVENT_DATE_TIME", nil), startDateString, apptDuration];
         }
    }
    else
    {
        NSString *detailFormatString = nil;
        NSDateFormatter *dateFormatter = nil;
        
        EKRecurrenceRule *recurRule = (EKRecurrenceRule *)[event.recurrenceRules objectAtIndex:0];
        
        NSInteger interval = recurRule.interval;
        EKRecurrenceFrequency freq = recurRule.frequency;
        EKRecurrenceEnd *recurEnd = recurRule.recurrenceEnd;
        
        NSString *occurencesDesc = getRepeatIntervalDesc(interval, freq);
        NSString *terminatingDesc = nil;

        dateFormatter = alldayEvent 
                            ? self.shortStyleDateNoTimeFormatter
                            : self.shortStyleDateTimeFormatter;

        if (recurEnd != nil)
        {
            if (recurEnd.endDate != nil)
            {
                terminatingDesc = [dateFormatter stringFromDate:recurEnd.endDate];
                detailFormatString = alldayEvent 
                                        ? @"ALL_DAY_RECUR_EVENT_UNTIL_END_DATE" 
                                        : @"RECUR_EVENT_UNTIL_END_DATE";
            }
            else
            {
                NSInteger ocurrences = interval * recurEnd.occurrenceCount;
                
                terminatingDesc = getRepeatIntervalDesc(ocurrences, freq);
                
                detailFormatString = alldayEvent
                                        ? @"ALL_DAY_RECUR_EVENT_UNTIL_OCCURENCES_REACHED"
                                        : @"RECUR_EVENT_UNTIL_OCCURENCES_REACHED"; 
            }
        }
        else
        {
            detailFormatString = alldayEvent
                                    ? @"ALL_DAY_RECUR_EVENT"
                                    : @"RECUR_EVENT";
        }
        
        NSString *startDateString = [dateFormatter stringFromDate:event.startDate];
        NSString *apptDuration = nil;
        
        if (!alldayEvent)
        {
            NSDateComponents *deltaDateComp 
                    = [NSDate deltaFromDate:event.startDate toDate:event.endDate];
            apptDuration = [NSDate durationFromDateComponents:deltaDateComp];
        }
        
        if (!terminatingDesc)
        {
            if (apptDuration)
            {
                detailText 
                    = [NSString stringWithFormat:NSLocalizedString(detailFormatString, nil),
                                        startDateString, apptDuration, occurencesDesc];
            }
            else
            {
                detailText 
                = [NSString stringWithFormat:NSLocalizedString(detailFormatString, nil),
                   startDateString, occurencesDesc];
            }
        }
        else
        {
            if (apptDuration)
            {
                detailText
                    = [NSString stringWithFormat:NSLocalizedString(detailFormatString, nil), 
                       startDateString, apptDuration, occurencesDesc, terminatingDesc];
                
            }
            else
            {
                detailText
                    = [NSString stringWithFormat:NSLocalizedString(detailFormatString, nil), 
                       startDateString, occurencesDesc, terminatingDesc];
            }
        }
    }
    
    cell.detailTextLabel.text = detailText;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) 
    {
        NSError * __autoreleasing error = nil;
        
        // Delete the row from the data source passing the store since it is our responsiblity to delete 
        // the actual event from the calendar.
        if ([self.takeReadingRemindersStore deleteReminderEventAtIndex:indexPath.row eventStore:self.takeReadingRemindersStore.eventStore error:&error])
        {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
        }
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) 
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - TableView Methods

- (void)configureBarButtons:(UINavigationItem *)navItem editMode:(BOOL)editMode
{
    if (navItem == nil)
    {
        return;
    }
    
    if (navItem.leftBarButtonItem == nil)
    {
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        navItem.leftBarButtonItem = self.editButtonItem;
    }
    
    if (editMode)
    {
        navItem.rightBarButtonItem = nil;
    }
    else
    {
        UIBarButtonItem *addNewItem = self.addNewItemButton;
        
        if (addNewItem == nil)
        {
            // Add a '+' bar button for adding a new bp reading.
            addNewItem = [[UIBarButtonItem alloc]
                          initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                          target:self
                          action:@selector(addEvent:)];
            
            self.addNewItemButton = addNewItem;
        }
        
        navItem.rightBarButtonItem = addNewItem;
    }
}

- (void)configureBarButtons:(BOOL)editMode
{
    UINavigationItem *navItem = self.navigationItem;

    [self configureBarButtons:navItem editMode:editMode];
}

- (void)setEditing:(BOOL)flag animated:(BOOL)animated
{
	// Always call super implementation of this method,
	// it needs to do work.
	[super setEditing:flag animated:animated];
	
	NSLog(@"setEditing: flag = %d, animated = %d", flag, animated);

    self.editingEvent = flag;
    
    [self configureBarButtons:flag];

    /*
    if (flag)
    {
        if (self.registeredEventStoreChangeNotifications)
        {
            [self unregisterForEventStoreChangeNotifications];
        }
    }
    else
    {
        [self reloadEventDataAndTableView];
        [self registerForEventStoreChangeNotifications];
    }
    */
    
#if 0	
	// You need to insert / remove a new row in to the table view.
	if (flag)
	{
		// If entering edit mode, add another row to our table view.
		NSIndexPath *indexPath =
		[NSIndexPath indexPathForRow:[possessions count] inSection:0];
		
		NSArray *paths = [NSArray arrayWithObject:indexPath];
		
		[[self tableView] insertRowsAtIndexPaths:paths
								withRowAnimation:UITableViewRowAnimationLeft];
	}
	else 
	{
		// If leaving edit mode, remove last row from table view.
		NSIndexPath *indexPath = 
		[NSIndexPath indexPathForRow:[possessions count] inSection:0];
		
		NSArray *paths = [NSArray arrayWithObject:indexPath];
		
		[[self tableView] deleteRowsAtIndexPaths:paths
								withRowAnimation:UITableViewRowAnimationFade];
		
	}
#endif	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    NSUInteger row = (NSUInteger)indexPath.row;
    
    if (row < self.takeReadingRemindersStore.count)
    {
        [self.tableViewUserDefaultsHelper saveSelectedIndex:indexPath withEditFlag:YES];

        EKEvent *selectedEvent = [self.takeReadingRemindersStore reminderEventAtIndex:row];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        [userDefaults setObject:selectedEvent.eventIdentifier 
                         forKey:reminderTableViewSelectionIdKey];
        
        [userDefaults synchronize];
        
        // When a row in the tableview is selected, create an EventViewControllerCustomDelegate to display the event.
        EventViewAndEditController *eventViewAndEditController = [[EventViewAndEditController alloc] initWithNibName:nil bundle:nil];
        
        // set the addController's event store to the current event store.
        eventViewAndEditController.event = selectedEvent;
        eventViewAndEditController.origEventId = eventViewAndEditController.event.eventIdentifier;
        eventViewAndEditController.allowsEditing = YES;
        eventViewAndEditController.eventViewAndEditDelegate = self;
        eventViewAndEditController.eventStore = self.takeReadingRemindersStore.eventStore;
        
        self.editingEvent = YES;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            CGRect rowRect = [tableView rectForRowAtIndexPath:indexPath];
            
            self.eventPopoverController = [[UIPopoverController alloc] initWithContentViewController:eventViewAndEditController];
            [self.eventPopoverController presentPopoverFromRect:rowRect inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            self.eventPopoverController.delegate = self;
        }
        else
        {
            //  Push detailViewController onto the navigation controller stack
            //  If the underlying event gets deleted, detailViewController will remove itself from
            //  the stack and clear its event property.
            [self.navigationController pushViewController:eventViewAndEditController animated:YES];
        }
    }
}

#pragma mark - Event Store Change Notification

- (void)registerForEventStoreChangeNotifications
{
    const NSTimeInterval TimerIntervalInSecs = 1.0f / 3.0f;
    
    if (!self.registeredEventStoreChangeNotifications)
    {
        self.actOnEventStoreUpdatesTimer = [NSTimer timerWithTimeInterval:TimerIntervalInSecs 
                                                                   target:self selector:@selector(actOnEventStoreUpdatesTimerMethod:) 
                                                                 userInfo:nil 
                                                                  repeats:YES];
        
        [[NSRunLoop currentRunLoop] addTimer:self.actOnEventStoreUpdatesTimer forMode:NSDefaultRunLoopMode];

        ReminderViewController * __weak weakSelf = self;
        
        self.eventStoreChangeObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:EKEventStoreChangedNotification
                                                           object:self.takeReadingRemindersStore.eventStore
                                                            queue:[NSOperationQueue mainQueue]
                                                       usingBlock:^(NSNotification *notification)
                                        {
                                            NSLog(@"ReminderViewController: Did receive EKEventStoreChangedNotification");
                                            
                                            weakSelf.eventStoreChanged = YES;
                                        }];
 
        self.registeredEventStoreChangeNotifications = YES;
        
        NSLog(@"ReminderViewController -> Registered for Event Store Change Notifications.");
    }
}

- (void)unregisterForEventStoreChangeNotifications
{
    if (self.registeredEventStoreChangeNotifications)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self.eventStoreChangeObserver
                                                        name:EKEventStoreChangedNotification
                                                      object:nil];
        
        [self.actOnEventStoreUpdatesTimer invalidate];
        self.actOnEventStoreUpdatesTimer = nil;
        self.registeredEventStoreChangeNotifications = NO;
        
        NSLog(@"ReminderViewController -> Unregistered for Event Store Change Notifications.");
    }
}

- (void)actOnEventStoreUpdatesTimerMethod:(NSTimer*)theTimer
{
    if (!self.editingEvent && [self isVisible])
    {
//        NSLog(@"Timer fired ... Not editing reminders and view is visible.");

        // This timer is guaranteed to fire on the main thread.
        // No need to synchronize since all notifications are being
        // delivered on the main thread as well.
        if (self.eventStoreChanged)
        {
            NSLog(@"Timer fired ... Reloading reminders.");
            self.eventStoreChanged = NO;
            [self reloadEventDataAndTableView];
        }
    }
}

#pragma mark - Application State Change Notifications.

- (void)registerForApplicationStateChangeNotifications
{
    if (!self.registeredApplicationStateNotifications)
    {
        NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        
        ReminderViewController * __weak weakSelf = self;
        
        self.appDidEnterBackgroundObserver =
            [center addObserverForName:UIApplicationDidEnterBackgroundNotification
                                object:nil
                                 queue:mainQueue
                            usingBlock:^(NSNotification *notification)
             {
                 NSLog(@"ReminderViewController: Did receive UIApplicationDidEnterBackgroundNotification");
                 weakSelf.inBackgroundState = YES;
             }];
             
        self.appDidBecomeActiveObserver =
             [center addObserverForName:UIApplicationDidBecomeActiveNotification
                                 object:nil
                                  queue:mainQueue
                             usingBlock:^(NSNotification *notification)
            {
                NSLog(@"ReminderViewController: Did receive UIApplicationDidBecomeActiveNotification");
                
                weakSelf.inBackgroundState = NO;
                
                if (!weakSelf.editingEvent)
                {
                    [weakSelf registerForEventStoreChangeNotifications];
                }
            }];
        
        self.registeredApplicationStateNotifications = YES;
        
        NSLog(@"ReminderViewController -> Registered for application state changes.");
    }
}

- (void)unregisterForApplicationStateChangeNotifications
{
    if (self.registeredApplicationStateNotifications)
    {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

        [center removeObserver:self.appDidBecomeActiveObserver name:UIApplicationDidBecomeActiveNotification object:nil];
        [center removeObserver:self.appDidEnterBackgroundObserver name:UIApplicationDidEnterBackgroundNotification object:nil];
        self.registeredApplicationStateNotifications = NO;
        
        NSLog(@"ReminderViewController -> Unregistered for application state changes.");
    }
}

@end
