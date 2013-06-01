//
//  PIKPlakatPlaceView.h
//  Piratenkarte
//
//  Created by Dominik Wagner on 01.06.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PIKPlakatPlaceView;

@protocol PIKPlakatPlaceVieDelegate
- (void)plakatPlaceViewDidStartDrag:(PIKPlakatPlaceView *)aPlakatPlaceView;
- (void)plakatPlaceViewDidEndDrag:(PIKPlakatPlaceView *)aPlakatPlaceView;
@end

@interface PIKPlakatPlaceView : UIView
@property (nonatomic, weak) id<PIKPlakatPlaceVieDelegate> delegate;
- (id)initWithPlakatType:(NSString *)aPlakatType;

@end
