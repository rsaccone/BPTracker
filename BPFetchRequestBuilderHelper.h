//
//  BPFetchRequestBuilderHelper.h
//  BPTracker
//
//  Created by Robert Saccone on 7/12/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BPFetchRequestBuilderHelper : NSObject

+ (NSFetchRequest *)makeFetchRequestToRetrieveDateRangeLimits:(NSManagedObjectContext *)managedObjectContext;
+ (NSFetchRequest *)makeFetchRequest:(NSManagedObjectContext *)managedObjectContext matchReadingDates:(NSArray *)sortedReadingDates;

+ (NSFetchRequest *)makeFetchRequestForManagedObjectContext:(NSManagedObjectContext *)managedObjContext
                                                 entityName:(NSString *)entityName
                                                  predicate:(NSPredicate *)predicate
                                         sectionNameKeyPath:(NSString *)sectionNameKey
                                                sortkeyName:(NSString *)sortkeyName
                                              sortAscending:(BOOL)ascending
                                                  cacheName:(NSString *)name
                                                  batchSize:(NSUInteger)fetchBatchSize;

#if 0
+ (NSFetchRequest *)makeFetchRequest:(NSManagedObjectContext *)managedObjectContext findDate:(NSDate *)date;
+ (void)updateFetchRequest:(NSFetchRequest *)fetchRequest newFindDate:(NSDate *)date;
#endif

@end
