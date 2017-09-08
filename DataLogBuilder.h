//
//  DataLogBuilder.h
//  BPTracker
//
//  Created by Robert Saccone on 12/2/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BloodPressureReading.h"

@protocol DataLogBuilder <NSObject>

- (void)addReading:(BloodPressureReading *)bpReading;
- (NSString *)consumeContents;


@end
