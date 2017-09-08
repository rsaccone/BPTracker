//
//  NumericUtil.m
//  BPTracker
//
//  Created by Robert Saccone on 3/29/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "NumericUtil.h"


@implementation NumericUtil

+ (BOOL)stringContainsUnsignedInteger:(NSString *)checkString
{
    NSCharacterSet *nonNumberSet = [[NSCharacterSet characterSetWithRange:NSMakeRange('0',10)] invertedSet];
    NSString *trimmed = [checkString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    BOOL isNumeric = trimmed.length > 0 && [trimmed rangeOfCharacterFromSet:nonNumberSet].location == NSNotFound;
    
    return isNumeric;
}

+ (NSNumber *)convertStringToNSNumber:(NSString *)text
{
    NSNumber *myNumber = nil;
    
    if (text != nil)
    {
        NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        myNumber = [formatter numberFromString:text];
    }
    
    return myNumber;
}

+ (BOOL)numberContainsShort:(NSNumber *)number
{
    if (number != nil)
    {
        int asInt = [number intValue];
        int asShort = [number shortValue];
        
        if (asInt == ((int)asShort))
        {
            double asDouble = [number doubleValue];
            
            if (asDouble == ((double)asShort))
            {
                return YES;
            }
        }
    }
    
    return NO;
}

+ (BOOL)numberContainsInt:(NSNumber *)number
{
    if (number != nil)
    {
        int asInt = [number intValue];
        long asLong = [number longValue];
        
        if (((long)asInt) == asLong)
        {
            double asDouble = [number doubleValue];
            
            if (asDouble == ((double)asInt))
            {
                return YES;
            }
        }
    }
    
    return NO;
}

+ (NSNumber *)convertStringToNSNumber:(NSString *)text expectedType:(NSNumberType)expectedType
{
    NSNumber *number = [self convertStringToNSNumber:text];
    
    if (number != nil)
    {
        switch (expectedType)
        {
            case IntNumberType:
                number = ([self numberContainsInt:number]) ? number : nil;
                break;
                
            case ShortNumberType:
                number = ([self numberContainsShort:number]) ? number : nil;
                break;
                
            default:
                // Unexpected type.
                number = nil;
                break;
        }
    }
    
    return number;
}

@end
