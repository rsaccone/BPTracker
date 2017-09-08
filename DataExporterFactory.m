//
//  DataExportFactory.m
//  BPTracker
//
//  Created by Robert Saccone on 11/29/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "DataExporterFactory.h"

#import "CVSDataExporterImpl.h"

@implementation DataExporterFactory

static DataExporterFactory *theInstance = nil;

+ (DataExporterFactory *)instance
{
    if (theInstance == nil)
        theInstance = [[DataExporterFactory alloc] init];
    
    return theInstance;
}

- (id<DataExporter>)dataExporterForType:(enum DataExporterType)type filename:(NSString *)filename;
{
    id<DataExporter> dataExporter = nil;
    
    switch (type)
    {
        case CSV_Data_Exporter:
            dataExporter = [[CVSDataExporterImpl alloc] initWithFilename:filename];
            break;
            
        default: // unknown type.
        	NSLog(@"DataExporterFactory: unknown type <%d> passed to init.", type);
            break;
    }
    
    return dataExporter;
}

@end
