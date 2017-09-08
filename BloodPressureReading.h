//
//  BloodPressureReading.h
//  BPTracker
//
//  Created by Robert Saccone on 11/25/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface BloodPressureReading : NSManagedObject

- (void)awakeFromFetch;
- (void)awakeFromInsert;

@property (nonatomic, strong) NSDate * readingDate;
@property (nonatomic, strong) NSNumber * pulse;
@property (nonatomic, strong) NSNumber * systolic;
@property (nonatomic, strong) NSNumber * weight;
@property (nonatomic, strong) NSNumber * diastolic;
@property (nonatomic, strong) NSString * note;
@property (nonatomic, strong) NSNumber * meanArterialPressure;
@property (nonatomic, strong) NSString *sectionId;

@end
