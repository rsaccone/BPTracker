//
//  DataExporterImpl.m
//  BPTracker
//
//  Created by Robert Saccone on 12/1/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "CVSDataExporterImpl.h"

#import <SLexUtil/CHCSVWriter.h>

@interface CVSDataExporterImpl ()

- (void)addReadingToFile:(BloodPressureReading *)bpReading;
- (void) writeHeader;


@property(nonatomic, readwrite, strong) CHCSVWriter *csvWriter;
@property(nonatomic, readwrite, strong) NSFileHandle *fileHandle;
@property(nonatomic, readwrite, strong) id<DataLogBuilder> dataLogBuilder;
@property(nonatomic, readwrite, strong) NSDateFormatter *dateFormatter;

@end

@implementation CVSDataExporterImpl
{
@private
    id<DataLogBuilder> dataLogBuilder_;
    NSFileHandle *fileHandle_;
    CHCSVWriter *csvWriter_;
    NSDateFormatter *dateFormatter_;
}

@synthesize csvWriter = csvWriter_;
@synthesize fileHandle=fileHandle_;
@synthesize dataLogBuilder=dataLogBuilder_;
@synthesize dateFormatter=dateFormatter_;

static NSString *const columnHeaderKeys[] =
{
    @"CSV_DATE_FIELD_TITLE",
    @"CSV_TIME_FIELD_TITLE",
    @"CSV_SYSTOLIC_FIELD_TITLE",
    @"CSV_DIASTOLIC_FIELD_TITLE",
    @"CSV_PULSE_FIELD_TITLE",
    @"CSV_WEIGHT_FIELD_TITLE",
    @"CSV_NOTE_FIELD_TITLE",
    nil
};

// Designated initializer
- (id)initWithFilename:(NSString *)filename
{
    self = [super init];
    
    if (self != nil)
    {
        if (filename == nil)
        {
            ALog(@"DataExportImpl: nil filename passed to initWithFileName!");
            
            return nil;
        }
        
        csvWriter_ = [[CHCSVWriter alloc] initWithCSVFile:filename atomic:NO];
        
        if (csvWriter_ != nil)
        {
            [self writeHeader];
        }
        else
        {
            ALog(@"Couldn't alloc CHCSWriter.");
            return nil;
        }
        
        dateFormatter_ = [[NSDateFormatter alloc] init];
        
        if (dateFormatter_ != nil)
        {
            [dateFormatter_ setDateStyle:NSDateFormatterMediumStyle];
            [dateFormatter_ setTimeStyle:NSDateFormatterMediumStyle];
        }
        else
        {
            return nil;
        }
    }
    
    return self;
}

- (void) writeHeader
{
    for (NSString *const *currColHdrKey = columnHeaderKeys; *currColHdrKey != nil; ++currColHdrKey)
    {
        NSString *colHdrStr = NSLocalizedString(*currColHdrKey, nil);
        [self.csvWriter writeField:colHdrStr];
    }
    
    [self.csvWriter writeLine];
}

- (void)addReadingToFile:(BloodPressureReading *)bpReading
{
    [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    NSString *dateStr = [self.dateFormatter stringFromDate:bpReading.readingDate];
    
    [self.dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    NSString *timeStr = [self.dateFormatter stringFromDate:bpReading.readingDate];

    // Encapsulate the note field string in "" in case there are embedded ','.
    [self.csvWriter writeLineOfFields:dateStr,
                                      timeStr,
                                      bpReading.systolic,
                                      bpReading.diastolic,
                                      bpReading.pulse,
                                      bpReading.weight,
                                      bpReading.note,
                                      nil];
}

- (void)addReadings:(NSArray *)bpReadings updateProgress:(void (^)(float))progressBlock
{
    NSAssert(bpReadings != nil, @"DataExporterImpl: bpReadings is nil!");
    id<DataLogBuilder> dataLogBuilder = self.dataLogBuilder;
    
    if (progressBlock != nil)
    {
        NSUInteger itemCount = bpReadings.count;
        NSUInteger progressInterval = 10;
        
        NSUInteger itemsProcessed = 0;
        
        for (BloodPressureReading *bpReading in bpReadings)
        {
            [self addReadingToFile:bpReading];
            
            if ((++itemsProcessed % progressInterval) == 0)
            {
                progressBlock(((float)itemsProcessed) / (float)itemCount);
            }
        }
        
        progressBlock(1.0f);
    }
    else
    {
        for (BloodPressureReading *bpReading in bpReadings)
        {
            [dataLogBuilder addReading:bpReading];
        }
    }
    
    NSString *contents = [dataLogBuilder consumeContents];
    NSData *data = [contents dataUsingEncoding:NSUTF8StringEncoding];

    // TBD - writeData throws an exception when it fails.  Add handling here.
    [self.fileHandle writeData:data];
}

- (void)done
{
    [self.fileHandle closeFile];
}

@end
