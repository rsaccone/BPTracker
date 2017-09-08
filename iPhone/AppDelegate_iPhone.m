//
//  AppDelegate_iPhone.m
//  BPTracker
//
//  Created by Robert Saccone on 1/23/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "AppDelegate_iPhone.h"

#import "BannerViewController.h"
#import "BPGraphViewController.h"
#import "BPReadingListViewController.h"
#import "ExportDataViewController.h"
#import "ReminderPermissionProxyViewController.h"
#import "ReminderViewController.h"
#import "TakeReadingRemindersStoreMgr.h"

@implementation AppDelegate_iPhone


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
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


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.

     Superclass implementation saves changes in the application's managed object context before the application terminates.
     */
	[super applicationDidEnterBackground:application];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of the transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


/**
 Superclass implementation saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
	[super applicationWillTerminate:application];
}


#pragma mark - Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
    [super applicationDidReceiveMemoryWarning:application];
}

#pragma mark - View Releated Setup Method Overrides from Base Class

- (NSUInteger)setupTabBarController:(UITabBarController *)tabBarController
{
    NSMutableArray *viewControllers = [NSMutableArray arrayWithCapacity:4];
    
    [viewControllers addObject:[[BPReadingListViewController alloc] initWithManagedObjectContext:self.managedObjectContext]];

    [viewControllers addObject:[[BPGraphViewController alloc] initWithManagedObjectContext:self.managedObjectContext]];
    
    id<TakeReadingRemindersStore> takeReadingRemindersStore = [[TakeReadingRemindersStoreMgr alloc] initWithManagedObjectContext:self.managedObjectContext];
    
    if (takeReadingRemindersStore.shouldAttemptPermissionRequest)
    {
        [viewControllers addObject:[[ReminderPermissionProxyViewController alloc] initWithTakeReadingRemindersStore:takeReadingRemindersStore]];
    }
    else
    {
        [viewControllers addObject:[[ReminderViewController alloc] initWithTakeReadingRemindersStore:takeReadingRemindersStore]];
    }
    
//#if !defined(BPTRACKER_LITE)
    
//    [viewControllers addObject:[[ExportDataViewController alloc] initWithManagedObjectContext:self.managedObjectContext]];
    
//#endif
    
    NSUInteger count = [viewControllers count];
    
    for (NSUInteger index = 0; index < count; ++index)
    {
        
#if defined(BPTRACKER_LITE)
        
        viewControllers[index] = [[BannerViewController alloc] initWithContentViewController:viewControllers[index]];

#endif

        viewControllers[index] = [[UINavigationController alloc] initWithRootViewController:viewControllers[index]];

        
    }
    
    [tabBarController setViewControllers:viewControllers];
    
    return [viewControllers count];
}

@end

