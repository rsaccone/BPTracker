//
//  BPReadingDetailView.h
//  BPTracker
//
//  Created by Robert Saccone on 1/30/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BloodPressureReading;
@class DatePickerViewController;
@class NoteTakerViewController;
@class BPReadingDetailViewController;

typedef BOOL (^DoneUpdatingBloodPressureReadingBlock)(BOOL saved);

@protocol BPReadingDetailViewControllerDelegate <NSObject>

- (void)modeChanged:(BOOL)editing;

- (BOOL)doneUpdatingBloodPressureReading:(BPReadingDetailViewController *)viewController bloodPressureReading:(BloodPressureReading *)reading saved:(BOOL)saved newReading:(BOOL)newReading;

@end

@interface BPReadingDetailViewController : UIViewController<UITextViewDelegate, UITextFieldDelegate>

// Designated initializer for this class.
- (id)init:(BloodPressureReading *)bloodPressureReading newReading:(BOOL)newBPReading
                                            setDefaultsFromReading:(BOOL)defaultsFromReading
                                            doneCallback:(DoneUpdatingBloodPressureReadingBlock)doneCallbackBlock;


// Designated initializer for this class.
- (id)init:(BloodPressureReading *)bloodPressureReading newReading:(BOOL)newBPReading
                                            setDefaultsFromReading:(BOOL)defaultsFromReading
                                            viewControllerDelegate:(id<BPReadingDetailViewControllerDelegate>)delegate;

// Cancels any editing action underway.
- (void)cancelEditMode;

@property(nonatomic, strong) BloodPressureReading *bloodPressureReading;
@property(nonatomic, assign) BOOL allowEditing;
@property(nonatomic, readonly, assign) BOOL newReading;
@property(nonatomic, readonly, assign) BOOL editMode;
@property(nonatomic, readonly, assign) BOOL canceled;
@property(nonatomic, readonly, assign) BOOL updated;

@end
