//
//  BPFetchRequestBuilderHelper.m
//  BPTracker
//
//  Created by Robert Saccone on 7/12/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BPFetchRequestBuilderHelper.h"
#import "FetchedResultsControllerFactory.h"

@implementation BPFetchRequestBuilderHelper

static NSString * const readingDate = @"readingDate";
static NSString * const matchDatePred = @"readingDate == %@";
static NSString * const bpReadingEntity = @"BloodPressureReading";


+ (NSFetchRequest *)makeFetchRequestForManagedObjectContext:(NSManagedObjectContext *)managedObjContext
                                                 entityName:(NSString *)entityName
                                                  predicate:(NSPredicate *)predicate
                                         sectionNameKeyPath:(NSString *)sectionNameKey
                                                sortkeyName:(NSString *)sortkeyName
                                              sortAscending:(BOOL)ascending
                                                  cacheName:(NSString *)name
                                                  batchSize:(NSUInteger)fetchBatchSize

{
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjContext];
    [fetchRequest setEntity:entity];
    
    if (predicate != nil)
    {
        [fetchRequest setPredicate:predicate];
    }
    
    // Create the sort descriptors array.
    NSSortDescriptor *sectionNameSortDescriptor = nil;
    
    // Edit the sort key as appropriate.
    if (sortkeyName != nil)
    {
        
        if (sectionNameKey != nil)
        {
            sectionNameSortDescriptor = [[NSSortDescriptor alloc] initWithKey:sectionNameKey ascending:ascending];
        }
        
        
        NSArray *sortDescriptors = nil;
        NSSortDescriptor *sortKeyDescriptor = [[NSSortDescriptor alloc] initWithKey:sortkeyName ascending:ascending];
        
        if (sectionNameSortDescriptor != nil)
        {
            sortDescriptors = [[NSArray alloc] initWithObjects:sectionNameSortDescriptor, sortKeyDescriptor, nil];
        }
        else
        {
            sortDescriptors = [[NSArray alloc] initWithObjects:sortKeyDescriptor, nil];
        }
        
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setFetchBatchSize:fetchBatchSize];
        
    }
    
#if defined(BPTRACKER_LITE)
    
    [fetchRequest setFetchLimit:BPReadingFetchRequestLimit];
    
#endif
    
    return fetchRequest;
}

+ (NSFetchRequest *)makeFetchRequestToRetrieveDateRangeLimits:(NSManagedObjectContext *)managedObjectContext
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    if (request != nil)
    {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"BloodPressureReading" inManagedObjectContext:managedObjectContext];
        [request setEntity:entity];
        
        // Specify that the request should return dictionaries.
        [request setResultType:NSDictionaryResultType];
        
        // Create an expression for the key path.
        NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"readingDate"];
        
        // Create an expression to represent the minimum value at the key path 'readingDate'
        NSExpression *minExpression = [NSExpression expressionForFunction:@"min:" arguments:[NSArray arrayWithObject:keyPathExpression]];
        
        // Create an expression to represent the maximum value at the key path 'readingDate'
        NSExpression *maxExpression = [NSExpression expressionForFunction:@"max:" arguments:[NSArray arrayWithObject:keyPathExpression]];
        
        // Create an expression description using the minExpression and returning a date.
        NSExpressionDescription *minDateExpressionDescription = [[NSExpressionDescription alloc] init];
        
        // The name is the key that will be used in the dictionary for the return value.
        [minDateExpressionDescription setName:@"minDate"];
        [minDateExpressionDescription setExpression:minExpression];
        [minDateExpressionDescription setExpressionResultType:NSDateAttributeType];
        
        // Create an expression description using the minExpression and returning a date.
        NSExpressionDescription *maxDateExpressionDescription = [[NSExpressionDescription alloc] init];
        
        // The name is the key that will be used in the dictionary for the return value.
        [maxDateExpressionDescription setName:@"maxDate"];
        [maxDateExpressionDescription setExpression:maxExpression];
        [maxDateExpressionDescription setExpressionResultType:NSDateAttributeType];
        
        // Set the request's properties to fetch just the property represented by the expressions.
        [request setPropertiesToFetch:[NSArray arrayWithObjects:minDateExpressionDescription, maxDateExpressionDescription, nil]];
        
    }
    
    return request;
}

+ (NSFetchRequest *)makeFetchRequest:(NSManagedObjectContext *)managedObjectContext matchReadingDates:(NSArray *)sortedReadingDates
{
    // Create the fetch request to get all readings with matching dates.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"BloodPressureReading"
                                        inManagedObjectContext:managedObjectContext]];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(readingDate IN %@)", sortedReadingDates]];
    
    // make sure the results are sorted as well
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"readingDate" ascending:YES];
    
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    return fetchRequest;
}


#if 0
+ (NSFetchRequest *)makeFetchRequest:(NSManagedObjectContext *)managedObjectContext findDate:(NSDate *)date
{
    return [[FetchedResultsControllerFactory instance] makeFetchRequestForManagedObjectContext:managedObjectContext
                                                                                    entityName:bpReadingEntity
                                                                                     predicate:matchDatePred
                                                                            sectionNameKeyPath:nil
                                                                                   sortkeyName:readingDate
                                                                                 sortAscending:YES
                                                                                     cacheName:nil
                                                                                     batchSize:100];
}

+ (void)updateFetchRequest:(NSFetchRequest *)fetchRequest newFindDate:(NSDate *)date
{
}
#endif

@end
