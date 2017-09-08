//
//  NSBundle+SLexUtilResBundle.m
//  SLexUtil
//
//  Created by Robert Saccone on 6/7/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "NSBundle+SLexUtilResBundle.h"

@implementation NSBundle (SLexUtilResBundle)

+ (NSBundle*)slexUtilResourcesBundle 
{
    static dispatch_once_t onceToken;
    static NSBundle *slexUtilResourcesBundle = nil;
    
    dispatch_once(&onceToken, ^{
        slexUtilResourcesBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"SLexUtilResources" withExtension:@"bundle"]];
    });
    
    return slexUtilResourcesBundle;
}

@end
