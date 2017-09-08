//
//  NSErrorHelper.h
//  BPTracker
//
//  Created by Robert Saccone on 3/19/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum String_Resource_Overrides
{
    NoStringOverrides           = 0x00000000,
    DescIsAString               = 0x00000001,
    FailureReasonIsAString      = 0x00000002,
    RecoverySuggestionIsAString = 0x00000004
} StringResourceOverrides;

extern void dumpNSError(NSError *error, NSString *msg);

extern NSError *makeNSError(NSString *domain,
                            NSInteger code,
                            NSString *localizedDescription,
                            NSString *localizedFailureReason,
                            NSString *localizedRecoverySuggestion,
                            NSError  *underlyingError);

extern NSError *makeNSErrorFromResources(NSString *domain,
                                         NSInteger code,
                                         NSString *descriptionFormatId,
                                         NSString *failureReasonId,
                                         NSString *recoverySuggestionId,
                                         NSError *underlyingError,
                                         NSString *tableName,
                                         NSBundle *bundle,
                                         StringResourceOverrides overrideFlags);
