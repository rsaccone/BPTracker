//
//  BPDataReplaceAllImport.h
//  BPTracker
//
//  Created by Robert Saccone on 10/9/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BPDataImporterBase.h"

@interface BPDataReplaceAllImport : BPDataImporterBase

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                     batchSizeHint:(NSUInteger)batchHint;

@end

