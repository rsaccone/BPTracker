//
//  TakeReadingRemindersStoreMgr.m
//  BPTracker
//
//  Created by Robert Saccone on 2/25/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "TakeReadingRemindersStoreMgr.h"

#import <SLexUtil/NSErrorHelper.h>
#import "BPFetchRequestBuilderHelper.h"
#import "FetchedResultsControllerFactory.h"
#import "TakeReadingCalendarEventMetaData.h"

NSString *const TakeReadingRemindersStoreErrorDomain = @"com.softlexsystems.bptracker.RemindersStoreErrorDomain";

@interface TakeReadingRemindersStoreMgr ()

- (void)loadData;
- (void)sortData;
- (void)processReloadAction;

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, strong) NSFetchRequest *fetchRequest;
@property(nonatomic, strong) NSMutableArray *events;
@property(nonatomic, strong) NSMutableDictionary *evIdToTakeReadingCDOMap;

@end

@implementation TakeReadingRemindersStoreMgr
{
@private
    enum ReloadActionType
    {
        NoAction = 0,
        Sort,
        Data
    };
    
    NSManagedObjectContext *managedObjectContext_;
    NSFetchedResultsController *fetchedResultsController_;
    NSFetchRequest *fetchRequest_;
    NSMutableArray *events_;
    NSMutableDictionary *evIdToTakeReadingCDOMap_;
    EKCalendar *defaultCalendar_;
    EKEventStore *eventStore_;  
    int reloadAction_;
}

@synthesize managedObjectContext = managedObjectContext_;
@synthesize fetchedResultsController = fetchedResultsController_;
@synthesize fetchRequest = fetchRequest_;
@synthesize defaultCalendar = defaultCalendar_;
@synthesize events = events_;
@synthesize evIdToTakeReadingCDOMap = evIdToTakeReadingCDOMap_;
@synthesize eventStore = eventStore_;
@synthesize forceDataReload;
@synthesize shouldAttemptPermissionRequest;


// Designated initializer.
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)mgdObjectContext
{
    self = [super init];
    
    if (self != nil)
    {
        if (mgdObjectContext == nil)
        {
            NSLog(@"TakeReadingRemindersStoreMgr: nil mgdObjectContext passed!");
            NSAssert(mgdObjectContext != nil, @"mgdObjectContext is nil!");
            
            
            return nil;
        }
        
        EKEventStore *eventStore = [[EKEventStore alloc] init];    

        if (eventStore == nil)
        {
            
            return nil;
        }
        
        eventStore_ = eventStore;
        
        managedObjectContext_ = mgdObjectContext;
        reloadAction_ = Data;
    }
    
    return self;
}

- (BOOL)shouldAttemptPermissionRequest
{
    return [self.eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)];
}

- (StoreAccessRequestResult)requestAccessToStore:(BOOL)forceReset completionHandler:(StoreAccessRequestCompletionHandler)completionHandler
{
    StoreAccessRequestResult result = StoreAccessRequestDenied;
    
    if ([self.eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)])
    {
        EKAuthorizationStatus authStatus = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
        
        if (authStatus == EKAuthorizationStatusNotDetermined)
        {
            [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error)
                                                                            {
                                                                                StoreAccessRequestResult result;
                                                                                
                                                                                if (granted)
                                                                                {
                                                                                    result = StoreAccessRequestGranted;
                                                                                }
                                                                                else
                                                                                {
                                                                                    result = StoreAccessRequestDenied;
                                                                                }
                                                                                
                                                                                dispatch_sync(dispatch_get_main_queue(), ^()
                                                                                              {
                                                                                                  completionHandler(result, error);
                                                                                              });
                                                                            }];
        }
        else if (authStatus == EKAuthorizationStatusAuthorized)
        {
            result = StoreAccessRequestGranted;
        }
    }
    else
    {
        // we're on iOS 5 or older
        result = StoreAccessRequestGranted;
    }
    
    return result;
}


