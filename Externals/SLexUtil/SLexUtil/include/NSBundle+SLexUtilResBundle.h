//
//  NSBundle+SLexUtilResBundle.h
//  SLexUtil
//
//  Created by Robert Saccone on 6/7/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SLEXUTIL_LocalizedString(key) NSLocalizedStringFromTableInBundle((key), nil, [NSBundle slexUtilResourcesBundle], nil)

@interface NSBundle (SLexUtilResBundle)

+ (NSBundle*)slexUtilResourcesBundle;

@end
