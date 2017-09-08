//
//  BPGraphViewController.h
//  BPTracker
//
//  Created by Robert Saccone on 6/30/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CPTGraphHostingView;

@interface BPGraphViewController : UIViewController

// Designated initializer.
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@property(nonatomic, strong) IBOutlet CPTGraphHostingView *graphHostView;

@end
