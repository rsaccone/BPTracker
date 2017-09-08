//
//  UserSettingKeys.h
//  BPTracker
//
//  Created by Robert Saccone on 6/9/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const selectedTabKey;                     // Selected tab tabbar.
extern NSString *const bpTableViewSectionSelectedKey;      // Section of the selected item in the blood pressure table view.
extern NSString *const bpTableViewRowSelectedKey;          // Row of selected item in the blood pressure table view.
extern NSString *const bpTableViewEditSelectedKey;         // Indicates whether or not the current selection was in the process of being edited.
extern NSString *const bpTableViewSortAscendingKey;        // Sorting order (ascending)

extern NSString *const reminderTableViewSectionSelectedKey;     // Section of the selected item in the reminder table view.
extern NSString *const reminderTableViewRowSelectedKey;         // Row of selected item in the reminder table view.
extern NSString *const reminderTableViewEditSelectedKey;        // Indicates if the current selection was in the process of being edited.
extern NSString *const reminderTableViewSelectionIdKey;         // Event identifier of the save secltion in the reminder table view.
extern NSString *const reminderTableViewSortAscendingKey;       // Sorting order (ascending)

extern NSString *const weightEntryDefaultValueKey;  // Last weight the user entered when entering a new reading.

extern NSString *const bpGraphStartDateKey;         // Last start date for the BP Graph.
extern NSString *const bpGraphEndDateKey;           // Last end date for the BP Graph.
extern NSString *const bpGraphSystolicDataKey;      // Include Systolic Data in BP Graph.
extern NSString *const bpGraphDiastolicDataKey;     // Include Diastolic Data in BP Graph.
extern NSString *const bpGraphPulseDataKey;         // Include Pulse Data in BP Graph.
extern NSString *const bpGraphLegendKey;            // Include Legend in BP Graph.
