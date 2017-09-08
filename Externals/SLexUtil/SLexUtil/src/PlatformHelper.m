//
//  PlatformHelper.m
//  BPTracker
//
//  Created by Robert Saccone on 2/21/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "PlatformHelper.h"

#import <UIKit/UIDevice.h>

extern BOOL runningOniPad();
extern BOOL runningOniPhone();

@implementation PlatformHelper

+ (BOOL) oniPad
{
    return runningOniPad();
}

+ (BOOL) oniPhone
{
    return runningOniPhone();
}

+ (NSString *) addSuffixToResourceName:(NSString *)resourceName
{
    NSString *suffix;
    
    if ([PlatformHelper oniPad])
    {
        suffix = @"_iPad";
    }
    else
    {
        suffix = @"_iPhone";
    }
    
    return [resourceName stringByAppendingString:suffix];
}

@end
