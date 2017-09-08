//
//  ABTableViewCell.h
//  BPTracker
//
//  Created by Robert Saccone on 5/12/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AbstractTableViewCell : UITableViewCell
{
	UIView *contentView;
}

-(void) drawDisclosureIndicator:(CGContextRef) ctxt 
                              x:(CGFloat)x y:(CGFloat) y highlighted:(BOOL)highlighted;

- (void)drawContentView:(CGRect)r; // subclasses should implement

@end
