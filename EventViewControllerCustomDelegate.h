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


@interface EventViewControllerCustomDelegate : EKEventViewController
{
@private
    EKEventStore *eventStore_;
    id<EKEventEditViewDelegate> editViewDelegate_;
}

@property(nonatomic, retain) EKEventStore *eventStore;
@property(nonatomic, assign) id<EKEventEditViewDelegate> editViewDelegate;

@end
