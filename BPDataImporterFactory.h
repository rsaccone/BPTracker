//
//  BPDataImporterFactory.h
//  BPTracker
//
//  Created by Robert Saccone on 10/9/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BPDataImporter.h"

@interface BPDataImporterFactory : NSObject

+ (BPDataImporterFactory *)instance;

- (id<BPDataImporter>)makeDataImporter:(NSManagedObjectContext *)moc mergeImportedData:(BOOL)merge batchSizeHint:(NSUInteger)batchHint;

@end

