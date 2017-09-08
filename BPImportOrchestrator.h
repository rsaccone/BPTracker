//
//  BPImportOrchestrator.h
//  BPTracker
//
//  Created by Robert Saccone on 12/27/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BPImportOrchestrator;

@protocol BPImportOrchestratorDelegate <NSObject>

- (void)importOrchestrator:(BPImportOrchestrator *)importOrch numRecordsImported:(NSUInteger)importCount numRecordsUpdated:(NSUInteger)updateCount;

- (void)importOrchestrator:(BPImportOrchestrator *)importOrch failedWithError:(NSError *)error totalRecordsImported:(NSUInteger)recordsImported totalRecordsUpdated:(NSUInteger)recordsUpdated;

- (void)importOrchestrator:(BPImportOrchestrator *)importOrch totalRecordsImported:(NSUInteger)recordsImported totalRecordsUpdated:(NSUInteger)recordsUpdated wasCanceled:(BOOL)canceled;

@end

@interface BPImportOrchestrator : NSObject

- (id)initWithCSVFile:(NSString *)filename parentManagedObjectContext:(NSManagedObjectContext *) parentManagedObjectContext notificationDelegate:(id<BPImportOrchestratorDelegate>)delegate error:(NSError **)anError;

- (void)beginImport;
- (void)cancelImportRequest;

@property(atomic, assign, readonly) NSUInteger numRecordsImported;
@property(atomic, assign, readonly) NSUInteger numRecordsUpdated;

@end
