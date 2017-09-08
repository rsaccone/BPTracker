//
//  NSDate+NSDate_UtilityExtensions.m
//  SLexUtil
//
//  Created by Robert Saccone on 3/26/13.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "NSDate+UtilityExtensions.h"
#import "NSBundle+SLexUtilResBundle.h"

@interface NSDate (UtilityExtensions)

+ (NSDate *)roundDate:(NSDate *)dateToRound toNearestIntervalInMinutes:(NSInteger)intervalInMins roundUp:(BOOL)roundUp;

@end

@implementation NSDate (UtilityExtensions)

+ (NSDate *)dateToNearestSecond
{
    NSDate *date = [NSDate date];
    
    NSTimeInterval timeInterval = [date timeIntervalSinceReferenceDate];
    
    timeInterval += 0.5;
    
    timeInterval = floor(timeInterval);
    
    return [NSDate dateWithTimeIntervalSinceReferenceDate:timeInterval];
}

+ (NSDate *)dropSeconds:(NSDate *)date
{
    long timeInterval = (long)[date timeIntervalSinceReferenceDate];
    timeInterval /= 60;
    return [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)timeInterval * 60];
}

+ (NSDate *)roundDate:(NSDate *)dateToRound toNearestIntervalInMinutes:(NSInteger)intervalInMins roundUp:(BOOL)roundUp
{
    // if the interval is 1 minute then round to the nearest minute so
    if (intervalInMins == 1)
    {
        long timeInterval = (long)[dateToRound timeIntervalSinceReferenceDate];

        if ((timeInterval % 60) != 0)
        {
            // Rounding up add 59 seconds to cross the next minute boundary otherwise use 30 so
            // values below 30 seconds will stay in the current minute.
            timeInterval += (roundUp) ?  59 : 30;
            dateToRound = [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)timeInterval];
        }
    }
    
    // Create a NSDate object and a NSDateComponets object for us to use
    NSDateComponents *dateComponents =
    [[NSCalendar currentCalendar] components:NSMinuteCalendarUnit | NSSecondCalendarUnit
                                    fromDate:dateToRound];
    
    // Extract the number of minutes and find the remainder when divided the time interval
    // gives us the remainder when divided by interval (for example, for interval of 5,
    // 25 would be 0, but 23 would give a remainder of 3
    NSInteger remainder = [dateComponents minute] % intervalInMins;
    NSInteger halfInterval = intervalInMins / 2;
    
    // Round to the nearest 5 minutes (ignoring seconds)
    if ((((halfInterval > 0) && remainder >= halfInterval)) || (roundUp && (remainder != 0)))
    {
        // Add the difference
        dateToRound = [dateToRound dateByAddingTimeInterval:((intervalInMins - remainder) * 60)];
    }
    else if ((remainder > 0) && (remainder < halfInterval))
    {
        // Subtract the difference
        dateToRound = [dateToRound dateByAddingTimeInterval:(remainder * -60)];
    }
    
    // Subtract the number of seconds
    return [dateToRound dateByAddingTimeInterval:(-1 * [dateComponents second])];
}

+ (NSDate *)roundDate:(NSDate *)date toNearestIntervalInMinutes:(NSTimeInterval)intervalInMins
{
    return [NSDate roundDate:date toNearestIntervalInMinutes:intervalInMins roundUp:NO];
}

+ (NSDate *)roundUpDate:(NSDate *)date toNearestIntervalInMinutes:(NSTimeInterval)intervalInMins
{
    return [NSDate roundDate:date toNearestIntervalInMinutes:intervalInMins roundUp:YES];
}

+ (NSDate *)roundUpCurrentDateToNearestIntervalInMinutes:(NSInteger)intervalInMins
{
    return [NSDate roundUpDate:[NSDate date] toNearestIntervalInMinutes:intervalInMins];
}

+ (NSDateComponents *)deltaFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    NSLog(@"Delta from date called!");
    
    // Get the system calendar
    NSCalendar *sysCalendar = [NSCalendar currentCalendar];
    
    // Get conversion to months, days, hours, minutes
    unsigned int unitFlags = NSSecondCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit;
    
    NSDateComponents *breakdownInfo = [sysCalendar components:unitFlags fromDate:fromDate  toDate:toDate  options:0];
    
    return breakdownInfo;
}

+ (NSString *)durationFromDateComponents:(NSDateComponents *)dateComponents
{
    unsigned int unitFlags = 0;
    
    unitFlags |= (dateComponents.month > 0) ? NSMonthCalendarUnit : 0;
    unitFlags |= (dateComponents.day > 0) ? NSDayCalendarUnit : 0;
    unitFlags |= (dateComponents.hour > 0) ? NSHourCalendarUnit : 0;
    unitFlags |= (dateComponents.minute > 0) ? NSMinuteCalendarUnit : 0;
    unitFlags |= (dateComponents.second > 0) ? NSSecondCalendarUnit : 0;
    
    if (unitFlags & NSMonthCalendarUnit)
    {
        if (unitFlags & ~NSMonthCalendarUnit)
        {
            return [NSString stringWithFormat:SLEXUTIL_LocalizedString(@"DURATION_MONTHS_DAYS_HOURS_MINUTES_SECONDS"),
                    dateComponents.month,
                    dateComponents.day,
                    dateComponents.hour,
                    dateComponents.minute,
                    dateComponents.second];
        }
        
        return [NSString stringWithFormat:SLEXUTIL_LocalizedString(@"DURATION_MONTHS"),
                dateComponents.month];
    }
    
    if (unitFlags & NSDayCalendarUnit)
    {
        if (unitFlags & ~NSDayCalendarUnit)
        {
            return [NSString stringWithFormat:SLEXUTIL_LocalizedString(@"DURATION_DAYS_HOURS_MINUTES_SECONDS"),
                    dateComponents.day,
                    dateComponents.hour,
                    dateComponents.minute,
                    dateComponents.second];
        }
        
        return [NSString stringWithFormat:SLEXUTIL_LocalizedString(@"DURATION_DAYS"),
                dateComponents.day];
    }
    
    if (unitFlags & NSHourCalendarUnit)
    {
        if (unitFlags & ~NSHourCalendarUnit)
        {
            return [NSString stringWithFormat:SLEXUTIL_LocalizedString(@"DURATION_HOURS_MINUTES_SECONDS"),
                    dateComponents.hour,
                    dateComponents.minute,
                    dateComponents.second];
        }
        
        return [NSString stringWithFormat:SLEXUTIL_LocalizedString(@"DURATION_HOURS"),
                dateComponents.hour];
    }
    
    if (unitFlags & ~NSMinuteCalendarUnit)
    {
        return [NSString stringWithFormat:SLEXUTIL_LocalizedString(@"DURATION_MINUTES_SECONDS"),
                dateComponents.minute,
                dateComponents.second];
    }
    
    return [NSString stringWithFormat:SLEXUTIL_LocalizedString(@"DURATION_MINUTES"),
            dateComponents.minute];
}

@end
