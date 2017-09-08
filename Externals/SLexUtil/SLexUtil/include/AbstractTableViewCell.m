//
//  ABTableViewCell.m
//  BPTracker
//
//  Created by Robert Saccone on 5/12/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "AbstractTableViewCell.h"

@interface ABTableViewCellView : UIView
@end

@implementation ABTableViewCellView

- (void)drawRect:(CGRect)r
{
    UIView *view = [self superview];
    
    while (view != nil)
    {
        if ([view isKindOfClass:[AbstractTableViewCell class]])
        {
            [((AbstractTableViewCell *)view) drawContentView:r];
            return;
        }
        else
        {
            view = [view superview];
        }
    }
}

@end

@implementation AbstractTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) 
    {
		contentView = [[ABTableViewCellView alloc] initWithFrame:CGRectZero];
		contentView.opaque = YES;
		[self addSubview:contentView];
    }
    
    return self;
}

- (void)setFrame:(CGRect)f
{
	[super setFrame:f];
	CGRect b = [self bounds];
	b.size.height -= 1; // leave room for the seperator line
	[contentView setFrame:b];
}

- (void)setNeedsDisplay
{
	[super setNeedsDisplay];
	[contentView setNeedsDisplay];
}

// Draws a disclosure indicator such that the tip of the arrow is at (x,y)
-(void) drawDisclosureIndicator:(CGContextRef) ctxt 
                              x:(CGFloat)x y:(CGFloat) y highlighted:(BOOL)highlighted 
{
    const CGFloat R = 4.5; // "radius" of the arrow head
    const CGFloat W = 3; // line width
    
    CGContextSaveGState(ctxt);
    
    CGContextMoveToPoint(ctxt, x-R, y-R);
    CGContextAddLineToPoint(ctxt, x, y);
    CGContextAddLineToPoint(ctxt, x-R, y+R);
    CGContextSetLineCap(ctxt, kCGLineCapSquare);
    CGContextSetLineJoin(ctxt, kCGLineJoinMiter);
    CGContextSetLineWidth(ctxt, W);
    
    // If the cell is highlighted (blue background) draw in white; otherwise gray
    if (highlighted) 
    {
        CGContextSetRGBStrokeColor(ctxt, 1, 1, 1, 1);
    } 
    else 
    {
        CGContextSetRGBStrokeColor(ctxt, 0.5, 0.5, 0.5, 1);
    }
    
    CGContextStrokePath(ctxt);
    
    CGContextRestoreGState(ctxt);
}

- (void)drawContentView:(CGRect)r
{
	// subclasses should implement this
}

@end
