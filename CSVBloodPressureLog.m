//
//  CSVBloodPressureLog.m
//  BPTracker
//
//  Created by Robert Saccone on 12/2/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "CSVBloodPressureLog.h"

static NSString *delimeter = @",";
static NSString *eol = @"\r\n";

@interface CSVBloodPressureLog ()

- (void)writeColumnValue:(NSString *)value;
- (void)writeDelimeter;
- (void)writeEOL;


@property(nonatomic, strong) NSCharacterSet *illegalChars;
@property(nonatomic, readwrite, strong) NSMutableString *contents;

@end

@implementation CSVBloodPressureLog
{
@private
    NSCharacterSet *illegalChars_;
}

@synthesize illegalChars = illegalChars_;
@synthesize contents=contents_;

static NSString *const columnHeaderKeys[] =
{
    @"CSV_DATE_FIELD_TITLE",
    @"CSV_SYSTOLIC_FIELD_TITLE",
    @"CSV_DIASTOLIC_FIELD_TITLE",
    @"CSV_PULSE_FIELD_TITLE",
    @"CSV_WEIGHT_FIELD_TITLE",
    @"CSV_NOTE_FIELD_TITLE",
    nil
};

static void writeHeader(NSMutableString *logContents)
{
    NSCAssert(logContents != nil, @"logContents == nil");
    
    NSString * const *currColHdrKey = columnHeaderKeys;
    
    while (*currColHdrKey != nil)
    {
        NSString * const *nextColHdrKey = currColHdrKey + 1;
        
        NSString *colHdrStr = NSLocalizedString(*currColHdrKey, nil);
        
        if (*nextColHdrKey != nil)
        {
            [logContents appendFormat:@"%@,", colHdrStr];
        }
        else
        {
            [logContents appendFormat:@"%@\r\n", colHdrStr];
        }
        
        currColHdrKey = nextColHdrKey;
    }
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        NSMutableString *contents = [[NSMutableString alloc] init];
        
        if (contents != nil)
        {
            NSMutableCharacterSet *bad = [NSMutableCharacterSet newlineCharacterSet];
            [bad addCharactersInString:@"\"\\"];
            [bad addCharactersInString:delimeter];
            illegalChars_ = [bad copy];
            
            writeHeader(contents);
            contents_ = contents;
        }
        else
        {
            // Failure to allocate.
            self = nil;
        }
    }
    
    return self;
}


- (void)writeColumnValue:(NSString *)value
{
	if ([value rangeOfCharacterFromSet:self.illegalChars].location != NSNotFound || [value hasPrefix:@"#"])
    {
        NSMutableString *writeable = [value mutableCopy];
        
		[writeable replaceOccurrencesOfString:@"\"" withString:@"\"\"" options:NSLiteralSearch range:NSMakeRange(0, [writeable length])];
        
		[writeable replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSLiteralSearch range:NSMakeRange(0, [writeable length])];
		[writeable insertString:@"\"" atIndex:0];
		[writeable appendString:@"\""];
        
        [self.contents appendString:writeable];
	}
    else
    {
        [self.contents appendString:value];
    }
}

- (void)writeDelimeter
{
    [self.contents appendString:delimeter];
}

- (void)writeEOL
{
    [self.contents appendString:eol];
}

- (void)addReading:(BloodPressureReading *)bpReading;
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    
    NSString *colValue = [dateFormatter stringFromDate:bpReading.readingDate];
    
    [self writeColumnValue:colValue];
    [self writeDelimeter];
    
    colValue = [NSString stringWithFormat:@"%hu", bpReading.systolic.shortValue];
    [self writeColumnValue:colValue];
    [self writeDelimeter];
    
    colValue = [NSString stringWithFormat:@"%hu", bpReading.diastolic.shortValue];
    [self writeColumnValue:colValue];
    [self writeDelimeter];
    
    colValue = [NSString stringWithFormat:@"%hu", bpReading.pulse.shortValue];
    [self writeColumnValue:colValue];
    [self writeDelimeter];
    
    colValue = [NSString stringWithFormat:@"%hu", bpReading.weight.shortValue];
    [self writeColumnValue:colValue];
    [self writeDelimeter];
    
    [self writeColumnValue:bpReading.note];
    [self writeEOL];
}

- (NSString *)consumeContents
{
    NSString * result = [[NSString alloc] initWithString:self.contents];

    [self.contents setString:@""];
    
    return result;
}

@end
