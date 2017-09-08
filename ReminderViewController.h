//
//  ReminderViewController.h
//  BPTracker
//
//  Created by Robert Saccone on 1/30/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TakeReadingRemindersStore.h"

@interface ReminderViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate>

// Designated initializer.
- (id)initWithTakeReadingRemindersStore:(id<TakeReadingRemindersStore>)takeReadingRemindersStore;
- (void)configureBarButtons:(UINavigationItem *)navItem editMode:(BOOL)editMode;

@end
