//
//  NSDate+NSDate_UtilityExtensions.h
//  SLexUtil
//
//  Created by Robert Saccone on 3/26/13.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (NSDate_UtilityExtensions)

+ (NSDate *)dateToNearestSecond;
+ (NSDate *)dropSeconds:(NSDate *)date;
+ (NSDate *)roundDate:(NSDate *)date toNearestIntervalInMinutes:(NSTimeInterval)intervalInMins;
+ (NSDate *)roundUpDate:(NSDate *)date toNearestIntervalInMinutes:(NSTimeInterval)intervalInMins;
+ (NSDate *)roundUpCurrentDateToNearestIntervalInMinutes:(NSInteger)intervalInMins;
+ (NSDateComponents *)deltaFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;
+ (NSString *)durationFromDateComponents:(NSDateComponents *)dateComponents;

@end
