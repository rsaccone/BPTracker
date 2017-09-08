//
//  UserSettingKeys.m
//  BPTracker
//
//  Created by Robert Saccone on 6/9/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "UserSettingKeys.h"

NSString *const selectedTabKey                 = @"selectedTab";                   // Selected tab tabbar.
NSString *const bpTableViewSectionSelectedKey  = @"bpTableViewSectionSelected";    // Section of the selected item in the blood pressure table view.
NSString *const bpTableViewRowSelectedKey      = @"bpTableViewRowSelected";        // Row of selected item in the blood pressure table view.
NSString *const bpTableViewEditSelectedKey     = @"bpTableViewEditSelected";       // Indicates if the current selection was in the process of being edited.
NSString * const bpTableViewSortAscendingKey   = @"bpTableViewSortAscending";      // Sorting order (ascending)

NSString *const reminderTableViewSectionSelectedKey = @"reminderTableViewSectionSelected";    // Section of the selected item in the reminder table view.
NSString *const reminderTableViewRowSelectedKey     = @"reminderTableViewRowSelected";        // Row of selected item in the reminder table view.
NSString *const reminderTableViewEditSelectedKey    = @"reminderTableViewEditSelected";       // Indicates if the current selection was in the process of being edited.
NSString *const reminderTableViewSelectionIdKey     = @"reminderTableViewSelectionIdKey";     // Event identifier of the save secltion in the reminder table view.
NSString *const reminderTableViewSortAscendingKey   = @"reminderTableViewSortAscending";      // Sorting order (ascending)

NSString *const weightEntryDefaultValueKey = @"weightEntryDefaultValueKey";  // Last weight the user entered when entering a new reading.

NSString *const bpGraphStartDateKey         = @"bpGraphStartDateKey";         // Last start date for the BP Graph.
NSString *const bpGraphEndDateKey           = @"bpGraphEndDateKey";           // Last end date for the BP Graph.
NSString *const bpGraphSystolicDataKey      = @"bpGraphSystolicDataKey";      // Include Systolic Data in BP Graph.
NSString *const bpGraphDiastolicDataKey     = @"bpGraphDiastolciDataKey";     // Include Diastolic Data in BP Graph.
NSString *const bpGraphPulseDataKey         = @"bpGraphPulseDataKey";         // Include Pulse Data in BP Graph.
NSString *const bpGraphLegendKey            = @"bpGraphLegendKey";            // Include Legend in BP Graph.
