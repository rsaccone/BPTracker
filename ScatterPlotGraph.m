//
//  ScatterPlotGraph.m
//  BPTracker
//
//  Created by Robert Saccone on 7/4/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "ScatterPlotGraph.h"

#import "BloodPressureDataAnalyzer.h"
#import "BloodPressureReading.h"

@interface ScatterPlotGraph ()<CPTPlotDataSource>

- (void)configureGraph;
- (void)configurePlots;
- (void)configureAxes;
- (void)configureLegend;

@property(nonatomic, strong) CPTGraphHostingView *hostingView;
@property(nonatomic, strong) CPTXYGraph *graph;
@property(nonatomic, strong) BPGraphSettings *graphSettings;
@property(nonatomic, strong) NSArray *graphData;
@property(nonatomic, assign) CGFloat topBarOffset;
@property(nonatomic, assign) CGFloat bottomBarOffset;

@end

@implementation ScatterPlotGraph
{
@private    
    CPTGraphHostingView *hostingView_;
    CPTXYGraph *graph_;
    BPGraphSettings *graphSettings_;
    NSArray *graphData_;
    CGFloat topBarOffset_;
    CGFloat bottomBarOffset_;
}

@synthesize hostingView = hostingView_;
@synthesize graph = graph_;
@synthesize graphData = graphData_;
@synthesize graphSettings = graphSettings_;
@synthesize topBarOffset = topBarOffset_;
@synthesize bottomBarOffset = bottomBarOffset_;
@synthesize displayLegend;

// Distance to place between values on the x-axis.
static const int X_AXIS_VALUE_SPACING = 2;

static NSString *SystolicPlotIdentifier = @"Systolic Data";
static NSString *DiastolicPlotIdentifier = @"Diastolic Data";
static NSString *PulsePlotIdentifier = @"Pulse Data";

// Initialise the scatter plot in the provided hosting view with the provided data.
// The data array should contain NSValue objects each representing a CGPoint.
-(id)initWithHostingView:(CPTGraphHostingView *)hostingView
           graphSettings:(BPGraphSettings *)bpGraphSettings
             graphValues:(NSArray *)data
             topBarOffet:(CGFloat)topBarOffset
         bottomBarOffset:(CGFloat)bottomBarOffset;
{
    self = [super init];
    
    if ( self != nil )
    {
        hostingView_ = hostingView;
        graphSettings_ = bpGraphSettings;
        graphData_ = data;
        graph_ = nil;
        topBarOffset_ = topBarOffset;
        bottomBarOffset_ = bottomBarOffset;
    }
    
    return self;
}

// This does the actual work of creating the plot if we don't already have a graph object.
-(void)initialisePlot
{
    // Start with some simple sanity checks before we kick off
    if ( (self.hostingView == nil) || (self.graphData == nil) )
    {
        NSLog(@"TUTSimpleScatterPlot: Cannot initialise plot without hosting view or data.");
        return;
    }
    
    if ( self.graph != nil )
    {
        NSLog(@"TUTSimpleScatterPlot: Graph object already exists.");
        return;
    }
    
    [self configureGraph];
    [self configurePlots];
    [self configureAxes];
    [self configureLegend];
    
}

- (void)configureGraph
{
    // 1 - Create the graph
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero /*bounds*/];
    [graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]]; // kCPTDarkGradientTheme]];
    self.hostingView.hostedGraph = graph;
    
    // Border
	graph.plotAreaFrame.borderLineStyle = nil;
	graph.plotAreaFrame.cornerRadius	   = 0.0f;

	// Paddings
	graph.paddingLeft   = 0.0f;
	graph.paddingRight  = 0.0f;
	graph.paddingTop	= 0.0f;
	graph.paddingBottom = 0.0f;

    /*
	barChart.plotAreaFrame.paddingLeft	 = 70.0;
	barChart.plotAreaFrame.paddingTop	 = 20.0;
	barChart.plotAreaFrame.paddingRight	 = 20.0;
	barChart.plotAreaFrame.paddingBottom = 80.0;
    */
    
    // 2 - Set graph title
    graph.title = nil;
    
    // 3 - Create and set text style
    CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
    titleStyle.color = [CPTColor blackColor];
    titleStyle.fontName = @"Helvetica-Bold";
    titleStyle.fontSize = 16.0f;
    graph.titleTextStyle = titleStyle;
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.titleDisplacement = CGPointMake(0.0f, 10.0f);
    
    // 4 - Set padding for plot area
    [graph.plotAreaFrame setPaddingLeft:30.0f];
    [graph.plotAreaFrame setPaddingBottom:40.0f + self.bottomBarOffset];
    
    // 5 - Enable user interactions for plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
}

