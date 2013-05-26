//
//  PIKLongDescriptionTableViewCell.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 25.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PIKLongDescriptionTableViewCell.h"

#import <QuartzCore/QuartzCore.h>

@implementation PIKLongDescriptionTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
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
    CGRect bounds = self.contentView.bounds;
    CGRect labelRect = self.textLabel.frame;
    labelRect.origin.y = bounds.origin.y + 4;
    self.textLabel.frame = labelRect;
    CGRect detailRect = self.detailTextLabel.frame;
    detailRect.origin.y = CGRectGetMaxY(labelRect);
    detailRect.size.height = CGRectGetMaxY(bounds) - CGRectGetMaxY(labelRect);
    
    if (self.editingStyle == UITableViewCellEditingStyleDelete) {
        detailRect.size.width = CGRectGetWidth(self.contentView.superview.frame) - 50;
    }
    
    self.detailTextLabel.frame = detailRect;
    self.detailTextLabel.numberOfLines = 0;
    [self.detailTextLabel sizeToFit];
    
    detailRect = self.detailTextLabel.frame;
    detailRect.origin.y = CGRectGetMaxY(labelRect);
    self.detailTextLabel.frame = detailRect;
    
//    self.contentView.layer.borderColor = [[UIColor blackColor] CGColor];
//    self.contentView.layer.borderWidth = 1.0;
}

@end
