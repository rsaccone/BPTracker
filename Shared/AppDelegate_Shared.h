//
//  AppDelegate_Shared.h
//  BPTracker
//
//  Created by Robert Saccone on 1/23/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "TakeReadingRemindersStore.h"

@class BPReadingListViewController;

@interface AppDelegate_Shared : NSObject <UIApplicationDelegate> 

@property (nonatomic, strong) IBOutlet UIWindow *window;

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readonly) id<TakeReadingRemindersStore> takeReadingRemindersStore;

+ (void)initialize;

- (NSURL *)applicationDocumentsDirectory;
- (void)saveContext;

- (NSUInteger)setupTabBarController:(UITabBarController *)tabBarController;

@end

