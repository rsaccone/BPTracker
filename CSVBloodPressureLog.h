//
//  CSVBloodPressureLog.h
//  BPTracker
//
//  Created by Robert Saccone on 12/2/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataLogBuilder.h"

@interface CSVBloodPressureLog : NSObject<DataLogBuilder>
{
    NSMutableString *contents_;
}

@property(nonatomic, readonly, strong) NSMutableString *contents;

// Designated initializer for this class.
- (id)init;

- (void)addReading:(BloodPressureReading *)bpReading;
- (NSString *)consumeContents;

@end
