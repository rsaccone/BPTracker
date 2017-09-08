//
//  AppDelegate_iPad.m
//  BPTracker
//
//  Created by Robert Saccone on 1/23/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "AppDelegate_iPad.h"

#import "BannerViewController.h"
#import "BPDetailViewController.h"
#import "BPGraphViewController.h"
#import "BPReadingListViewController.h"
#import "ExportDataViewController.h"
#import "ReminderPermissionProxyViewController.h"
#import "ReminderViewController.h"
#import "TakeReadingRemindersStoreMgr.h"

@interface CustomSplitViewController : UISplitViewController

@end

@implementation CustomSplitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.edgesForExtendedLayout = NO; //UIRectEdgeBottom;
    self.extendedLayoutIncludesOpaqueBars = YES;
}

- (void)viewDidLayoutSubviews
{
}

@end

@interface AppDelegate_iPad ()

- (UIViewController *)createBPReadingListViewController;
- (NSUInteger)placeViewControllersInTabController:(UITabBarController *)tabBarController;

@end

@implementation AppDelegate_iPad

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    
    // Override point for customization after application launch.
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive.
     */
}


/**
 Superclass implementation saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
	[super applicationWillTerminate:application];
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
    [super applicationDidReceiveMemoryWarning:application];
}

#pragma mark - View Releated Setup Method Overrides from Base Class

- (NSUInteger)setupTabBarController:(UITabBarController *)tabBarController
{
    return [self placeViewControllersInTabController:tabBarController];
}

- (NSUInteger)placeViewControllersInTabController:(UITabBarController *)tabBarController
{
    NSMutableArray *viewControllers = [NSMutableArray arrayWithCapacity:4];
    
    [viewControllers addObject:[self createBPReadingListViewController]];
    
    UIViewController *vc = [[BPGraphViewController alloc] initWithManagedObjectContext:self.managedObjectContext];

    [viewControllers addObject:vc];
    
    id<TakeReadingRemindersStore> takeReadingRemindersStore = [[TakeReadingRemindersStoreMgr alloc] initWithManagedObjectContext:self.managedObjectContext];
    
    if (takeReadingRemindersStore.shouldAttemptPermissionRequest)
    {
        vc = [[ReminderPermissionProxyViewController alloc] initWithTakeReadingRemindersStore:takeReadingRemindersStore];
    }
    else
    {
        vc = [[ReminderViewController alloc] initWithTakeReadingRemindersStore:takeReadingRemindersStore];
    }

    [viewControllers addObject:vc];
    
#if 0
    
#if !defined(BPTRACKER_LITE)

    vc = [[ExportDataViewController alloc] initWithManagedObjectContext:self.managedObjectContext];
    
    [viewControllers addObject:vc];
    
#endif
    
#endif
    
    NSUInteger count = [viewControllers count];
    
    for (NSUInteger index = 0; index < count; ++index)
    {
#if defined(BPTRACKER_LITE)

        viewControllers[index] = [[BannerViewController alloc] initWithContentViewController:viewControllers[index]];
        
#endif

        // Index 0 is the splitview controller used for the readings. Don't
        // encapsulate it inside of a UINavigationController.
        if (index != 0)
        {
            viewControllers[index] = [[UINavigationController alloc] initWithRootViewController:viewControllers[index]];
        }
    }
    
    [tabBarController setViewControllers:viewControllers];
    
    return [viewControllers count];
}

- (UIViewController *)createBPReadingListViewController
{
    UISplitViewController *splitViewController = [[CustomSplitViewController alloc] init];

    BPReadingListViewController *bpReadingListViewController = [[BPReadingListViewController alloc] initWithManagedObjectContext:self.managedObjectContext];
    UINavigationController *bpReadingNav = [[UINavigationController alloc] initWithRootViewController:bpReadingListViewController];

    BPDetailViewController *detail = [[BPDetailViewController alloc] init];
    
    bpReadingListViewController.readingSelectionViewController = detail;
    
    UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:detail];
    
    splitViewController.viewControllers = [NSArray arrayWithObjects:bpReadingNav, detailNav, nil];
    splitViewController.delegate = detail;
    splitViewController.tabBarItem = bpReadingListViewController.tabBarItem;
    
    return splitViewController;
}

@end

