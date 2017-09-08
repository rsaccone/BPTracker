//
//  BPDataReplaceAllImport.m
//  BPTracker
//
//  Created by Robert Saccone on 10/9/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BPDataReplaceAllImport.h"

#import <Foundation/NSBundle.h>
#import <SLexUtil/NSErrorHelper.h>
#import <SLexUtil/ViewHelper.h>
#import "BPDataImportError.h"
#import "BPFetchRequestBuilderHelper.h"
#import "BPReadingUtil.h"

@interface BPDataReplaceAllImport ()

- (void)deleteAllReadings;

@end

@implementation BPDataReplaceAllImport
{
@private
    BOOL dbCleared_;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                     batchSizeHint:(NSUInteger)batchHint
{
    self = [super initWithManagedObjectContext:moc batchSizeHint:batchHint];
    
    if (self != nil)
    {
        dbCleared_ = NO;
    }
    
    return self;
}

- (void)deleteAllReadings
{
    NSFetchRequest * allReadings = [[NSFetchRequest alloc] init];
    [allReadings setEntity:[NSEntityDescription entityForName:@"Car" inManagedObjectContext:self.managedObjectContext]];
    [allReadings setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * __autoreleasing error = nil;
    NSArray *readings = [self.managedObjectContext executeFetchRequest:allReadings error:&error];
    
    //error handling goes here
    for (NSManagedObject * reading in readings)
    {
        [self.managedObjectContext deleteObject:reading];
    }
}

- (void)beginImpl
{
    if (!dbCleared_)
    {
        [self deleteAllReadings];
        dbCleared_ = YES;
    }
    
    [self.dateToReading removeAllObjects];
    [self.importReadingDates removeAllObjects];
}

- (BOOL)importImpl:(BloodPressureReading *)reading error:(NSError* __autoreleasing *)error
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
        NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"IMPORT_READING_DUPLICATE_DATES_FAILURE_REASON", nil), [self.dateFormatter stringFromDate:reading.readingDate]];
        
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
    
    [self.dateToReading setObject:reading forKey:reading.readingDate];
    [self.importReadingDates addObject:reading.readingDate];
    
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
    NSArray *sortedDatesToMatch = [self.importReadingDates sortedArrayUsingSelector:@selector(compare:)];
    
    NSFetchRequest *fetchRequest = [BPFetchRequestBuilderHelper makeFetchRequest:self.managedObjectContext matchReadingDates:sortedDatesToMatch];
    
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
    
    if ([readingsMatchingDates count] > 0)
    {
        // Duplicate dates in source.
        *error = makeNSErrorFromResources(BPDataImportErrorDomain,
                                          BPIDuplicateReadingDetectionFailed,
                                          @"IMPORT_READINGS_FAILURE_DESCRIPTION",
                                          @"IMPORT_READINGS_DUPLICATE_DATES_DETECTED_REASON",
                                          @"IMPORT_READINGS_DUPLICATE_DATES_RECOVERY_SUGGESTION",
                                          nil,
                                          nil,
                                          nil,
                                          NoStringOverrides);
        
        return NO;
    }
    
    NSEnumerator *objEnumerator = [self.dateToReading objectEnumerator];
    BloodPressureReading *currReading;
    NSUInteger numReadingsImported = 0;
    
    while (currReading = [objEnumerator nextObject])
    {
        BloodPressureReading *destReading
        =[NSEntityDescription insertNewObjectForEntityForName:@"BloodPressureReading"
                                       inManagedObjectContext:self.managedObjectContext];
        
        copyReading(currReading, destReading);
        ++numReadingsImported;
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

    self.newReadingsImportedCount = numReadingsImported;
    [self.dateToReading removeAllObjects];
    [self.importReadingDates removeAllObjects];
    
    return YES;
}

- (void)rollbackImpl
{
    [self.managedObjectContext rollback];
    [self.dateToReading removeAllObjects];
    [self.importReadingDates removeAllObjects];
}

@end