- (void)configurePlots
{
    // 1 - Get graph and plot space
    CPTGraph *graph = self.hostingView.hostedGraph;
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    CPTScatterPlot *systolicPlot = nil;
    CPTScatterPlot *diastolicPlot = nil;
    CPTScatterPlot *pulsePlot = nil;

    if (self.graphSettings.systolicData)
    {
        // 2 - Create the three plots
        systolicPlot = [[CPTScatterPlot alloc] init];
        systolicPlot.dataSource = self;
        systolicPlot.identifier = SystolicPlotIdentifier;
        [graph addPlot:systolicPlot toPlotSpace:plotSpace];
    }
    
    if (self.graphSettings.diasotlicData)
    {
        diastolicPlot = [[CPTScatterPlot alloc] init];
        diastolicPlot.dataSource = self;
        diastolicPlot.identifier = DiastolicPlotIdentifier;
        [graph addPlot:diastolicPlot toPlotSpace:plotSpace];
    }
    
    if (self.graphSettings.pulseData)
    {
        pulsePlot = [[CPTScatterPlot alloc] init];
        pulsePlot.dataSource = self;
        pulsePlot.identifier = PulsePlotIdentifier;
        [graph addPlot:pulsePlot toPlotSpace:plotSpace];
    }
    
    // 3 - Set up plot space
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:[[NSNumber numberWithFloat:0] decimalValue ]
                                                    length:[[NSNumber numberWithFloat:self.graphData.count] decimalValue] ];
    
    
    short yMaxShort = MAX([BloodPressureDataAnalyzer instance].maxDiastolic, [BloodPressureDataAnalyzer instance].maxSystolic);
    yMaxShort = MAX(yMaxShort, [[BloodPressureDataAnalyzer instance] maxPulse]);
    
    CGFloat yMax = (CGFloat)yMaxShort;
    
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:[[NSNumber numberWithFloat:0] decimalValue]
                                                    length:[[NSNumber numberWithFloat:yMax] decimalValue]];
    
    // 4 - Create styles and symbols
    if (systolicPlot)
    {
        CPTColor *systolicColor = [CPTColor blueColor];
        CPTMutableLineStyle *systolicLineStyle = [systolicPlot.dataLineStyle mutableCopy];
        systolicLineStyle.lineWidth = 2.5;
        systolicLineStyle.lineColor = systolicColor;
        systolicPlot.dataLineStyle = systolicLineStyle;
        CPTMutableLineStyle *systolicSymbolLineStyle = [CPTMutableLineStyle lineStyle];
        systolicSymbolLineStyle.lineColor = systolicColor;
        CPTPlotSymbol *systolicSymbol = [CPTPlotSymbol ellipsePlotSymbol];
        systolicSymbol.fill = [CPTFill fillWithColor:systolicColor];
        systolicSymbol.lineStyle = systolicSymbolLineStyle;
        systolicSymbol.size = CGSizeMake(6.0f, 6.0f);
        systolicPlot.plotSymbol = systolicSymbol;
    }
    
    if (diastolicPlot)
    {
        CPTColor *diastolicColor = [CPTColor cyanColor];
        CPTMutableLineStyle *diastolicLineStyle = [diastolicPlot.dataLineStyle mutableCopy];
        diastolicLineStyle.lineWidth = 2.5;
        diastolicLineStyle.lineColor = diastolicColor;
        diastolicPlot.dataLineStyle = diastolicLineStyle;
        CPTMutableLineStyle *diastolicSymbolLineStyle = [CPTMutableLineStyle lineStyle];
        diastolicSymbolLineStyle.lineColor = diastolicColor;
        CPTPlotSymbol *diastolicSymbol = [CPTPlotSymbol diamondPlotSymbol];
        diastolicSymbol.fill = [CPTFill fillWithColor:diastolicColor];
        diastolicSymbol.lineStyle = diastolicSymbolLineStyle;
        diastolicSymbol.size = CGSizeMake(6.0f, 6.0f);
        diastolicPlot.plotSymbol = diastolicSymbol;
    }
    
    if (pulsePlot)
    {
        CPTColor *pulseColor = [CPTColor magentaColor];
        CPTMutableLineStyle *pulseLineStyle = [pulsePlot.dataLineStyle mutableCopy];
        pulseLineStyle.lineWidth = 2.5;
        pulseLineStyle.lineColor = pulseColor;
        pulsePlot.dataLineStyle = pulseLineStyle;
        CPTMutableLineStyle *pulseSymbolLineStyle = [CPTMutableLineStyle lineStyle];
        pulseSymbolLineStyle.lineColor = pulseColor;
        CPTPlotSymbol *pulseSymbol = [CPTPlotSymbol starPlotSymbol];
        pulseSymbol.fill = [CPTFill fillWithColor:pulseColor];
        pulseSymbol.lineStyle = pulseSymbolLineStyle;
        pulseSymbol.size = CGSizeMake(6.0f, 6.0f);
        pulsePlot.plotSymbol = pulseSymbol;
    }
}

