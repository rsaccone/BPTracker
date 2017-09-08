//
//  BPReadingCustomTableViewCell.h
//  BPTracker
//
//  Created by Robert Saccone on 5/12/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AbstractTableViewCell.h"

@interface BPReadingCustomTableViewCell : AbstractTableViewCell

+ (void) initialize;

- (void)setTitle:(NSString*) title subTitle:(NSString*) subTitle time:(NSString*) time thumbnail:(UIImage *)aThumbnail;

@end
