//
//  ReminderPermisionProxyViewController.h
//  BPTracker
//
//  Created by Robert Saccone on 4/16/13.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TakeReadingRemindersStore.h"

@interface ReminderPermissionProxyViewController : UIViewController

- (id)initWithTakeReadingRemindersStore:(id<TakeReadingRemindersStore>)store;

@end
