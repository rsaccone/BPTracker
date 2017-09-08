//
//  BPDataImporter.m
//  BPTracker
//
//  Created by Robert Saccone on 9/30/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BPDataImporterFactory.h"
#import "BPDataMergeImport.h"
#import "BPDataReplaceAllImport.h"

@implementation BPDataImporterFactory

static BPDataImporterFactory *theInstance = nil;

+ (BPDataImporterFactory *)instance
{
    if (theInstance == nil)
        theInstance = [[BPDataImporterFactory alloc] init];
    
    return theInstance;
}

- (id<BPDataImporter>)makeDataImporter:(NSManagedObjectContext *)moc
                 mergeImportedData:(BOOL)merge
                     batchSizeHint:(NSUInteger)batchHint
{
    if (merge)
    {
        return [[BPDataMergeImport alloc] initWithManagedObjectContext:moc batchSizeHint:batchHint];
    }
    
    return [[BPDataReplaceAllImport alloc] initWithManagedObjectContext:moc batchSizeHint:batchHint];
}

@end

