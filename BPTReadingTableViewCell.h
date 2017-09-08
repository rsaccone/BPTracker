//
//  BPTReadingTableViewCell.h
//  BPTracker
//
//  Created by Robert Saccone on 3/6/14.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BPTReadingTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbNailView;
@property (weak, nonatomic) IBOutlet UILabel *bpReadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *readingDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *notesLabel;

@end
