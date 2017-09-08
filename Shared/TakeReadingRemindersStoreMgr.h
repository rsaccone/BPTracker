//
//  TakeReadingRemindersStoreMgr.h
//  BPTracker
//
//  Created by Robert Saccone on 2/25/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TakeReadingRemindersStore.h"

@interface TakeReadingRemindersStoreMgr : NSObject<TakeReadingRemindersStore>
{
}

// Designated initializer.
-(id)initWithManagedObjectContext:(NSManagedObjectContext *)mgdObjectContext;

@end
