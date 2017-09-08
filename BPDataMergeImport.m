//
//  BPDataMergeImport.m
//  BPTracker
//
//  Created by Robert Saccone on 10/9/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BPDataMergeImport.h"

#import <SLexUtil/NSErrorHelper.h>
#import "BPDataImportError.h"
#import "BPReadingUtil.h"
#import "BPFetchRequestBuilderHelper.h"

@implementation BPDataMergeImport

#pragma mark - BPDataImportBase contract implementation

- (void)beginImpl
{
    [self.dateToReading removeAllObjects];
    [self.importReadingDates removeAllObjects];
}

- (BOOL)importImpl:(BloodPressureReading *)reading error:(NSError *  __autoreleasing *)error
{
    if (reading == nil)
    {
        NSException* myException = [NSException
                                    exceptionWithName:NSInvalidArgumentException
                                    reason:@"reading is nil!"
                                    userInfo:nil];
        @throw myException;
    }
    
    if (error == nil)
    {
        NSException* myException = [NSException
                                    exceptionWithName:NSInvalidArgumentException
                                    reason:@"error is nil!"
                                    userInfo:nil];
        @throw myException;
    }
    
    // Make sure that a reading with this date/time hasn't already been imported.
    BloodPressureReading *dupe = [self.dateToReading objectForKey:reading.readingDate];
    
    if (dupe != nil)
    {
        NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"IMPORT_READING_DUPLICATE_DATES_FAILURE_REASON", nil),
                            [self.dateFormatter stringFromDate:reading.readingDate]];
        
        *error = makeNSErrorFromResources(BPDataImportErrorDomain,
                                          BPIDuplicateReadingDateInSource,
                                          @"IMPORT_READINGS_FAILURE_DESCRIPTION",
                                          reason,
                                          @"IMPORT_READING_DUPLICATE_DATES_RECOVERY_SUGGESTION",
                                          *error,
                                          nil,
                                          nil,
                                          FailureReasonIsAString);
        
        // Extend the method to return an NSError with information for the user
        // describing that a reading with the same date/time already exists.
        return NO;
    }
    
    NSDate *readingDate = reading.readingDate;
    
    [self.dateToReading setObject:reading forKey:readingDate];
    [self.importReadingDates addObject:readingDate];
    
    return YES;
}

- (BOOL)commitImpl:(NSError * __autoreleasing *)error
{
    if (error == nil)
    {
        NSException* myException = [NSException
                                    exceptionWithName:NSInvalidArgumentException
                                    reason:@"error is nil!"
                                    userInfo:nil];
        @throw myException;
    }
    
    NSError *internalError = nil;
    
    // Sort the reading dates.
    NSArray *sortedReadingDates = [self.importReadingDates sortedArrayUsingSelector:@selector(compare:)];
    
    // Create the fetch request to get all readings with matching dates.
    NSFetchRequest *fetchRequest = [BPFetchRequestBuilderHelper makeFetchRequest:self.managedObjectContext matchReadingDates:sortedReadingDates];
    
    NSArray *readingsMatchingDates = [self.managedObjectContext executeFetchRequest:fetchRequest
                                                                              error:&internalError];
    
    if (!readingsMatchingDates)
    {
        *error = makeNSErrorFromResources(BPDataImportErrorDomain,
                                          BPIDuplicateReadingDetectionFailed,
                                          @"IMPORT_READINGS_FAILURE_DESCRIPTION",
                                          @"IMPORT_READINGS_DUPLICATE_DATE_DETECTION_FAILURE_REASON",
                                          @"IMPORT_READINGS_RESTART_APPLICATION_RECOVERY_SUGGESTION",
                                          internalError,
                                          nil,
                                          nil,
                                          NoStringOverrides);
        
        return NO;
    }

    
    NSUInteger numReadingsFetched = [readingsMatchingDates count];
    NSUInteger currFetchedReadingIndex = 0;
    NSUInteger newReadingsImportedCount = 0;
    NSUInteger readingsUpdatedCount = 0;

    /* For debugging.
    for (BloodPressureReading *bpFetched in readingsMatchingDates)
    {
        NSLog(@"reading index %u = %@, systolic = %@, diastolic = %@, pulse = %@", currFetchedReadingIndex,
                                                                       bpFetched.readingDate,
              bpFetched.systolic, bpFetched.diastolic, bpFetched.pulse);
        
        ++currFetchedReadingIndex;
    }
    */
    
    currFetchedReadingIndex = 0;
    
    for (NSDate *currImportDate in sortedReadingDates)
    {
        BloodPressureReading *currImportReading = [self.dateToReading objectForKey:currImportDate];
        
        NSAssert(currImportReading != nil, @"currImportReading == nil");
        
        if (currFetchedReadingIndex < numReadingsFetched)
        {
            BloodPressureReading *currFetchedReading = [readingsMatchingDates objectAtIndex:currFetchedReadingIndex];
            
            if ([currFetchedReading.readingDate compare:currImportDate] == NSOrderedSame)
            {
                copyReading(currImportReading, currFetchedReading);
                
                ++currFetchedReadingIndex;
                ++readingsUpdatedCount;
                
                continue;
            }
        }
        
        // Reaching here means that a new BloodPressureReading should be created
        // because the current import date wasn't found in the fetched results set.
        BloodPressureReading *newReading
        =[NSEntityDescription insertNewObjectForEntityForName:@"BloodPressureReading"
                                       inManagedObjectContext:self.managedObjectContext];
        
        copyReading(currImportReading, newReading);
        
        ++newReadingsImportedCount;
    }
    
    if (![self.managedObjectContext save:&internalError])
    {
        *error = makeNSErrorFromResources(BPDataImportErrorDomain,
                                          BPIDuplicateReadingDetectionFailed,
                                          @"IMPORT_READINGS_FAILURE_DESCRIPTION",
                                          @"IMPORT_READINGS_SAVE_READINGS_FAILURE_REASON",
                                          @"IMPORT_READINGS_RESTART_APPLICATION_RECOVERY_SUGGESTION",
                                          internalError,
                                          nil,
                                          nil,
                                          NoStringOverrides);
        
        return NO;
    }
    
    [self.importReadingDates removeAllObjects];
    [self.dateToReading removeAllObjects];
    self.newReadingsImportedCount = newReadingsImportedCount;
    self.readingsUpdatedCount = readingsUpdatedCount;
    
    return YES;
}

- (void)rollbackImpl
{
    [self.importReadingDates removeAllObjects];
    [self.dateToReading removeAllObjects];
    [self.managedObjectContext rollback];
}

@end
