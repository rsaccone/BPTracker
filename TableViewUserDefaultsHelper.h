//
//  TableViewUserDefaultsHelper.h
//  BPTracker
//
//  Created by Robert Saccone on 6/10/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

enum TableViewKeyIndex
{
    sectionKeyIndex = 0,
    rowKeyIndex = 1,
    editFlagKeyIndex = 2,
    sortAscendingIndex = 3,
    numTableViewKeys
};

@interface TableViewUserDefaultsHelper : NSObject

- (id)initWithKeyNames:(NSArray *)keyNames;
- (NSIndexPath *)getSavedSelection;
- (BOOL)getSavedEditingFlag;
- (BOOL)getSortAscendingFlag;
- (void)saveEditingFlag:(BOOL)editingFlag;
- (void)saveSelectedIndex:(NSIndexPath *)indexPath withEditFlag:(BOOL)editing;
- (void)saveSortAscendingFlag:(BOOL)sortAscendingFlag;

@end
