//
//  ReminderPermisionProxyViewController.m
//  BPTracker
//
//  Created by Robert Saccone on 4/16/13.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "ReminderPermissionProxyViewController.h"

#import "BannerViewController.h"
#import <SLexUtil/UIAlertView+Blocks.h>
#import "ReminderViewController.h"

@interface ReminderPermissionProxyViewController ()

@property(nonatomic, strong) id<TakeReadingRemindersStore> takeReadingRemindersStore;
@property(nonatomic, strong) ReminderViewController *reminderViewController;

@end

@implementation ReminderPermissionProxyViewController
{
    BOOL askForPermission_;
}

@synthesize takeReadingRemindersStore;

- (id)initWithTakeReadingRemindersStore:(id<TakeReadingRemindersStore>)store;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        self.takeReadingRemindersStore = store;
        
        UITabBarItem *tbi = [self tabBarItem];
        
        [tbi setTitle:NSLocalizedString(@"REMINDER_CONTROLLER_TITLE", nil)];
        UIImage *image = [UIImage imageNamed:@"calendar.png"];
        [tbi setImage:image];
        askForPermission_ = YES;
        _reminderViewController = [[ReminderViewController alloc] initWithTakeReadingRemindersStore:store];
        [_reminderViewController configureBarButtons:self.navigationItem editMode:NO];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    self.title = NSLocalizedString(@"REMINDER_CONTROLLER_TITLE", nil);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self->askForPermission_)
    {
        [self askForCalAccessPermission];
    }
    else
    {
        self->askForPermission_ = YES;
    }
}

- (void)askForCalAccessPermission
{
    ReminderPermissionProxyViewController * __weak weakSelf = self;
    self->askForPermission_ = NO;
    
    StoreAccessRequestResult result =
    [self.takeReadingRemindersStore requestAccessToStore:NO completionHandler:^(StoreAccessRequestResult storeAccReqResult, NSError *error)
                                                         {
                                                             if (storeAccReqResult == StoreAccessRequestGranted)
                                                             {
                                                                 if ([NSThread isMainThread])
                                                                 {
                                                                     [weakSelf swapInReminderView];
                                                                 }
                                                                 else
                                                                 {
                                                                     dispatch_sync(dispatch_get_main_queue(), ^()
                                                                                   {
                                                                                       [weakSelf swapInReminderView];
                                                                                   });
                                                                 }
                                                             }
                                                         }];
    
    if (result == StoreAccessRequestGranted)
    {
        [self swapInReminderView];
    }
    else
    {
        UIAlertView * alertView = [[UIAlertView alloc]
                                   initWithTitle:NSLocalizedString(@"CALENDAR_ACCESS_DENIED", nil)
                                   message:NSLocalizedString(@"ENABLE_CALENDAR_ACCESS", nil)
                                   clickedButtonBlock:^(UIAlertView *alertView, NSInteger buttonIndex)
                                   {
                                   }
                                   cancelButtonTitle:NSLocalizedString(@"OK_BUTTON_LABEL", @"OK button label")
                                   otherButtonTitles:nil];
        
        [alertView show];
    }
}

- (void)swapInReminderView
{
#if !defined(BPTRACKER_LITE)

    UINavigationController *navController = self.navigationController;
    
    if (navController)
    {
        NSArray *vcArray = [NSArray arrayWithObject:self.reminderViewController];
        self.reminderViewController = nil;
        
        [navController setViewControllers:vcArray];
    }
    
#else
 
    BannerViewController *bvc = (BannerViewController *)self.parentViewController;
    bvc.contentController =  self.reminderViewController;
    self.reminderViewController = nil;
    UINavigationController *navController = bvc.navigationController;
    
    if (navController)
    {
        NSArray *vcArray = [NSArray arrayWithObject:bvc];
        
        [navController setViewControllers:vcArray];
    }
    
#endif
}

@end
