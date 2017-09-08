//
//  ErrorMsgBuilder.h
//  BPTracker
//
//  Created by Robert Saccone on 4/22/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ErrorMsgBuilder : NSObject

+ (NSString *)build:(NSString *)message error:(NSError *)error;

@end
