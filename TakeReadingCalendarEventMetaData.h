//
//  TakeReadingCalendarEventMetaData.h
//  BPTracker
//
//  Created by Robert Saccone on 2/27/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TakeReadingCalendarEventMetaData : NSManagedObject

@property (nonatomic, copy) NSString *eventIdentifier;

@end
