//
//  BloodPressureReadingsFetchedResultsControllerFactory.m
//  BPTracker
//
//  Created by Robert Saccone on 12/18/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "FetchedResultsControllerFactory.h"
#import "BPFetchRequestBuilderHelper.h"

@interface FetchedResultsControllerFactory ()

- (NSFetchedResultsController *)makeBPFetchedResultsControllerWithManagedObjectContext:(NSManagedObjectContext *)managedObjContext
                                                                             predicate:(NSPredicate *)predicate
                                                                    sectionNameKeyPath:(NSString *)sectionNameKey
                                                                         sortAscending:(BOOL)ascending
                                                                             cacheName:(NSString *)name
                                                                             batchSize:(NSUInteger)fetchBatchSize;

@end

@implementation FetchedResultsControllerFactory 

static FetchedResultsControllerFactory *theInstance = nil;

+ (FetchedResultsControllerFactory *)instance
{
    if (theInstance == nil)
        theInstance = [[FetchedResultsControllerFactory alloc] init];
    
    return theInstance;
}

- (NSFetchedResultsController *)makeFetchedResultsControllerWithManagedObjectContext:(NSManagedObjectContext *)managedObjContext
                                                                          entityName:(NSString *)entityName
                                                                           predicate:(NSPredicate *)predicate
                                                                  sectionNameKeyPath:(NSString *)sectionNameKey
                                                                         sortkeyName:(NSString *)sortkeyName
                                                                       sortAscending:(BOOL)ascending
                                                                           cacheName:(NSString *)name
                                                                           batchSize:(NSUInteger) fetchBatchSize
{
    NSFetchedResultsController *aFetchedResultsController = nil;
    
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [BPFetchRequestBuilderHelper makeFetchRequestForManagedObjectContext:managedObjContext
                                                                                             entityName:entityName
                                                                                              predicate:predicate
                                                                                     sectionNameKeyPath:sectionNameKey
                                                                                            sortkeyName:sortkeyName
                                                                                          sortAscending:ascending
                                                                                              cacheName:name
                                                                                              batchSize:fetchBatchSize];
    
    if (fetchRequest != nil)
    {
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                         managedObjectContext:managedObjContext
                                                                           sectionNameKeyPath:sectionNameKey cacheName:name];
    }

    return aFetchedResultsController;
}


- (NSFetchedResultsController *)makeBPFetchedResultsControllerWithManagedObjectContext:(NSManagedObjectContext *)managedObjContext
                                                                             predicate:(NSPredicate *)predicate
                                                                    sectionNameKeyPath:(NSString *)sectionNameKey
                                                                         sortAscending:(BOOL)ascending
                                                                             cacheName:(NSString *)name
                                                                             batchSize:(NSUInteger)fetchBatchSize
{
    return [self makeFetchedResultsControllerWithManagedObjectContext:managedObjContext
                                                           entityName:@"BloodPressureReading"
                                                            predicate:predicate
                                                   sectionNameKeyPath:sectionNameKey
                                                          sortkeyName:@"readingDate"
                                                        sortAscending:ascending
                                                            cacheName:name
                                                            batchSize:fetchBatchSize];
}

- (NSFetchedResultsController *)makeBPFetchedResultsControllerWithManagedObjectContext:(NSManagedObjectContext *)managedObjContext
                                                                             startDate:(NSDate *)startDate
                                                                               endDate:(NSDate *)endDate
                                                                    sectionNameKeyPath:(NSString *)sectionNameKey
                                                                             cacheName:(NSString *)name
                                                                             batchSize:(NSUInteger) fetchBatchSize
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(readingDate >= %@) AND (readingDate <= %@)", startDate, endDate];
    
    return [self makeBPFetchedResultsControllerWithManagedObjectContext:managedObjContext
                                                              predicate:predicate
                                                     sectionNameKeyPath:sectionNameKey
                                                          sortAscending:YES
                                                              cacheName:name
                                                              batchSize:fetchBatchSize];
}


- (NSFetchedResultsController *)makeBPFetchedResultsControllerWithManagedObjectContext:(NSManagedObjectContext *)managedObjContext
                                                                    sectionNameKeyPath:(NSString *)sectionNameKey
                                                                         sortAscending:(BOOL)ascending
                                                                             cacheName:(NSString *)name
                                                                             batchSize:(NSUInteger)fetchBatchSize
{
    return [self makeBPFetchedResultsControllerWithManagedObjectContext:managedObjContext
                                                              predicate:nil
                                                     sectionNameKeyPath:sectionNameKey
                                                          sortAscending:ascending
                                                              cacheName:name
                                                              batchSize:fetchBatchSize];
}

- (NSFetchedResultsController *)makeTakeReadingEventsFetchedResultsControllerWithManagedObjectContext: (NSManagedObjectContext *)managedObjContext sectionNameKeyPath:(NSString *)sectionNameKey cacheName:(NSString *)name batchSize:(NSUInteger)fetchBatchSize
{
    return [self makeFetchedResultsControllerWithManagedObjectContext:managedObjContext
                                                           entityName:@"TakeReadingCalendarEventMetaData"
                                                            predicate:nil sectionNameKeyPath:nil
                                                          sortkeyName:nil
                                                        sortAscending:YES
                                                            cacheName:name
                                                            batchSize:fetchBatchSize];
}


@end