- (void)configureAxes
{
    // 1 - Create styles
    CPTMutableTextStyle *axisTitleStyle = [CPTMutableTextStyle textStyle];
    axisTitleStyle.color = [CPTColor blackColor];
    axisTitleStyle.fontName = @"Helvetica-Bold";
    axisTitleStyle.fontSize = 12.0f;
    axisTitleStyle.textAlignment = CPTTextAlignmentLeft;

    
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 2.0f;
    axisLineStyle.lineColor = [CPTColor blackColor];
    
    CPTMutableTextStyle *axisTextStyle = [[CPTMutableTextStyle alloc] init];
    axisTextStyle.color = [CPTColor blackColor];
    axisTextStyle.fontName = @"Helvetica-Bold";
    axisTextStyle.fontSize = 11.0f;
    axisTextStyle.textAlignment = CPTTextAlignmentCenter;
    
    CPTMutableLineStyle *tickLineStyle = [CPTMutableLineStyle lineStyle];
    tickLineStyle.lineColor = [CPTColor whiteColor];
    tickLineStyle.lineWidth = 2.0f;
    
    CPTMutableLineStyle *gridLineStyle = [CPTMutableLineStyle lineStyle];
    tickLineStyle.lineColor = [CPTColor whiteColor];
    tickLineStyle.lineWidth = 1.0f;
    
    // 2 - Get axis set
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostingView.hostedGraph.axisSet;
    
    // 3 - Configure x-axis
    CPTAxis *x = axisSet.xAxis;
    x.title = NSLocalizedString(@"BP_GRAPH_X_AXIS", nil);
    x.titleTextStyle = axisTitleStyle;
    x.titleOffset = 60.0f;
    x.axisLineStyle = axisLineStyle;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    x.labelTextStyle = axisTextStyle;
    x.majorTickLineStyle = axisLineStyle;
    x.majorIntervalLength = CPTDecimalFromCGFloat(1.0);
    x.majorTickLength = 17.0f;
    x.tickDirection = CPTSignNegative;
    CGFloat dateCount = [self.graphData count];
    NSMutableSet *xLabels = [NSMutableSet setWithCapacity:dateCount];
    NSMutableSet *xLocations = [NSMutableSet setWithCapacity:dateCount];
    NSInteger i = 0;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];

    [dateFormatter2 setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter2 setTimeStyle:NSDateFormatterShortStyle];

    CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:nil  textStyle:x.labelTextStyle];
    CGFloat location = i++ * X_AXIS_VALUE_SPACING;
    label.tickLocation = CPTDecimalFromCGFloat(location);
    label.offset = x.majorTickLength;
    if (label)
    {
        [xLabels addObject:label];
        [xLocations addObject:[NSNumber numberWithFloat:location]];
    }
    
    for (BloodPressureReading *bpReading in self.graphData)
    {
        NSDate *date = bpReading.readingDate;
        NSString *formattedDate = [dateFormatter stringFromDate:date];
        NSString *formattedTime = [dateFormatter2 stringFromDate:date];
        NSString *labelString = [NSString stringWithFormat:@"%@\n%@", formattedDate, formattedTime];

        label = [[CPTAxisLabel alloc] initWithText:labelString textStyle:x.labelTextStyle];
        location = i++ * X_AXIS_VALUE_SPACING;
        label.tickLocation = CPTDecimalFromCGFloat(location);
        label.offset = x.majorTickLength;
        if (label)
        {
            [xLabels addObject:label];
            [xLocations addObject:[NSNumber numberWithFloat:location]];
        }
    }
    
    x.axisLabels = xLabels;
    x.majorTickLocations = xLocations;
    
    // 4 - Configure y-axis
    CPTAxis *y = axisSet.yAxis;
    y.title = NSLocalizedString(@"BP_GRAPH_Y_AXIS", nil);
    y.titleTextStyle = axisTitleStyle;
    y.titleOffset = 30.0f; //-40.0f;
    y.axisLineStyle = axisLineStyle;
    y.majorGridLineStyle = gridLineStyle;
    y.labelingPolicy = CPTAxisLabelingPolicyNone;
    y.labelTextStyle = axisTextStyle;
    y.labelOffset = -8.0f;
    y.majorTickLineStyle = tickLineStyle; //axisLineStyle;
    y.majorTickLength = 4.0f;
    y.minorTickLength = 0.5f;//2.0f;
    y.tickDirection = CPTSignNegative;
    NSInteger majorIncrement = 100;
    NSInteger minorIncrement = 20;
    CGFloat yMax = (CGFloat)MAX([BloodPressureDataAnalyzer instance].maxDiastolic, [BloodPressureDataAnalyzer instance].maxSystolic);
    NSMutableSet *yLabels = [NSMutableSet set];
    NSMutableSet *yMajorLocations = [NSMutableSet set];
    NSMutableSet *yMinorLocations = [NSMutableSet set];
    for (NSInteger j = 0; j <= yMax; j += minorIncrement)
    {
        NSUInteger mod = j % majorIncrement;

        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%li", (long)j] textStyle:y.labelTextStyle];
        NSDecimal location = CPTDecimalFromInteger(j);
        label.tickLocation = location;
        label.offset = -y.majorTickLength - y.labelOffset;
        
        [yLabels addObject:label];
        
        /*
        if (label)
        {
            [yLabels addObject:label];
        }
        */
        
        if ((mod == 0) && (j != 0))
        {
            [yMajorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:location]];
        }
        else
        {
            [yMinorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:CPTDecimalFromInteger(j)]];
        }
    }
    
    y.axisLabels = yLabels;    
    y.majorTickLocations = yMajorLocations;
    y.minorTickLocations = yMinorLocations;
}

