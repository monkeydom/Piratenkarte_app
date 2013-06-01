//
//  PIKPlakatPlaceView.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 01.06.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PIKPlakatPlaceView.h"
#import "PIKPlakat.h"
#import <QuartzCore/QuartzCore.h>

@interface PIKPlakatPlaceView ()
@property (nonatomic, strong) UIView *crosshairView;
@end

@implementation PIKPlakatPlaceView

#define INSET 7

- (id)initWithPlakatType:(NSString *)aPlakatType {
    UIImageView *crosshairView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Crosshair"]];
    UIImageView *plakatTypeView = [[UIImageView alloc] initWithImage:[PIKPlakat annotationImageForPlakatType:aPlakatType]];
    CGRect frame = CGRectInset(plakatTypeView.frame,-INSET, -INSET);
    self = [super initWithFrame:frame];
    if (self) {
        
        plakatTypeView.frame = CGRectInset(self.bounds,INSET,INSET);
        [self addSubview:plakatTypeView];
        crosshairView.layer.position = CGPointMake(CGRectGetMidX(self.bounds)+0.5, -CGRectGetHeight(crosshairView.frame) + 10.5);
        [self addSubview:crosshairView];
        self.crosshairView=crosshairView;
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    }
    return self;    
}

@end
