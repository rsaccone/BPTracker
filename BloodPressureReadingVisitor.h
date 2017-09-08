//
//  BloodPressureReadingVistor.h
//  BPTracker
//
//  Created by Robert Saccone on 11/29/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BloodPressureReading.h"

@protocol BloodPressureReadingVisitor <NSObject>

@required

- (void)visit:(BloodPressureReading *)bpReading;

@end
