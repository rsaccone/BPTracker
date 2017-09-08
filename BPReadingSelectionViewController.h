//
//  BPReadingSelectionDelegate.h
//  BPTracker
//
//  Created by Robert Saccone on 4/27/14.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BloodPressureReading.h"

@class BPReadingDetailViewController;

typedef void (^ReadingDismissedBlock)(BOOL saved);

@protocol BPReadingSelectionViewControllerDelegate

@required

- (void)modeChanged:(BOOL)editing;

@end

@protocol BPReadingSelectionViewController <NSObject>

@required

- (void)selectedReading:(BloodPressureReading *)bpReading
             completion:(ReadingDismissedBlock)readingDismissed;

- (void)editNewReading:(BloodPressureReading *)bpReading
            completion:(ReadingDismissedBlock)readingDismissed;

- (void)popTopLevelReading;

@property(nonatomic, assign) id<BPReadingSelectionViewControllerDelegate> delegate;
@property(nonatomic, assign, readonly) BOOL editingNewReading;
@property(nonatomic, strong) BPReadingDetailViewController *currBPReadingDetailViewController;
@property(nonatomic, readonly) BloodPressureReading *currBPReading;

@end
