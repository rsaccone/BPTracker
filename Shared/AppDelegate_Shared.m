//
//  AppDelegate_Shared.m
//  BPTracker
//
//  Created by Robert Saccone on 1/23/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "AppDelegate_Shared.h"

#import <math.h>

#import <SLexUtil/NSErrorHelper.h>
#import "BPGraphViewController.h"
#import "BPReadingListViewController.h"
#import "ExportDataViewController.h"
#import "ReminderPermissionProxyViewController.h"
#import "ReminderViewController.h"
#import "TakeReadingRemindersStoreMgr.h"
#import "URLHandler.h"
#import "UserSettingKeys.h"

#if defined(BPTRACKER_LITE)

#import "BannerViewController.h"

#endif

@interface AppDelegate_Shared ()<UITabBarControllerDelegate, URLHandlerDelegate>

- (void)setupCoreDataStack;
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController;

- (void)handlerCompletion:(URLHandler *)urlHandler;

@property(nonatomic, weak) id mocDidSaveObserver;
@property(nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property(nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property(nonatomic, strong) NSManagedObjectContext *privateWriterContext;
@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) URLHandler *urlHandler;

@end

@implementation AppDelegate_Shared
{
@private
    UIWindow *window;
    
    NSManagedObjectModel *managedObjectModel_;
    NSManagedObjectContext *privateWriterContext_;
    NSManagedObjectContext *managedObjectContext_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
    id<TakeReadingRemindersStore> takeReadingRemindersStore_;
    URLHandler *urlHandler_;
}

@synthesize window;
@synthesize mocDidSaveObserver;
@synthesize managedObjectModel = managedObjectModel_;
@synthesize persistentStoreCoordinator = persistentStoreCoordinator_;
@synthesize privateWriterContext = privateWriterContext_;
@synthesize managedObjectContext = managedObjectContext_;
@synthesize urlHandler = urlHandler_;

#pragma mark - Application class level initialization

+ (void)initialize
{
    if (self == [AppDelegate_Shared class]) 
    {
        NSBundle* bundle = [NSBundle mainBundle];
        NSString* plistPath = [bundle pathForResource:@"DefaultSettings" ofType:@"plist"];
    
        NSDictionary *defSettings = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:defSettings];
    }
}

#pragma mark -
#pragma mark Application lifecycle

static void registerDefaultPreferenceValues()
{
    NSNumber *trueValue = [NSNumber numberWithBool:YES];
    
    // Register the preference defaults early.
    NSDictionary *appDefaults = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 trueValue, bpGraphSystolicDataKey,
                                 trueValue, bpGraphDiastolicDataKey,
                                 trueValue, bpGraphPulseDataKey, nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    
}

static NSUInteger getSelectedTabFromSettings(NSUInteger maxIndex)
{
    NSUInteger selectedTab = 0;
    
    NSNumber *tabNumber = [[NSUserDefaults standardUserDefaults] objectForKey:selectedTabKey];
    
    if (tabNumber)
    {
        selectedTab = [tabNumber unsignedIntValue];
    }
    
    selectedTab = MIN(selectedTab, maxIndex);
    
    return selectedTab;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    registerDefaultPreferenceValues();
    
    [self setupCoreDataStack];

    UITabBarController *tabBarController = [[UITabBarController alloc] init];

    [tabBarController.tabBar setTranslucent:YES];
    
    tabBarController.delegate = self;
    
    NSUInteger tabCount = [self setupTabBarController:tabBarController];

    [[self window] setRootViewController:tabBarController];
    
    NSUInteger selectedTab = getSelectedTabFromSettings(tabCount - 1);
    
    tabBarController.selectedIndex = selectedTab;
     
    [[self window] makeKeyAndVisible];
    
	return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if (url != nil && [url isFileURL])
    {
        NSError *error;
        
        NSLog(@"Request to open url %@", url);
        self.urlHandler = [[URLHandler alloc] initWithURL:url parentManagedObjectContext:self.managedObjectContext initError:&error];
        
        if (self.urlHandler != nil)
        {
            [self.urlHandler begin:self];
        }
    }
    
    return YES;
}


/**
 Save changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application 
{
//    [self saveContext];
}


- (void)applicationDidEnterBackground:(UIApplication *)application 
{
//    [self saveContext];
}


- (void)saveContext 
{
    NSError * __autoreleasing error = nil;
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            dumpNSError(error, nil);
            
            abort();
        } 
    }
} 

#pragma mark - Core Data stack

- (void)setupCoreDataStack
{
    // setup managed object model
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"BPTracker" withExtension:@"momd"];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    // setup persistent store coordinator
    NSError * __autoreleasing error = nil;
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"BPTracker.sqlite"];
    
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    // create writer MOC
    privateWriterContext_ = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [privateWriterContext_ setPersistentStoreCoordinator:persistentStoreCoordinator_];
    
    // create MOC
    managedObjectContext_ = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    managedObjectContext_.parentContext = privateWriterContext_;
    
    AppDelegate_Shared * __weak weakSelf = self;
    
    // subscribe to save notifications on the main queue moc.
    self.mocDidSaveObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                          object:managedObjectContext_
                                                           queue:nil
                                                      usingBlock:^(NSNotification *note)
                                                                 {
                                                                     AppDelegate_Shared * __strong strongSelf = weakSelf;
                                                                     
                                                                     if (strongSelf != nil)
                                                                     {
                                                                         [strongSelf->privateWriterContext_ performBlock:^()
                                                                         {
                                                                             [strongSelf->privateWriterContext_ save:nil];
                                                                         }];
                                                                     }
                                                                 }];
}

#pragma mark - TakeReadingRemindersStore

- (id<TakeReadingRemindersStore>)takeReadingRemindersStore
{
    if (takeReadingRemindersStore_ == nil)
    {
        takeReadingRemindersStore_ = [[TakeReadingRemindersStoreMgr alloc] initWithManagedObjectContext:self.managedObjectContext];
    }
    
    return takeReadingRemindersStore_;
}

#pragma mark - UITabBarControllerDelegate implementation

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    NSUInteger selectedIndex = tabBarController.selectedIndex;
    
    NSNumber *tabNumber = [NSNumber numberWithUnsignedLong:selectedIndex];
    
    [[NSUserDefaults standardUserDefaults] setObject:tabNumber forKey:selectedTabKey];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark URLHandlerDelegate implementation

- (void)checkAndClearURLHandler:(URLHandler *)urlHandler
{
    if (self.urlHandler == urlHandler)
    {
        NSLog(@"URL handler completion notification.  Clearing urlHandler reference.");
        self.urlHandler = nil;
    }
}

- (void)handlerCompletion:(URLHandler *)urlHandler
{
    if ([NSThread isMainThread])
    {
        [self checkAndClearURLHandler:urlHandler];
    }
    else
    {
        AppDelegate_Shared * __weak weakSelf = self;
        
        dispatch_sync(dispatch_get_main_queue(), ^()
                      {
                          [weakSelf checkAndClearURLHandler:urlHandler];
                      });
    }
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory 
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


#pragma mark - Memory management

- (void)dealloc
{
    if (self.mocDidSaveObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self.mocDidSaveObserver];
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}

#pragma mark - View Setup Methods That Derived classes should implement.

- (NSUInteger)setupTabBarController:(UITabBarController *)tabBarController;
{
    [self doesNotRecognizeSelector:_cmd];
    
    return 0;
}

@end

