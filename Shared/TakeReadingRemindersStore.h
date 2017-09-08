//
//  TakeReadingRemindersStore.h
//  BPTracker
//
//  Created by Robert Saccone on 2/24/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <EventKit/EKCalendar.h>
#import <EventKit/EKEvent.h>
#import <EventKit/EKEventStore.h>

extern NSString *const TakeReadingRemindersStoreErrorDomain;

enum TakeReadingRemindersStoreErrors
{
    TRSUnknownError = -1, 
    TRSDeleteError  = -2,
    TRSSaveError    = -3,
    TRSAddError     = -4
};

typedef enum StoreAccessRequestResult
{
    StoreAccessRequestPending,
    StoreAccessRequestGranted,
    StoreAccessRequestDenied,
    StoreAccessRequetError
} StoreAccessRequestResult;

typedef void (^StoreAccessRequestCompletionHandler)(StoreAccessRequestResult result, NSError *error);

@protocol TakeReadingRemindersStore <NSObject>

- (StoreAccessRequestResult)requestAccessToStore:(BOOL)forceReset completionHandler:(StoreAccessRequestCompletionHandler)completionHandler;

- (BOOL)saveReminderEvent:(EKEvent *)reminderEvent eventStore:(EKEventStore *)store 
          originalEventId:(NSString *)originalId error:(NSError * __autoreleasing *)error;

- (BOOL)addReminderEvent:(EKEvent *)reminderEvent eventStore:(EKEventStore *)store error:(NSError * __autoreleasing *)error;
- (BOOL)deleteReminderEvent:(EKEvent *)reminderEvent eventStore:(EKEventStore *)store error:(NSError * __autoreleasing *)error;
- (BOOL)deleteReminderEventAtIndex:(NSUInteger)index eventStore:(EKEventStore *)store error:(NSError * __autoreleasing *)error;


- (EKEvent *)reminderEventAtIndex:(NSUInteger)index;

@property(nonatomic, assign, readonly) BOOL shouldAttemptPermissionRequest;
@property(nonatomic, assign, readonly) NSUInteger count;
@property(nonatomic, retain) EKEventStore *eventStore;
@property(nonatomic, retain) EKCalendar *defaultCalendar;
@property(nonatomic, assign) BOOL forceDataReload;

@end
