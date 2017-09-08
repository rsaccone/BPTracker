//
//  EventViewControllerCustomDelegate.h
//  BPTracker
//
//  Created by Robert Saccone on 3/3/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKitUI/EKEventViewController.h>
#import <EventKitUI/EKEventEditViewController.h>

typedef enum 
{
    EventViewAndEditActionCanceled,
    EventViewAndEditActionDone,
    EventViewAndEditActionSaved,
    EventViewAndEditActionResponded,
    EventViewAndEditActionDeleted
} EventViewAndEditAction;

@class EventViewAndEditController;

@protocol EventViewAndEditDelegate<NSObject>

- (void)eventViewAndEditController:(EventViewAndEditController *)controller didCompleteWithAction:(EventViewAndEditAction)action;

@end

@interface EventViewAndEditController : EKEventViewController
{
@private
    EKEventStore *eventStore_;
    NSString *origEventId_;
    id<EventViewAndEditDelegate> __weak eventViewAndEditDelegate_;
}

@property(nonatomic, strong) EKEventStore *eventStore;
@property(nonatomic, copy) NSString *origEventId;
@property(nonatomic, weak) id<EventViewAndEditDelegate> eventViewAndEditDelegate;

@end
