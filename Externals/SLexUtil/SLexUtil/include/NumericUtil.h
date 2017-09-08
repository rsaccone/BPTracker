//
//  NumericUtil.h
//  BPTracker
//
//  Created by Robert Saccone on 3/29/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

#define COUNT_OF(a) (sizeof((a)) / sizeof((a)[0]))

typedef enum
{
    IntNumberType,
    ShortNumberType
} NSNumberType;

@interface NumericUtil : NSObject 

+ (BOOL)stringContainsUnsignedInteger:(NSString *)checkString;
+ (BOOL)numberContainsShort:(NSNumber *)number;
+ (BOOL)numberContainsInt:(NSNumber *)number;
+ (NSNumber *)convertStringToNSNumber:(NSString *)text;
+ (NSNumber *)convertStringToNSNumber:(NSString *)text expectedType:(NSNumberType)numType;

@end