- (void)configureLegend
{
    if (self.graphSettings.legend)
    {
        CPTMutableTextStyle *legendTitleStyle = [CPTMutableTextStyle textStyle];
        legendTitleStyle.color = [CPTColor blackColor];
        legendTitleStyle.fontName = @"Helvetica-Bold";
        legendTitleStyle.fontSize = 12.0f;
        legendTitleStyle.textAlignment = CPTTextAlignmentLeft;

        CPTMutableLineStyle *legendLineStyle = [CPTMutableLineStyle lineStyle];
        legendLineStyle.lineWidth = 2.0f;
        legendLineStyle.lineColor = [CPTColor blackColor];

        // Add legend
        CPTGraph *graph = self.hostingView.hostedGraph;

        graph.legend = [CPTLegend legendWithGraph:graph];
        graph.legend.textStyle = legendTitleStyle;
        graph.legend.fill = [CPTFill fillWithColor:[CPTColor whiteColor]];
        graph.legend.borderLineStyle = legendLineStyle;
        graph.legend.cornerRadius = 5.0;
        graph.legend.swatchSize = CGSizeMake(25.0, 25.0);
        graph.legendAnchor = CPTRectAnchorTop;
        
        graph.legendDisplacement = CGPointMake(0.0, -25.0 - self.topBarOffset);
    }
    else
    {
        self.hostingView.hostedGraph.legend = nil;
    }
}

// Delegate method that returns the number of points on the plot
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    if ( [plot.identifier isEqual:SystolicPlotIdentifier] || [plot.identifier isEqual:DiastolicPlotIdentifier]  || [plot.identifier isEqual:PulsePlotIdentifier])
    {
        return [self.graphData count];
    }
    
    return 0;
}

// Delegate method that returns a single X or Y value for a given plot.
-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    if (fieldEnum == CPTScatterPlotFieldX)
    {
        return [NSNumber numberWithFloat:(index + 1) * X_AXIS_VALUE_SPACING];
    }

    BloodPressureReading *bpR = [self.graphData objectAtIndex:index];
    
    if ([plot.identifier isEqual:SystolicPlotIdentifier])
    {
        return bpR.systolic;
    }
    
    if ([plot.identifier isEqual:DiastolicPlotIdentifier])
    {
        return bpR.diastolic;
    }
    
    if ([plot.identifier isEqual:PulsePlotIdentifier])
    {
        return bpR.pulse;
    }
    
    return [NSNumber numberWithFloat:0];
}

#pragma mark - Enable / Disable Legend display

- (void)setDisplayLegend:(BOOL)display
{
    self.graphSettings.legend = display;
    [self configureLegend];
}

- (BOOL)displayLegend
{
    return self.graphSettings.legend;
}

@end