- (BOOL)saveReminderEvent:(EKEvent *)reminderEvent 
               eventStore:(EKEventStore *)store 
          originalEventId:(NSString *)originalId 
                    error:(NSError * __autoreleasing *)error;
{
    if (!reminderEvent)
    {
        NSAssert(NO, @"reminderEvent is nil!");
        
        NSLog(@"TakeReadingRemindersStoreMgr saveReminderEvent : reminderEvent is nil");
        
        [NSException raise:NSInvalidArgumentException format:@"TakeReadingRemindersStoreMgr saveReminderEvent : reminderEvent is nil"];
    }
    
    if (!error)
    {
        NSAssert(NO, @"error is nil!");
        
        NSLog(@"TakeReadingRemindersStoreMgr saveReminderEvent : error is nil");

        [NSException raise:NSInvalidArgumentException format:@"TakeReadingRemindersStoreMgr saveReminderEvent : error is nil"];
    }

    BOOL saveContext = NO;
    
    TakeReadingCalendarEventMetaData *calEventMetaData = nil;

    if (originalId && ([originalId compare:reminderEvent.eventIdentifier] != NSOrderedSame))
    {
        calEventMetaData = (TakeReadingCalendarEventMetaData *)[self.evIdToTakeReadingCDOMap objectForKey:originalId];
        
        NSAssert(calEventMetaData != nil, @"originalId NOT associated with calendar metadata!");
        
        if (calEventMetaData)
        {
            [self.evIdToTakeReadingCDOMap removeObjectForKey:originalId];
            
            calEventMetaData.eventIdentifier = reminderEvent.eventIdentifier; 
            
            saveContext = YES;
        }
        else
        {
            // Original id should have mapped to an a metadata object.
            NSLog(@"saveReminderEvent - originalId (%@) not associated with calendar metadata.", originalId);
            
            NSAssert(NO, @"originalId not associated with calendar metadata");
        }
    }
    
    NSAssert([calEventMetaData.eventIdentifier compare:reminderEvent.eventIdentifier] == NSOrderedSame, @"reminderEvent.eventIdentifier != calEventMetaData.eventIdentifier");

    if ((store != nil) && ![store saveEvent:reminderEvent span:EKSpanThisEvent error:error])
    {
        dumpNSError(*error, @"saveReminderEvent - Couldn't save reminder event to calendar store");

        if (saveContext)
        {
            [managedObjectContext_ rollback];
        }
        
        *error = makeNSErrorFromResources(TakeReadingRemindersStoreErrorDomain,
                                         TRSSaveError,
                                         @"SAVE_REMINDER_TO_REMINDER_STORE_FAILURE_DESCRIPTION",
                                         @"SAVE_REMINDER_TO_CALENDAR_STORE_FAILURE",
                                         @"REMINDER_STORE_FAILURE_RECOVERY_SUGGESTION",
                                         *error,
                                         nil,
                                         nil,
                                         NoStringOverrides);
        
        return NO;
    }
    
    if (saveContext)
    {
        if (![managedObjectContext_ save:error]) 
        {
            dumpNSError(*error, @"saveReminderEvent couldn't save reminder event metadata");
            
            
            *error = makeNSErrorFromResources(TakeReadingRemindersStoreErrorDomain,
                                              TRSSaveError,
                                              @"SAVE_REMINDER_TO_REMINDER_STORE_FAILURE_DESCRIPTION",
                                              @"SAVE_REMINDER_METADATA_FAILURE_REASON",
                                              @"REMINDER_STORE_FAILURE_RECOVERY_SUGGESTION",
                                              *error,
                                              nil,
                                              nil,
                                              NoStringOverrides);
            
            return NO;
        }
        
        [self.evIdToTakeReadingCDOMap removeObjectForKey:originalId];
        [self.evIdToTakeReadingCDOMap setObject:calEventMetaData forKey:calEventMetaData.eventIdentifier];
    }

    reloadAction_ = (reloadAction_ < Sort) ? Sort : reloadAction_;
    
    return YES;
}

