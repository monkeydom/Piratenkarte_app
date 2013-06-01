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
        self.crosshairView.alpha = 0.0;
        self.userInteractionEnabled = YES;
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
        [self addGestureRecognizer:panRecognizer];
    }
    return self;    
}

- (void)didPan:(UIPanGestureRecognizer *)aPanGestureRecognizer {
    CGPoint touchPointInSuperview = self.layer.position;
    if ([aPanGestureRecognizer numberOfTouches] > 0) {
        touchPointInSuperview = [aPanGestureRecognizer locationOfTouch:0 inView:self.superview];
    }
    
    CGAffineTransform translation = CGAffineTransformMakeTranslation(touchPointInSuperview.x - self.layer.position.x, touchPointInSuperview.y - self.layer.position.y);
    
    switch (aPanGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            // inform delegate
            if (self.delegate) {
                [[self delegate] plakatPlaceViewDidStartDrag:self];
            }
            [UIView animateWithDuration:0.4 animations:^{
                self.crosshairView.alpha = 1.0;
            }];
        }
            break;
        case UIGestureRecognizerStateChanged:{
            self.transform = translation;
        }
            break;
        case UIGestureRecognizerStateEnded: {
            //inform delegate
            if (self.delegate) {
                [[self delegate] plakatPlaceViewDidEndDrag:self];
            }
            [UIView animateWithDuration:0.4 animations:^{
                self.crosshairView.alpha = 0.0;
                self.transform = CGAffineTransformIdentity;
            }];
        }
            break;
        default:
            break;
    }
}




@end
