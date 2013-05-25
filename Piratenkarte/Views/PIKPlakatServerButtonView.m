//
//  PIKPlakatServerButtonView.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 25.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PIKPlakatServerButtonView.h"
#import "PIKPlakatServer.h"
#import <QuartzCore/QuartzCore.h>

@interface PIKPlakatServerButtonView ()
@property (nonatomic,strong) UILabel *serverMainLabel;
@property (nonatomic,strong) UILabel *serverSubtitleLabel;
@end

@implementation PIKPlakatServerButtonView

#define LABELINSET 6.

- (UILabel *)labelWithFontSize:(CGFloat)aFontSize {
    UILabel *result = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, ceilf(aFontSize *1.2))];
	result.font = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:aFontSize];
	result.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.8];
	result.shadowOffset = CGSizeMake(0,1);
    result.textColor = [UIColor whiteColor];
    result.backgroundColor = [UIColor clearColor];
    result.opaque = NO;
    return result;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        UILabel *bigLabel = [self labelWithFontSize:16.0];
        bigLabel.text = @"Big Label Text";
        UILabel *smallLabel = [self labelWithFontSize:12.0];
        smallLabel.text = @"Small Label Text Which Has More Space";
        smallLabel.layer.anchorPoint = CGPointMake(0,0);
        bigLabel.layer.anchorPoint = CGPointMake(0,0);
        self.layer.anchorPoint = CGPointMake(0,0.0); // lets anchor ourselves to the top left for fun
        self.bounds = CGRectMake(0, 0, 200, CGRectGetHeight(bigLabel.frame) + CGRectGetHeight(smallLabel.frame) + LABELINSET);
        bigLabel.layer.position = CGPointMake(LABELINSET,2.0);
        smallLabel.layer.position = CGPointMake(LABELINSET,CGRectGetMaxY(bigLabel.frame));
        [self addSubview:smallLabel];
        [self addSubview:bigLabel];
        _serverMainLabel = bigLabel;
        _serverSubtitleLabel = smallLabel;
        self.opaque = 0.0;
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        self.layer.cornerRadius = LABELINSET;
        
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:recognizer];
        
    }
    return self;
}

- (void)handleTap:(UITapGestureRecognizer *)aRecognizer {
    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)setPlakatServer:(PIKPlakatServer *)aPlakatServer {
    self.serverMainLabel.text = aPlakatServer.serverName;
    self.serverSubtitleLabel.text = aPlakatServer.serverBaseURL;
}

@end
