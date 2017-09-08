//
//  BPReadingCustomTableViewCell.m
//  BPTracker
//
//  Created by Robert Saccone on 5/12/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BPReadingCustomTableViewCell.h"

#import <UIKit/UIStringDrawing.h>

@interface BPReadingCustomTableViewCell ()

@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *subTitle;
@property(nonatomic, copy) NSString *timeTitle;
@property(nonatomic, strong) UIImage *thumbnail;

@end

@implementation BPReadingCustomTableViewCell
{
@private    
    NSString *title_;
    NSString *subTitle_;
    NSString *timeTitle_;
    UIImage *thumbnail_;
}

@synthesize title = title_;
@synthesize subTitle = subTitle_;
@synthesize timeTitle = timeTitle_;
@synthesize thumbnail = thumbnail_;

static UIFont *titleFont = nil;
static UIFont *subTitleFont = nil;
static UIFont *timeTitleFont = nil;

+ (void)initialize
{
    titleFont = [UIFont systemFontOfSize:17];
    subTitleFont = [UIFont systemFontOfSize:13];
    timeTitleFont = [UIFont boldSystemFontOfSize:10];
}

- (void)setTitle:(NSString *)aTitle subTitle:(NSString *)aSubTitle 
            time:(NSString *)aTimeTitle thumbnail:(UIImage *)aThumbnail
{
    if (self.title != aTitle) 
    {
        self.title = aTitle;        
    }
    
    if (self.subTitle != aSubTitle) 
    {
        self.subTitle = aSubTitle;
    }
    
    if (self.timeTitle != aTimeTitle) 
    {
        self.timeTitle = aTimeTitle;
    }
    
    if (self.thumbnail != aThumbnail) 
    {
        self.thumbnail = aThumbnail;        
    }
    
    [self setNeedsDisplay];
}


const CGFloat ThumbNailXPos = 12;
const CGFloat ThumbNailYPos = 4;
const CGFloat ThumbNailWidth = 35;
const CGFloat ThumbNailHeight = 35;

const CGFloat GapBetweenThumbNailAndTitle = 7;
const CGFloat GapBetweenTitleAndTime = 5;
const CGFloat TimeWidth = 90;
const CGFloat TitleAndTimeDisplayYPos = 3;
const CGFloat DisclosureRightMargin = 5;

const CGFloat SubTitleXPos = 54;
const CGFloat SubTitleYPos = 23;
const CGFloat SubTitleWidth = 200;

-(void) drawContentView:(CGRect)r
{
    enum 
    {
        normalIndex = 0,
        selectedIndex = 1
    };
    
    static UIColor *titleColors[2];
    static UIColor *subtitleColors[2];
    static UIColor *timeTitleColors[2];
    
    static CGFloat titleXPos = 0;
    static CGFloat timeDisplayXPos = 0;
    static CGFloat titleDisplayWidth = 0;
    static CGFloat subtitleXPos = 0;
    static CGFloat subtitleWidth = 0;
    
    if (titleColors[normalIndex] == nil)
    {
        titleColors[normalIndex] = [UIColor darkTextColor];
        subtitleColors[normalIndex] = [UIColor darkGrayColor];
        timeTitleColors[normalIndex] = [UIColor colorWithRed:0 green:0 blue:255 alpha:0.7];
        
        titleColors[selectedIndex] = [UIColor whiteColor];
        subtitleColors[selectedIndex] = titleColors[selectedIndex];
        timeTitleColors[selectedIndex] = titleColors[selectedIndex];
        
        timeDisplayXPos = r.size.width - TimeWidth;
        titleXPos = ThumbNailXPos + ThumbNailWidth + GapBetweenThumbNailAndTitle;
        titleDisplayWidth = timeDisplayXPos - GapBetweenTitleAndTime;
        subtitleXPos = titleXPos;
        subtitleWidth = MIN(r.size.width - subtitleXPos, SubTitleWidth);
    }
        
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    BOOL highlighted = self.highlighted || self.selected;
    int colorIndex;
    
    if (highlighted)
	{
        colorIndex = selectedIndex;
		CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
		CGContextFillRect(context, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height));
		CGContextSetFillColorWithColor(context, titleColors[selectedIndex].CGColor);					
	}
	else
	{
        colorIndex = normalIndex;
		CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
		CGContextFillRect(context, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height));
		CGContextSetFillColorWithColor(context, titleColors[selectedIndex].CGColor);					
	}
    
    [titleColors[colorIndex] set];
    [thumbnail_ drawInRect:CGRectMake(ThumbNailXPos, ThumbNailYPos, ThumbNailWidth, ThumbNailHeight)];
    
    [self.title drawAtPoint:CGPointMake(titleXPos, TitleAndTimeDisplayYPos) 
               forWidth:titleDisplayWidth 
               withFont:titleFont 
               fontSize:17 
          lineBreakMode:NSLineBreakByTruncatingTail 
     baselineAdjustment:UIBaselineAdjustmentAlignCenters];    
    
    [subtitleColors[colorIndex] set];
    [self.subTitle drawAtPoint:CGPointMake(subtitleXPos, SubTitleYPos) 
                  forWidth:subtitleWidth 
                  withFont:subTitleFont 
                  fontSize:13 
             lineBreakMode:NSLineBreakByTruncatingTail 
        baselineAdjustment:UIBaselineAdjustmentAlignCenters];    
    
    [timeTitleColors[colorIndex] set];
    [self.timeTitle drawAtPoint:CGPointMake(timeDisplayXPos, TitleAndTimeDisplayYPos) 
                   forWidth:TimeWidth 
                   withFont:timeTitleFont 
                   fontSize:10 
              lineBreakMode:NSLineBreakByTruncatingTail 
         baselineAdjustment:UIBaselineAdjustmentAlignCenters];  
    
    CGFloat DisclosureX = CGRectGetMaxX(self.bounds) - DisclosureRightMargin;
    CGFloat DisclosureY = CGRectGetMidY(self.bounds);
    
    [self drawDisclosureIndicator:context x:DisclosureX y:DisclosureY highlighted:highlighted];
 }

@end
