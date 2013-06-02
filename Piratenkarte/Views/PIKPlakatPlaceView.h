//
//  PIKPlakatPlaceView.h
//  Piratenkarte
//
//  Created by Dominik Wagner on 01.06.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PIKPlakatPlaceView;
#import "PIKPlakat.h"

typedef void (^MKDAnimationCompletionBlock)(BOOL didFinish);

@protocol PIKPlakatPlaceVieDelegate
- (void)plakatPlaceViewDidStartDrag:(PIKPlakatPlaceView *)aPlakatPlaceView;
- (BOOL)plakatPlaceViewDidEndDragShouldSnapBack:(PIKPlakatPlaceView *)aPlakatPlaceView;
@end

@interface PIKPlakatPlaceView : UIView
@property (nonatomic, weak) id<PIKPlakatPlaceVieDelegate> delegate;
@property (nonatomic, strong) NSString *plakatType;

- (id)initWithPlakatType:(NSString *)aPlakatType;

- (CGPoint)targetPointInBoundsCoordinates;
- (void)ploppViewInWithDelay:(NSTimeInterval)aDelay completion:(MKDAnimationCompletionBlock)aCompletion;
- (void)ploppViewOutCompletion:(MKDAnimationCompletionBlock)aCompletion;
@end
