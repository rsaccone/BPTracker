//
//  BPGraphOptions.h
//  BPTracker
//
//  Created by Robert Saccone on 9/5/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BPGraphSettings : NSObject<NSCopying>

- (void)clearFields;

@property(nonatomic, strong) NSDate *graphDateRangeStart;
@property(nonatomic, strong) NSDate *graphDateRangeEnd;
@property(nonatomic, assign) BOOL    systolicData;
@property(nonatomic, assign) BOOL    diasotlicData;
@property(nonatomic, assign) BOOL    pulseData;
@property(nonatomic, assign) BOOL    legend;

@end
