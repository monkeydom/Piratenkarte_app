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
@property (nonatomic, strong) UIView *annotationImageView;
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
        self.annotationImageView = plakatTypeView;
        
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

- (CGPoint)targetPointInBoundsCoordinates {
    CGPoint result = self.crosshairView.center;
    return result;
}


- (void)ploppViewInWithDelay:(NSTimeInterval)aDelay completion:(MKDAnimationCompletionBlock)aCompletion {
    self.crosshairView.alpha = 0.0;
    self.transform = CGAffineTransformMakeScale(0.1, 0.1);
    self.annotationImageView.transform = CGAffineTransformIdentity;
    [UIView animateWithDuration:0.4 delay:aDelay options:0 animations:^{
        self.transform = CGAffineTransformMakeScale(1.3, 1.3);
        self.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:0.0 options:0 animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:aCompletion];
    }];
}

- (void)ploppViewOutCompletion:(MKDAnimationCompletionBlock)aCompletion {
    [UIView animateWithDuration:0.3 delay:0.0 options:0 animations:^{
        self.transform = CGAffineTransformMakeScale(0.1, 0.1);
        self.alpha = 0.0;
        self.crosshairView.alpha = 0.0;
    } completion:aCompletion];
}


- (void)didPan:(UIPanGestureRecognizer *)aPanGestureRecognizer {
    CGPoint touchPointInSuperview = self.layer.position;
    if ([aPanGestureRecognizer numberOfTouches] > 0) {
        touchPointInSuperview = [aPanGestureRecognizer locationOfTouch:0 inView:self.superview];
        touchPointInSuperview.y -= 30.0; // Thumb area bonus
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
                self.annotationImageView.transform = CGAffineTransformMakeTranslation(0, -80.);
            }];
        }
            break;
        case UIGestureRecognizerStateChanged:{
            self.transform = translation;
        }
            break;
        case UIGestureRecognizerStateEnded: {
            //inform delegate
            BOOL shouldSnapBack = YES;
            if (self.delegate) {
                shouldSnapBack = [[self delegate] plakatPlaceViewDidEndDragShouldSnapBack:self];
            }
            if (shouldSnapBack) {
                [UIView animateWithDuration:0.4 animations:^{
                    self.crosshairView.alpha = 0.0;
                    self.transform = CGAffineTransformIdentity;
                    self.annotationImageView.transform = CGAffineTransformIdentity;
                }];
            }
        }
            break;
        default:
            break;
    }
}




@end
