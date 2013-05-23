//
//  MKDMutableLocationItemStorage.h
//  Piratenkarte
//
//  Created by Dominik Wagner on 23.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@protocol MKDLocationItem <NSObject>
@property (readonly,nonatomic) NSString *locationItemIdentifier;
@property (readonly,nonatomic) CLLocationCoordinate2D coordinate;
@end

@interface MKDMutableLocationItemStorage : NSObject

- (id)locationItemForItemIdentifier:(NSString *)aLocationItemIdentifier;
- (void)addLocationItem:(id<MKDLocationItem>)aLocationItem;
- (void)removeLocationItem:(id<MKDLocationItem>)aLocationItem;

@property (readonly, nonatomic) NSArray *allLocationItems;
- (NSArray *)locationItemsForCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion;

@property (readonly, nonatomic) NSUInteger count;
- (NSUInteger)countOfLocationItemsForCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion;

@end