- (BOOL)addReminderEvent:(EKEvent *)reminderEvent eventStore:(EKEventStore *)store error:(NSError * __autoreleasing *)error
{
    if (!reminderEvent)
    {
        NSAssert(NO, @"reminderEvent is nil!");
        
        NSLog(@"TakeReadingRemindersStoreMgr addReminderEvent : reminderEvent is nil");
        
        [NSException raise:NSInvalidArgumentException format:@"TakeReadingRemindersStoreMgr addReminderEvent : reminderEvent is nil"];
    }
    
    if (error == nil)
    {
        NSAssert(NO, @"error is nil!");
        
        NSLog(@"TakeReadingRemindersStoreMgr saveReminderEvent : reminderEvent is nil");
        
        [NSException raise:NSInvalidArgumentException format:@"TakeReadingRemindersStoreMgr addReminderEvent : error is nil"];
    }
    
    if ((store != nil) && ![store saveEvent:reminderEvent span:EKSpanThisEvent error:error])
    {
        dumpNSError(*error, @"addReminderEvent - couldn't save reminder event to calendar store.");
        
        *error = makeNSErrorFromResources(TakeReadingRemindersStoreErrorDomain,
                                          TRSAddError,
                                          @"ADD_REMINDER_TO_REMINDER_STORE_FAILURE_DESCRIPTION",
                                          @"ADD_REMINDER_TO_CALENDAR_STORE_FAILURE",
                                          @"REMINDER_STORE_FAILURE_RECOVERY_SUGGESTION",
                                          *error,
                                          nil,
                                          nil,
                                          NoStringOverrides);
;
        
        return NO;
    }
    
    TakeReadingCalendarEventMetaData *newCalEventMetaData = [NSEntityDescription
                                             insertNewObjectForEntityForName:@"TakeReadingCalendarEventMetaData"
                                             inManagedObjectContext:self.managedObjectContext];
    
    newCalEventMetaData.eventIdentifier = reminderEvent.eventIdentifier;
    
    
    if (![self.managedObjectContext save:error]) 
    {
        dumpNSError(*error, @"addReminderEvent = couldn't save calendar meta-data");

        *error = makeNSErrorFromResources(TakeReadingRemindersStoreErrorDomain,
                                          TRSAddError,
                                          @"ADD_REMINDER_TO_REMINDER_STORE_FAILURE_DESCRIPTION",
                                          @"ADD_REMINDER_METADATA_FAILURE_REASON",
                                          @"REMINDER_STORE_FAILURE_RECOVERY_SUGGESTION",
                                          *error,
                                          nil,
                                          nil,
                                          NoStringOverrides);
        
        return NO;
    }  
    
    [self.events addObject:reminderEvent];
    
    [self.evIdToTakeReadingCDOMap setObject:newCalEventMetaData forKey:reminderEvent.eventIdentifier];
    
    reloadAction_ = (reloadAction_ < Sort) ? Sort : reloadAction_;

    return YES;
}

- (BOOL)deleteReminderEvent:(EKEvent *)reminderEvent eventStore:(EKEventStore *)store error:(NSError * __autoreleasing *)error
{
    if (!reminderEvent)
    {
        NSAssert(NO, @"reminderEvent is nil!");
        
        NSLog(@"TakeReadingRemindersStoreMgr deleteReminderEvent : reminderEvent is nil");
        
        [NSException raise:NSInvalidArgumentException format:@"TakeReadingRemindersStoreMgr deleteReminderEvent : reminderEvent is nil"];
    }
    
    if (error == nil)
    {
        NSAssert(NO, @"error is nil!");
        
        NSLog(@"TakeReadingRemindersStoreMgr saveReminderEvent : error is nil");
        
        [NSException raise:NSInvalidArgumentException format:@"TakeReadingRemindersStoreMgr addReminderEvent : error is nil"];
    }
    
    NSString *key = reminderEvent.eventIdentifier;
    
    // Event has already been deleted from the calendar.
    // Remove its reference from the core data store.
    TakeReadingCalendarEventMetaData *calEventMetaData = (TakeReadingCalendarEventMetaData *)[self.evIdToTakeReadingCDOMap objectForKey:key];
    
    NSAssert(calEventMetaData != nil, @"Metadata for calender event NOT found!");
    
    if (calEventMetaData != nil)
    {
        if (store != nil)
        {
            if (![store removeEvent:reminderEvent span:EKSpanThisEvent error:error])
            {
                dumpNSError(*error, @"Deleting reminderEvent for calendar store failed");
                
                *error = makeNSErrorFromResources(TakeReadingRemindersStoreErrorDomain,
                                                  TRSDeleteError,
                                                  @"DELETE_REMINDER_FROM_REMINDER_STORE_FAILURE_DESCRIPTION",
                                                  @"DELETE_EVENT_FROM_CALENDAR_STORE_FAILURE",
                                                  @"REMINDER_STORE_FAILURE_RECOVERY_SUGGESTION",
                                                  *error,
                                                  nil,
                                                  nil,
                                                  NoStringOverrides);

                
                return NO;
            }
            
            NSLog(@"deleteReminderEventAtIndex, removed calendar event WITH ID %@ from store.", key);
        }
        else
        {
            NSLog(@"deleteReminderEventAtIndex, store is nil, skipping store delete of calendar event with ID %@.", key);
        }
        
        [managedObjectContext_ deleteObject:calEventMetaData];
        
        if (![managedObjectContext_ save:error]) 
        {
            if (*error)
            {    
                dumpNSError(*error, @"deleteReminderEventAtIndex, couldn't save delete of calendar metadata");
            }
            
            *error = makeNSErrorFromResources(TakeReadingRemindersStoreErrorDomain,
                                              TRSDeleteError,
                                              @"DELETE_REMINDER_FROM_REMINDER_STORE_FAILURE_DESCRIPTION",
                                              @"DELETE_REMINDER_METADATA_FAILURE",
                                              @"REMINDER_STORE_FAILURE_RECOVERY_SUGGESTION",
                                              *error,
                                              nil,
                                              nil,
                                              NoStringOverrides);
;
            
            return NO;
        }  

        if (reloadAction_ != Data)
        {
            [self.events removeObject:reminderEvent];
            [self.evIdToTakeReadingCDOMap removeObjectForKey:key];
            
        }
    }
    
    return YES;
}

