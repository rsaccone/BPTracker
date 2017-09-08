//
//  ScatterPlotGraph.h
//  BPTracker
//
//  Created by Robert Saccone on 7/4/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CorePlot-CocoaTouch/CorePlot-CocoaTouch.h>
#import "BPGraphSettings.h"

@interface ScatterPlotGraph : NSObject

// Method to create this object and attach it to it's hosting view.
-(id)initWithHostingView:(CPTGraphHostingView *)hostingView
           graphSettings:(BPGraphSettings *)bpGraphSettings
             graphValues:(NSArray *)data
             topBarOffet:(CGFloat)topBarOffset
         bottomBarOffset:(CGFloat)bottomBarOffset;


// Specific code that creates the scatter plot.
-(void)initialisePlot;

@property(nonatomic, assign) BOOL displayLegend;

@end
