//
//  BPGraphOptions.m
//  BPTracker
//
//  Created by Robert Saccone on 9/5/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BPGraphSettings.h"

@implementation BPGraphSettings

@synthesize graphDateRangeStart;
@synthesize graphDateRangeEnd;
@synthesize systolicData;
@synthesize diasotlicData;
@synthesize pulseData;
@synthesize legend;

- (void)clearFields
{
    self.graphDateRangeStart = nil;
    self.graphDateRangeEnd = nil;
    self.systolicData = NO;
    self.diasotlicData = NO;
    self.pulseData = NO;
    self.legend = NO;
}

- (id)copyWithZone:(NSZone *)zone
{
    id newSettings = [[[self class] allocWithZone:zone] init];
    
    ((BPGraphSettings *)newSettings).graphDateRangeStart = self.graphDateRangeStart;
    ((BPGraphSettings *)newSettings).graphDateRangeEnd = self.graphDateRangeEnd;
    ((BPGraphSettings *)newSettings).systolicData = self.systolicData;
    ((BPGraphSettings *)newSettings).diasotlicData = self.diasotlicData;
    ((BPGraphSettings *)newSettings).pulseData = self.pulseData;
    ((BPGraphSettings *)newSettings).legend = self.legend;
    
    return newSettings;
}

@end
