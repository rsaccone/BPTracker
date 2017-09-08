//
//  DataExporter.h
//  BPTracker
//
//  Created by Robert Saccone on 11/29/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DataExporter <NSObject>

- (void)addReadings:(NSArray *)bpReadings updateProgress:(void (^)(float))block;
- (void)done;

@end
