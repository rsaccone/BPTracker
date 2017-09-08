//
//  BPReadingNoteTaker.h
//  BPTracker
//
//  Created by Robert Saccone on 10/17/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NoteTakerViewController;

@protocol NoteTakerViewControllerDelegate <NSObject>

@required
- (void)noteTakerViewControllerShouldBeDismissed:(NoteTakerViewController *)viewController;

@end

@interface NoteTakerViewController : UIViewController
{
}

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;
- (id)init;
- (id)initWithNoteText:(NSString *)noteText;

@property(nonatomic, weak) id<NoteTakerViewControllerDelegate> delegate;
@property(nonatomic, weak) IBOutlet UITextView *notesField;
@property(nonatomic, copy, readonly) NSString *noteText;
@property(nonatomic, assign, readonly) BOOL canceled;

@end
