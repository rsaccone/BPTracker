//
//  BloodPressureReading.m
//  BPTracker
//
//  Created by Robert Saccone on 11/25/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BloodPressureReading.h"
#import "BloodPressureDataAnalyzer.h"

@interface BloodPressureReading ()

- (NSString *)createSectionId:(NSDate *)readingDate;

@end

@interface BloodPressureReading (PrimitiveAccessors)

- (NSNumber *)primitiveSystolic;
- (void)setPrimitiveSystolic:(NSNumber *)newSystolic;

- (NSNumber *)primitiveDiastolic;
- (void)setPrimitiveDiastolic:(NSNumber *)newDiastolic;

- (NSDate *)primitiveReadingDate;
- (void)setPrimitiveReadingDate:(NSDate *)newReadingDate;

- (NSString *)primitiveSectionId;
- (void)setPrimitiveSectionId:(NSString *)newSectionId;

@end

@implementation BloodPressureReading

@dynamic readingDate;
@dynamic pulse;
@dynamic systolic;
@dynamic weight;
@dynamic diastolic;
@dynamic note;
@dynamic meanArterialPressure;
@dynamic sectionId;

static NSString *systolicKey                = @"systolic";
static NSString *diastolicKey               = @"diastolic";
static NSString *meanArterialPressureKey    = @"meanArterialPressure";
static NSString *sectionIdKey               = @"sectionId";
static NSString *readingDate                = @"readingDate";

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    
    double map = [[BloodPressureDataAnalyzer instance] meanArterialPressureFromBloodPressureReading:self];
    
    [super setPrimitiveValue:[NSNumber numberWithDouble:map] forKey:meanArterialPressureKey];
}

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    
    double map = [[BloodPressureDataAnalyzer instance] meanArterialPressureFromBloodPressureReading:self];
    
    [super setPrimitiveValue:[NSNumber numberWithDouble:map] forKey:meanArterialPressureKey];
}

- (void)setSystolic:(NSNumber *)newSystolic
{
    [self willChangeValueForKey:systolicKey];
    [self setPrimitiveSystolic:newSystolic];
    [self didChangeValueForKey:systolicKey];
    
    double map = [[BloodPressureDataAnalyzer instance] meanArterialPressureFromBloodPressureReading:self];
    
    self.meanArterialPressure = [NSNumber numberWithDouble:map];
}

- (void)setDiastolic:(NSNumber *)newDiastolic
{
    [self willChangeValueForKey:diastolicKey];
    [self setPrimitiveDiastolic:newDiastolic];
    [self didChangeValueForKey:diastolicKey];

    double map = [[BloodPressureDataAnalyzer instance] meanArterialPressureFromBloodPressureReading:self];
    
    self.meanArterialPressure = [NSNumber numberWithDouble:map];
}

- (void)setReadingDate:(NSDate *)newDate 
{
    
    // If the time stamp changes, the section identifier become invalid.
    [self willChangeValueForKey:readingDate];
    [self setPrimitiveReadingDate:newDate];
    [self didChangeValueForKey:readingDate];
    
    [self setSectionId:[self createSectionId:newDate]];
}

- (NSString *)sectionId
{
    
    // Create and cache the section identifier on demand.
    
    [self willAccessValueForKey:sectionIdKey];
    NSString *tmp = [self primitiveSectionId];
    [self didAccessValueForKey:sectionIdKey];

#if 0
    if (!tmp) 
    {
        /*
         Sections are organized by month and year. Create the section identifier as a string representing the number (year * 1000) + month; this way they will be correctly ordered chronologically regardless of the actual name of the month.
         */
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:[self readingDate]];
        tmp = [NSString stringWithFormat:@"%d", ([components year] * 1000) + [components month]];
        [self setPrimitiveSectionId:tmp];
    }
#endif
    
    return tmp;
}

- (NSString *)createSectionId:(NSDate *)readingDate;
{
    /*
     Sections are organized by month and year. Create the section identifier as a string representing the number (year * 1000) + month; this way they will be correctly ordered chronologically regardless of the actual name of the month.
     */
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:readingDate];
    
    return [NSString stringWithFormat:@"%ld", (long)(([components year] * 1000) + [components month])];
}

@end
