//
//  EventViewControllerCustomDelegate.m
//  BPTracker
//
//  Created by Robert Saccone on 3/3/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "EventViewAndEditController.h"

#import <EventKitUI/EKEventEditViewController.h>
#import <EventKitUI/EKEventViewController.h>

@interface EventViewAndEditController () <EKEventViewDelegate, EKEventEditViewDelegate>

- (void)editCalEvent;

@end

@implementation EventViewAndEditController

@synthesize eventStore = eventStore_;
@synthesize origEventId = origEventId_;
@synthesize eventViewAndEditDelegate = eventViewAndEditDelegate_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        // Custom initialization
        self.delegate = self;
    }
    
    return self;
}

#pragma mark - Memory management

- (void)dealloc
{
    
    // Just nil out since it is assign and NOT retain.
    eventViewAndEditDelegate_ = nil;
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *editItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit 
                                                                              target:self
                                                                              action:@selector(editCalEvent)];
    
    
    self.navigationItem.rightBarButtonItem = editItem;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)editCalEvent 
{
    EKEventEditViewController *editController = [[EKEventEditViewController alloc] init];
    
    editController.event = self.event;
    editController.eventStore = self.eventStore;
    editController.editViewDelegate = self;
    
    [self presentViewController:editController animated:YES completion:nil];
    
}

#pragma mark - EKEventViewDelegate

- (void)eventViewController:(EKEventViewController *)controller didCompleteWithAction:(EKEventViewAction)action
{
    id<EventViewAndEditDelegate> eventViewAndEditDelegate = self.eventViewAndEditDelegate;
    
    if (eventViewAndEditDelegate != nil)
    {
        switch (action) 
        {
            case EKEventViewActionDone:
                // User pressed the "Done" button. 
                [eventViewAndEditDelegate eventViewAndEditController:self didCompleteWithAction:EventViewAndEditActionDone];
                break;
                
            case EKEventViewActionResponded:
                // The user responded to a pending event invitation and saved it.
                [eventViewAndEditDelegate eventViewAndEditController:self didCompleteWithAction:EventViewAndEditActionResponded];
                break;
                
            case EKEventViewActionDeleted:
                // The event was deleted when deleting an event, remove the event from the event store, 
                // and reload table view.
                [eventViewAndEditDelegate eventViewAndEditController:self 
                                               didCompleteWithAction:EventViewAndEditActionDeleted];
                break;
                
            default:
                NSAssert(YES, @"Unexpected EKEventEditViewAction: %ld", action);
                break;
        }
    }
}

#pragma mark - EKEventEditViewDelegate

// Overriding EKEventEditViewDelegate method to update event store according to user actions
// when a new event has been created.
- (void)eventEditViewController:(EKEventEditViewController *)controller 
          didCompleteWithAction:(EKEventEditViewAction)action                                                                                                                               
{
    EventViewAndEditAction mappedAction;
    BOOL forwardAction = NO;
    BOOL oniPad = runningOniPad();


    id<EventViewAndEditDelegate> eventViewAndEditDelegate = self.eventViewAndEditDelegate;
    
    if (eventViewAndEditDelegate != nil)
    {
        switch (action) 
        {
            case EKEventEditViewActionCanceled:                                                                                                                                                                                             
                // Edit action canceled,
                mappedAction = EventViewAndEditActionCanceled;
                
                // On the iPad view is running in
                // a popover which has to be dismissed by the
                // delegate.  Otherwise on the iPhone, the
                // editing view is a modal view controller
                // that this view controller presented
                // is the responsibility of this view controller
                // to dismiss.
                if (runningOniPad())
                {
                    forwardAction = YES;
                }
                else
                {
                    forwardAction = NO;
                }
                break;
                
            case EKEventEditViewActionSaved:
                // When user hit "Done" button, save the newly created event to the event store, 
                // and reload table view.
                // If the new event is being added to the default calendar, then update its 
                // eventsList.
                forwardAction = YES;
                mappedAction = EventViewAndEditActionSaved;
                break;
                
            case EKEventEditViewActionDeleted:
                if (oniPad)
                {
                    // When running on the iPad the view is being
                    // displayed in a popover when the view controller
                    // that created this one has ownership of.
                    // It must be notified so that the popover will be
                    // removed.  However, sending the dlete action will
                    // cause incorrect behavior because the event will be
                    // deleted prematurely before the real delete notification
                    // comes in.  Send over something benign.
                    mappedAction = EventViewAndEditActionCanceled;
                    forwardAction = YES;
                }
                else
                {
                    forwardAction = NO;
                    mappedAction = EventViewAndEditActionDeleted;
                }
                break;
                
            default:
                NSAssert(YES, @"Unexpected EKEventEditViewAction: %ld", (long)action);
                forwardAction = NO;
                break;
        }
    }

    // Dismiss the modal view controller
    if (oniPad)
    {
        if (forwardAction)
        {
            [eventViewAndEditDelegate eventViewAndEditController:self didCompleteWithAction:mappedAction];
        }
    }
    else
    {
        if (forwardAction)
        {
            [self dismissViewControllerAnimated:YES
                                     completion:^(void) { [eventViewAndEditDelegate eventViewAndEditController:self didCompleteWithAction:mappedAction]; }];
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

@end
