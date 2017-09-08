//
//  ExportDataViewController.h
//  BPTracker
//
//  Created by Robert Saccone on 12/10/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MFMailComposeViewController;

typedef void (^ExportDataViewControllerCompletionCallback)(void);

@interface ExportDataViewController : UIViewController<UITextFieldDelegate>

- (id)init;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

// Designated initializer.
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@property(nonatomic, copy) ExportDataViewControllerCompletionCallback completionCallback;

@end
