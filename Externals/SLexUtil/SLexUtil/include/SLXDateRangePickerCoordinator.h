//
//  SLXDateRangePickerCoordinator.h
//  SLexUtil
//
//  Created by Robert Saccone on 7/13/14.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class SLXDateRangePickerCoordinator;

typedef NS_ENUM(NSUInteger, DateRangeComponent)
{
    Start,
    End,
    Both
};

@protocol SLXDateRangePickerCoordinatorDelegate <NSObject>

- (void)dateRangeUpdated:(SLXDateRangePickerCoordinator *)coordinator componentUpdated:(DateRangeComponent)updatedComponent;

@end

@interface SLXDateRangePickerCoordinator : NSObject

- (instancetype)initWithStartRangeTextField:(UITextField *)startRangeTextField endRangeTextField:(UITextField *)endRangeTextField;

@property(nonatomic, strong) NSDate *minDate;
@property(nonatomic, strong) NSDate *maxDate;

@property(nonatomic, strong) NSDate *startDate;
@property(nonatomic, strong) NSDate *endDate;

@property(nonatomic, weak) id<SLXDateRangePickerCoordinatorDelegate> delegate;


@end