- (BOOL)deleteReminderEventAtIndex:(NSUInteger)index eventStore:(EKEventStore *)store error:(NSError * __autoreleasing *)error
{
    if (error == nil)
    {
        NSAssert(NO, @"error is nil!");
        
        NSLog(@"TakeReadingRemindersStoreMgr deleteReminderEventAtIndex : error is nil");
        
        [NSException raise:NSInvalidArgumentException format:@"TakeReadingRemindersStoreMgr deleteReminderEventAtIndex : error is nil"];
    }
    
    EKEvent *reminderEvent = [self reminderEventAtIndex:index];
    
    if (!reminderEvent)
    {
        NSAssert(NO, @"reminderEvent is nil!");
        
        NSLog(@"TakeReadingRemindersStoreMgr deleteReminderEvent : reminderEvent is nil");
        
        [NSException raise:NSInvalidArgumentException format:@"TakeReadingRemindersStoreMgr deleteReminderEvent : reminderEvent is nil"];
    }
    
    NSString *key = reminderEvent.eventIdentifier;
    
    // Event has already been deleted from the calendar.
    // Remove its reference from the core data store.
    TakeReadingCalendarEventMetaData *calEventMetaData = (TakeReadingCalendarEventMetaData *)[self.evIdToTakeReadingCDOMap objectForKey:key];
    
    NSAssert(calEventMetaData != nil, @"Metadata for calender event NOT found!");
    
    if (calEventMetaData != nil)
    {
        if (store != nil)
        {
            if (![store removeEvent:reminderEvent span:EKSpanThisEvent error:error])
            {
                dumpNSError(*error, @"Deleting reminderEvent for calendar store failed");
                
                *error = makeNSErrorFromResources(TakeReadingRemindersStoreErrorDomain,
                                                  TRSDeleteError,
                                                  @"DELETE_REMINDER_FROM_REMINDER_STORE_FAILURE_DESCRIPTION",
                                                  @"DELETE_EVENT_FROM_CALENDAR_STORE_FAILURE",
                                                  @"REMINDER_STORE_FAILURE_RECOVERY_SUGGESTION",
                                                  *error,
                                                  nil,
                                                  nil,
                                                  NoStringOverrides);
;
                
                return NO;
            }

            NSLog(@"deleteReminderEventAtIndex, removed calendar event WITH ID %@ from store.", key);
        }
        else
        {
            NSLog(@"deleteReminderEventAtIndex, store is nil, skipping store delete of calendar event with ID %@.", key);
        }
        
        [managedObjectContext_ deleteObject:calEventMetaData];
        
        if (![managedObjectContext_ save:error]) 
        {
            dumpNSError(*error, @"deleteReminderEventAtIndex, couldn't save delete of calendar metadata");
            
            *error = makeNSErrorFromResources(TakeReadingRemindersStoreErrorDomain,
                                              TRSDeleteError,
                                              @"DELETE_REMINDER_FROM_REMINDER_STORE_FAILURE_DESCRIPTION",
                                              @"DELETE_REMINDER_METADATA_FAILURE",
                                              @"REMINDER_STORE_FAILURE_RECOVERY_SUGGESTION",
                                              *error,
                                              nil,
                                              nil,
                                              NoStringOverrides);
;
            
            return NO;
        }  
        
        if (reloadAction_ != Data)
        {
            [self.events removeObject:reminderEvent];
            [self.evIdToTakeReadingCDOMap removeObjectForKey:key];
            
        }
    }
    
    return YES;
}

- (EKEvent *)reminderEventAtIndex:(NSUInteger)index
{
    [self processReloadAction];

    return [self.events objectAtIndex:index];
}

