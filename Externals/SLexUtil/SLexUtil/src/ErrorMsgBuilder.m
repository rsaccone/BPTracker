//
//  ErrorMsgBuilder.m
//  BPTracker
//
//  Created by Robert Saccone on 4/22/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "ErrorMsgBuilder.h"

#import "NSBundle+SLexUtilResBundle.h"

@implementation ErrorMsgBuilder

static void appendMessagePartToString(NSMutableString *str, NSString *msgPart)
{
    NSCAssert(str != nil, @"str == nil");
    NSCAssert(msgPart != nil, @"msgPart == nil");
    
    if (str.length != 0)
    {
        [str appendFormat:@"\n%@", msgPart];
    }
    else
    {
        [str appendFormat:@"%@", msgPart];
    }
}

+ (NSString *)build:(NSString *)message error:(NSError *)error;
{
    NSMutableString *nserrorMsg = nil;
    
    nserrorMsg = [[NSMutableString alloc] init];
    
    if (message != nil)
    {
        appendMessagePartToString(nserrorMsg, message);
    }
    
    if (error != nil)
    {
        NSString *msg;
        
        msg = [error localizedDescription];
        
        if (msg != nil)
        {
            appendMessagePartToString(nserrorMsg, msg);
        }

        // The failure reason should already be included in the description but if it
        // isn't then try to include the failure reason so there is some details to
        // display for the user.
        if (msg == nil)
        {
            msg = [error localizedFailureReason];
            
            if (msg != nil)
            {
                appendMessagePartToString(nserrorMsg, msg);
            }
        }
        
        msg = [error localizedRecoverySuggestion];
        
        if (msg != nil)
        {
            appendMessagePartToString(nserrorMsg, msg);
        }
    }
    
    return nserrorMsg;
}

@end
