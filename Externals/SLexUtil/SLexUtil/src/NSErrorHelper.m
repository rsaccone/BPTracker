//
//  NSErrorHelper.h
//  BPTracker
//
//  Created by Robert Saccone on 3/19/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "NSErrorHelper.h"

#import <CoreData/CoreData.h>

void dumpNSError(NSError *error, NSString *msg) 
{
    // If Cocoa generated the error...
    if ([[error domain] isEqualToString:NSCocoaErrorDomain]) 
    {
        if (msg  && ([msg length] != 0))
        {
            NSLog(@"%@", msg);
        }
        
        // ...check whether there's an NSDetailedErrors array            
        NSDictionary *userInfo = [error userInfo];
        if ([userInfo valueForKey:NSDetailedErrorsKey] != nil) 
        {
            // ...and loop through the array, if so.
            NSArray *errors = [userInfo valueForKey:NSDetailedErrorsKey];
            for (NSError *anError in errors) 
            {
                
                NSDictionary *subUserInfo = [anError userInfo];
                subUserInfo = [anError userInfo];
                // Granted, this indents the NSValidation keys rather a lot
                // ...but it's a small loss to keep the code more readable.
                NSLog(@"Core Data Save Error\n\n \
                      %@\n%@\n\n \
                      %@\n%@\n\n \
                      %@\n%@\n\n \
                      %@\n%@",
                      NSValidationKeyErrorKey,
                      [subUserInfo valueForKey:NSValidationKeyErrorKey],
                      NSValidationPredicateErrorKey,
                      [subUserInfo valueForKey:NSValidationPredicateErrorKey],
                      NSValidationObjectErrorKey,
                      [subUserInfo valueForKey:NSValidationObjectErrorKey], 
                      NSLocalizedDescriptionKey,
                      [subUserInfo valueForKey:NSLocalizedDescriptionKey]);
            }
        }
        else 
        {
            // If there was no NSDetailedErrors array, print values directly
            // from the top-level userInfo object. (Hint: all of these keys
            // will have null values when you've got multiple errors sitting
            // behind the NSDetailedErrors key.
            
            NSLog(@"Core Data Save Error\n\n \
                  %@\n%@\n\n \
                  %@\n%@\n\n \
                  %@\n%@\n\n \
                  %@\n%@",
                  NSValidationKeyErrorKey,
                  [userInfo valueForKey:NSValidationKeyErrorKey],
                  NSValidationPredicateErrorKey,
                  [userInfo valueForKey:NSValidationPredicateErrorKey],
                  NSValidationObjectErrorKey,
                  [userInfo valueForKey:NSValidationObjectErrorKey], 
                  NSLocalizedDescriptionKey,
                  [userInfo valueForKey:NSLocalizedDescriptionKey]);
        }
    } 
    // Handle mine--or 3rd party-generated--errors
    else 
    {
        if (!msg  || ([msg length] == 0))
        {
            msg = @"Custom Error:";
        }
        
        NSLog(@"%@ %@", msg, [error localizedDescription]);
    }
}

NSError *makeNSError(NSString *domain,
                     NSInteger code,
                     NSString *localizedDescription,
                     NSString *localizedFailureReason,
                     NSString *localizedRecoverySuggestion,
                     NSError  *underlyingError)
{
    NSCAssert(domain != nil, @"domain is nil");
    
    NSMutableDictionary *userInfo = nil;
    
    if (localizedDescription || localizedFailureReason || localizedRecoverySuggestion || underlyingError)
    {
      userInfo = [NSMutableDictionary dictionaryWithCapacity:4];
    }

    if (localizedDescription)
    {
        [userInfo setValue:localizedDescription forKey:NSLocalizedDescriptionKey];
    }
    
    if (localizedFailureReason)
    {
        [userInfo setValue:localizedFailureReason forKey:NSLocalizedFailureReasonErrorKey];
    }
    
    if (localizedRecoverySuggestion)
    {
        [userInfo setValue:localizedRecoverySuggestion forKey:NSLocalizedRecoverySuggestionErrorKey];
    }
    
    if (underlyingError)
    {
        [userInfo setValue:underlyingError forKey:NSUnderlyingErrorKey];
    }
    
    return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

NSError *makeNSErrorFromResources(NSString *domain,
                                  NSInteger code,
                                  NSString *descriptionFormatId,
                                  NSString *failureReasonId,
                                  NSString *recoverySuggestionId,
                                  NSError *underlyingError,
                                  NSString *tableName,
                                  NSBundle *bundle,
                                  StringResourceOverrides overrideFlags)

{
    NSCAssert(domain != nil, @"domain == nil");
    
    if (bundle == nil)
    {
        bundle = [NSBundle mainBundle];
    }

    NSString *failureReason = failureReasonId;
    
    if ((failureReasonId != nil) && !(overrideFlags & FailureReasonIsAString))
    {
        failureReason = [bundle localizedStringForKey:failureReasonId 
                                                value:nil 
                                                table:tableName];
    }
    
    NSString *description = descriptionFormatId;
    
    if ((descriptionFormatId != nil) && !(overrideFlags & DescIsAString))
    {
        NSString *descriptionFormat = [bundle localizedStringForKey:descriptionFormatId 
                                                              value:nil 
                                                              table:tableName];
        
        description = [NSString stringWithFormat:descriptionFormat, failureReason];
    }
    
    NSString *recoverySuggestion = recoverySuggestionId;
    
    if ((recoverySuggestionId != nil) && !(overrideFlags & RecoverySuggestionIsAString))
    {
        recoverySuggestion = [bundle localizedStringForKey:recoverySuggestionId 
                                                     value:nil 
                                                     table:tableName];
    }
    
    return makeNSError(domain, code, description, failureReason, recoverySuggestion, underlyingError);
}

