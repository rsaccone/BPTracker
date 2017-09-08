//
//  PlatformHelper.h
//  BPTracker
//
//  Created by Robert Saccone on 2/21/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIDevice.h>

inline BOOL runningOniPad()
{
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? YES : NO;
}

inline BOOL runningOniPhone()
{
    return !runningOniPad();
}

@interface PlatformHelper : NSObject 

+ (BOOL) oniPad;
+ (BOOL) oniPhone;
+ (NSString *) addSuffixToResourceName:(NSString *)resourceName;

@end
