//
//  DataExportFactory.h
//  BPTracker
//
//  Created by Robert Saccone on 11/29/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataExporter.h"


enum DataExporterType
{
    CSV_Data_Exporter
};

@interface DataExporterFactory : NSObject

+ (DataExporterFactory *)instance;

- (id<DataExporter>)dataExporterForType:(enum DataExporterType)type filename:(NSString *)filename;
@end
