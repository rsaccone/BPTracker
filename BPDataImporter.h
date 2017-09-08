//
//  BPDataImporter.h
//  BPTracker
//
//  Created by Robert Saccone on 9/30/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BloodPressureReading.h"

@protocol BPDataImporter<NSObject>

-(void)begin;
-(BOOL)import:(BloodPressureReading *)reading error:(NSError * __autoreleasing *)error;
-(BOOL)commit:(NSError * __autoreleasing *)error;
-(void)rollback;

@property(nonatomic, readonly, assign) NSUInteger newReadingsImportedCount;
@property(nonatomic, readonly, assign) NSUInteger readingsUpdatedCount;

@end
