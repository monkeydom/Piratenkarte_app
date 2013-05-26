//
//  PIKNetworkErrorIndicationView.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 26.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PIKNetworkErrorIndicationView.h"
#import <QuartzCore/QuartzCore.h>
#import "PIKServerListViewController.h"

@implementation PIKNetworkErrorIndicationView

+ (instancetype)networkErrorIndicationView {
    return [[self alloc] initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    UIImage *networkErrorImage = [UIImage imageNamed:@"alert-big"];
    frame.size = networkErrorImage.size;
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *alertImageView = [[UIImageView alloc] initWithImage:networkErrorImage];
        self.bounds = alertImageView.bounds;
        alertImageView.frame = self.bounds;
        [self addSubview:alertImageView];
        self.userInteractionEnabled = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNetworkError:) name:PIKPlakatServerManagerDidEncounterNetworkError object:nil];
        self.layer.anchorPoint = CGPointMake(1,0);
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.alpha = 0.0;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)indicateNetworkError {
    [UIView animateWithDuration:1.0 delay:0.2 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.alpha = 1.0;
    } completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:0.8 animations:^{
                self.alpha = 0.0;
            }];
        }
    }];
}

- (void)didReceiveNetworkError:(NSNotificationCenter *)aNotification {
    [self indicateNetworkError];
}


@end