- (void)loadData
{
    // Initialize an event store object with the init method. Initilize the array for events.
    
    if (self.eventStore == nil)
    {
        self.eventStore = [[EKEventStore alloc] init];    
    }
    
    if (self.defaultCalendar == nil)
    {
        self.defaultCalendar = [self.eventStore defaultCalendarForNewEvents];
    }
    
    self.evIdToTakeReadingCDOMap = [NSMutableDictionary dictionary];
    
    NSFetchRequest *fr = self.fetchRequest;
    
    if (fr == nil)
    {
        NSLog(@"Fetch request is nil., Aborting");
        abort();
    }
    
    NSError * __autoreleasing error = nil;
    
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fr error:&error];
    
    if (error != nil)
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
        
    if (self.events == nil)
    {
        self.events = [NSMutableArray arrayWithCapacity:[fetchedObjects count]];
    }
    else
    {
        [self.events removeAllObjects];
    }
    
    NSMutableArray *eventCol = self.events;
    NSMutableDictionary *evIdToCDOMap = self.evIdToTakeReadingCDOMap;
    NSManagedObjectContext *moc = nil;
    
    for (id object in fetchedObjects) 
    {
        TakeReadingCalendarEventMetaData *takeReadingCalEventId = (TakeReadingCalendarEventMetaData *)object;
        
        EKEvent *event = [self.eventStore eventWithIdentifier:takeReadingCalEventId.eventIdentifier];
        
        if (event != nil)
        {
            [eventCol addObject:event];
            [evIdToCDOMap setObject:takeReadingCalEventId forKey:takeReadingCalEventId.eventIdentifier];
        }
        else
        {
            // The core data store is out of sync with the calendar. Update it.
            NSLog(@"Data store is out of sync with the calendary.  No event with id %@", takeReadingCalEventId.eventIdentifier);
            
            if (moc == nil)
            {
                moc = self.managedObjectContext;
            }
            
            [moc deleteObject:takeReadingCalEventId];
        }
    }
    
    if (moc != nil)
    {
        NSError * __autoreleasing error = nil;
        
        if (![managedObjectContext_ save:&error]) 
        {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            abort();
        }            
    }
    
    if (eventCol.count != 0)
    {
        [self sortData];
    }
    
    reloadAction_ = NoAction;
}

- (void)sortData
{
    if (self.events.count != 0)
    {
        // Sort the array.
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:YES];

        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];

        [self.events sortedArrayUsingDescriptors:sortDescriptors];
    }
    reloadAction_ = NoAction;
}

#pragma mark - processReloadAction

- (void)processReloadAction
{
    if (reloadAction_ == Data)
    {
        [self loadData];
    }
    else if (reloadAction_ == Sort)
    {
        [self sortData];
    }
}

#pragma mark - Count property implementation.

- (NSUInteger)count
{
    [self processReloadAction];
    
    if (self.events != nil)
    {
        return self.events.count;
    }
    
    return 0;
}

#pragma mark - Force Data Reload Property

- (void)setForceDataReload
{
    reloadAction_ = Data;
}

- (BOOL)forceDataReload
{
    return (reloadAction_ == Data) ? YES : NO;
}

#pragma mark - Fetched results controller

- (NSFetchRequest *)fetchRequest
{
    if (fetchRequest_ == nil)
    {
        NSFetchRequest *fetchRequest = [BPFetchRequestBuilderHelper makeFetchRequestForManagedObjectContext:managedObjectContext_
                                                                             entityName:@"TakeReadingCalendarEventMetaData"
                                                                              predicate:nil sectionNameKeyPath:nil 
                                                                            sortkeyName:nil 
                                                                          sortAscending:NO 
                                                                              cacheName:@"TakeReadingReminders" 
                                                                              batchSize:20];
        self.fetchRequest = fetchRequest;
    }
    
    return fetchRequest_;
}

- (NSFetchedResultsController *)fetchedResultsController 
{
    // Set up the fetched results controller if needed.
    if (fetchedResultsController_ == nil) 
	{
        NSFetchedResultsController *fetchedResultsCtrlr = 
        [[FetchedResultsControllerFactory instance]
         makeTakeReadingEventsFetchedResultsControllerWithManagedObjectContext:managedObjectContext_ 
         sectionNameKeyPath:nil 
         cacheName:@"TakeReadingReminders" 
         batchSize:20];
        
        if (fetchedResultsCtrlr != nil)
        {
            fetchedResultsCtrlr.delegate = nil;
            self.fetchedResultsController = fetchedResultsCtrlr;
        }
    }
	
	return fetchedResultsController_;
}    

#pragma mark - Memory Management


@end
