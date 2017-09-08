//
//  DataExporterImpl.h
//  BPTracker
//
//  Created by Robert Saccone on 12/1/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DataExporter.h"
#import "DataLogBuilder.h"
#import "BloodPressureReading.h"
#import "BloodPressureReadingVisitor.h"

@interface CVSDataExporterImpl : NSObject<DataExporter>

// Designated initializer
- (id)initWithFilename:(NSString *)filename;
- (void)addReadings:(NSArray *)bpReadings updateProgress:(void (^)(float))block;
- (void)done;

@end
