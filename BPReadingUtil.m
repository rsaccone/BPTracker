//
//  BPReadingUtil.m
//  BPTracker
//
//  Created by Robert Saccone on 10/10/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BPReadingUtil.h"

void copyReading(BloodPressureReading *src, BloodPressureReading *dest)
{
    NSCAssert(src != nil, @"src == nil");
    NSCAssert(dest != nil, @"dest == nil");
    
    dest.readingDate = src.readingDate;
    dest.systolic = src.systolic;
    dest.diastolic = src.diastolic;
    dest.pulse = src.pulse;
    dest.weight = src.weight;
    dest.note = src.note;
}
