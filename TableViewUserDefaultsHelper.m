//
//  TableViewUserDefaultsHelper.cs
//  BPTracker
//
//  Created by Robert Saccone on 6/10/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "TableViewUserDefaultsHelper.h"

@interface TableViewUserDefaultsHelper ()

@property(nonatomic, strong) NSArray *keyNames;

@end

@implementation TableViewUserDefaultsHelper
{
@private
    NSArray *keyNames_;
}

@synthesize keyNames = keyNames_;

- (id)initWithKeyNames:(NSArray *)keyNames
{
    if (!keyNames)
    {
        NSLog(@"TableViewUserDefaultsHelper init: keyNames is nil!");
        NSAssert(NO, @"keyNames is nil!");
        
        
        return nil;
    }
    
    if (keyNames.count < numTableViewKeys)
    {
        NSLog(@"TableViewUserDefaultsHelper init: incorrect number of keys (%lu) in keyNames", (unsigned long)keyNames.count);
        NSAssert2(NO, @"keyNames count is %lu, should be %d", (unsigned long)keyNames.count, numTableViewKeys);
        return nil;
    }
    
    for (NSString *key in keyNames)
    {
        if ((key == nil) && (key.length == 0))
        {
            NSLog(@"TableViewUserDefaultsHelper init: one or more keys is nil or empty!");
            return nil;
        }
    }
    
    self = [super init];
    
    if (self != nil)
    {
        keyNames_ = keyNames;
    }
    
    return self;
}

- (id)init
{
    return [self initWithKeyNames:nil];
}

- (NSIndexPath *)getSavedSelection
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *keyNames = self.keyNames;
    
    NSNumber *value = [userDefaults objectForKey:[keyNames objectAtIndex:sectionKeyIndex]];
    
    if (!value)
    {
        return nil;
    }
    
    NSInteger section = [value integerValue];
    
    value = [userDefaults objectForKey:[self.keyNames objectAtIndex:rowKeyIndex]];
    
    if (!value)
    {
        return nil;
    }
    
    NSInteger row = [value integerValue];
    
    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (BOOL)getSavedEditingFlag
{
    BOOL editing = NO;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSNumber *value = [userDefaults objectForKey:[self.keyNames objectAtIndex:editFlagKeyIndex]];
    
    if (value)
    {
        editing = [value boolValue];
    }
    
    return editing;
}

- (void)saveEditingFlag:(BOOL)editingFlag
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:editingFlag]
                                              forKey:[self.keyNames objectAtIndex:editFlagKeyIndex]];
}

- (void)saveSelectedIndex:(NSIndexPath *)indexPath withEditFlag:(BOOL)editing
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    if (!indexPath)
    {
        [userDefaults setObject:nil
                         forKey:[self.keyNames objectAtIndex:sectionKeyIndex]];
        
        [userDefaults setObject:nil
                         forKey:[self.keyNames objectAtIndex:rowKeyIndex]];
        
        [userDefaults setObject:nil
                         forKey:[self.keyNames objectAtIndex:editFlagKeyIndex]];
    }
    else
    {
        [userDefaults setObject:[NSNumber numberWithInteger:indexPath.section] 
                         forKey:[self.keyNames objectAtIndex:sectionKeyIndex]];

        [userDefaults setObject:[NSNumber numberWithInteger:indexPath.row] 
                         forKey:[self.keyNames objectAtIndex:rowKeyIndex]];

        [userDefaults setObject:[NSNumber numberWithBool:editing] 
                         forKey:[self.keyNames objectAtIndex:editFlagKeyIndex]];
    }

    [userDefaults synchronize];
}

- (BOOL)getSortAscendingFlag
{
    BOOL sortAscending = YES;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSNumber *value = [userDefaults objectForKey:[self.keyNames objectAtIndex:sortAscendingIndex]];
    
    if (value)
    {
        sortAscending = [value boolValue];
    }
    
    return sortAscending;
}

- (void)saveSortAscendingFlag:(BOOL)sortAscendingFlag
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:sortAscendingFlag]
                                              forKey:[self.keyNames objectAtIndex:sortAscendingIndex]];
}

@end
