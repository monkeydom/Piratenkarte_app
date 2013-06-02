//
//  PIKEditableCommentsCell.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 26.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PIKEditableCommentsCell.h"

@implementation PIKEditableCommentsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.textView = [[UITextView alloc] initWithFrame:self.detailTextLabel.frame];
        [self.contentView addSubview:self.textView];
        self.detailTextLabel.alpha = 0.0;
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.opaque = NO;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect maxRect = self.contentView.frame;
    CGRect textFieldRect = UIEdgeInsetsInsetRect(maxRect, UIEdgeInsetsMake(4.0, CGRectGetMaxX(self.textLabel.frame), 4.0, 9.0));
    self.textView.frame = textFieldRect;
    self.textView.font = self.detailTextLabel.font;
}

@end
