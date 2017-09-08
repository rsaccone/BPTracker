//
//  BloodPressureReadingsFetchedResultsControllerFactory.h
//  BPTracker
//
//  Created by Robert Saccone on 12/18/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FetchedResultsControllerFactory : NSObject

+ (FetchedResultsControllerFactory *)instance;

- (NSFetchedResultsController *)makeFetchedResultsControllerWithManagedObjectContext:(NSManagedObjectContext *)managedObjContext 
                                                                          entityName:(NSString *)entityName 
                                                                           predicate:(NSPredicate *)predicate 
                                                                  sectionNameKeyPath:(NSString *)sectionNameKey 
                                                                         sortkeyName:(NSString *)sortkeyName 
                                                                       sortAscending:(BOOL)ascending 
                                                                           cacheName:(NSString *)name 
                                                                           batchSize:(NSUInteger) fetchBatchSize;

- (NSFetchedResultsController *)makeBPFetchedResultsControllerWithManagedObjectContext:(NSManagedObjectContext *)managedObjContext 
                                                                    sectionNameKeyPath:(NSString *)sectionNameKey
                                                                         sortAscending:(BOOL)ascending
                                                                             cacheName:(NSString *)name 
                                                                             batchSize:(NSUInteger)fetchBatchSize;

- (NSFetchedResultsController *)makeBPFetchedResultsControllerWithManagedObjectContext: (NSManagedObjectContext *)managedObjContext 
                                                                             startDate:(NSDate *)startDate 
                                                                               endDate:(NSDate *)endDate 
                                                                    sectionNameKeyPath:(NSString *)sectionNameKey
                                                                             cacheName:(NSString *)name
                                                                             batchSize:(NSUInteger) fetchBatchSize;

- (NSFetchedResultsController *)makeTakeReadingEventsFetchedResultsControllerWithManagedObjectContext:(NSManagedObjectContext *)managedObjContext
                                                                                   sectionNameKeyPath:(NSString *)sectionNameKey 
                                                                                            cacheName:(NSString *)name 
                                                                                            batchSize:(NSUInteger)fetchBatchSize;

@end
