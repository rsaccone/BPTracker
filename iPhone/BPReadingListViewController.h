//
//  BPReadingListViewController.h
//  BPTracker
//
//  Created by Robert Saccone on 1/25/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BPReadingDetailViewController;
@class BloodPressureReading;
@protocol BPReadingSelectionViewController;

@interface BPReadingListViewController : UITableViewController<NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate> 

// Designated initializer.
-(id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@property(nonatomic, weak) id<BPReadingSelectionViewController> readingSelectionViewController;

@end
