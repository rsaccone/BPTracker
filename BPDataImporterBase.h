//
//  BPDataImporterBase.h
//  BPTracker
//
//  Created by Robert Saccone on 10/9/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BloodPressureReading.h"
#import "BPDataImporter.h"

@interface BPDataImporterBase : NSObject<BPDataImporter>

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                     batchSizeHint:(NSUInteger)batchHint;

- (BloodPressureReading *)findPressureReading:(BloodPressureReading *)match;

- (void)begin;
- (BOOL)import:(BloodPressureReading *)reading error:(NSError * __autoreleasing *)error;
- (BOOL)commit:(NSError * __autoreleasing *)error;
- (void)rollback;

- (void)beginImpl;
- (BOOL)importImpl:(BloodPressureReading *)reading error:(NSError * __autoreleasing *)error;
- (BOOL)commitImpl:(NSError * __autoreleasing *)error;
- (void)rollbackImpl;

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) NSMutableDictionary *dateToReading;
@property(nonatomic, strong) NSMutableArray *importReadingDates;
@property(nonatomic, strong) NSDateFormatter *dateFormatter;

@property(nonatomic, assign) NSUInteger newReadingsImportedCount;
@property(nonatomic, assign) NSUInteger readingsUpdatedCount;

@end
