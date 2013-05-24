//
//  MKDMutableLocationItemStorage.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 23.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "MKDMutableLocationItemStorage.h"

// TODO: normalize to main areas

CLLocationDegrees MKDCoordnateRegionGetMinLatitude(MKCoordinateRegion aRegion) {
    CLLocationDegrees result = aRegion.center.latitude - aRegion.span.latitudeDelta;
    return result;
}

CLLocationDegrees MKDCoordnateRegionGetMaxLatitude(MKCoordinateRegion aRegion) {
    CLLocationDegrees result = aRegion.center.latitude + aRegion.span.latitudeDelta;
    return result;
}

CLLocationDegrees MKDCoordnateRegionGetMinLongitude(MKCoordinateRegion aRegion) {
    CLLocationDegrees result = aRegion.center.longitude - aRegion.span.longitudeDelta;
    return result;
}

CLLocationDegrees MKDCoordnateRegionGetMaxLongitude(MKCoordinateRegion aRegion) {
    CLLocationDegrees result = aRegion.center.longitude + aRegion.span.longitudeDelta;
    return result;
}

BOOL MKDCoordinateRegionContainsCoordinate(MKCoordinateRegion aRegion, CLLocationCoordinate2D aCoordinate) {
    aCoordinate.latitude -= aRegion.center.latitude;
    aCoordinate.longitude -= aRegion.center.longitude; // TODO: normalize across 180 degrees
    BOOL result = aRegion.span.latitudeDelta > ABS(aCoordinate.latitude);
    result = result && (aRegion.span.longitudeDelta > ABS(aCoordinate.longitude));
    return result;
}

BOOL MKDCoordinateRegionIntersectsRegion(MKCoordinateRegion aRegion1, MKCoordinateRegion aRegion2) {
    for (int i = 1; i>=0; i--) {
        MKCoordinateRegion regionA = i ? aRegion1 : aRegion2;
        MKCoordinateRegion regionB = i ? aRegion2 : aRegion1;
        CLLocationCoordinate2D coord;
        for (int loma = 1; loma >= 0; loma--) {
            for (int lama = 1; lama >= 0; lama--) {
                coord.longitude = loma ? MKDCoordnateRegionGetMaxLongitude(regionA) : MKDCoordnateRegionGetMinLongitude(regionA);
                coord.latitude = lama ? MKDCoordnateRegionGetMaxLatitude(regionA) : MKDCoordnateRegionGetMinLatitude(regionA);
                if (MKDCoordinateRegionContainsCoordinate(regionB,coord)) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

BOOL MKDCoordinateRegionContainsRegion(MKCoordinateRegion aRegion, MKCoordinateRegion subRegion) {
    CLLocationCoordinate2D coord;
    for (int loma = 1; loma >= 0; loma--) {
        for (int lama = 1; lama >= 0; lama--) {
            coord.longitude = loma ? MKDCoordnateRegionGetMaxLongitude(subRegion) : MKDCoordnateRegionGetMinLongitude(subRegion);
            coord.latitude = lama ? MKDCoordnateRegionGetMaxLatitude(subRegion) : MKDCoordnateRegionGetMinLatitude(subRegion);
            if (!MKDCoordinateRegionContainsCoordinate(aRegion,coord)) {
                return NO;
            }
        }
    }
    return YES;
}

@interface MKDMutableLocationItemStorageArea : NSObject
@property (nonatomic) MKCoordinateRegion coordinateRegion;
@property (nonatomic, strong) NSMutableArray *subAreas;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, strong) NSMutableArray *locationItems;
- (void)addLocationItem:(id<MKDLocationItem>)aLocationItem;
- (void)removeLocationItem:(id<MKDLocationItem>)aLocationItem;
- (void)addAllLocationItemsToMutableArray:(NSMutableArray *)aMutableArray;
- (void)retrieveLocationItemsForCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion toMutableArray:(NSMutableArray *)anArray;
- (NSUInteger)countOfLocationItemsForCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion;

- (instancetype)initWithCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion;
@end

@implementation MKDMutableLocationItemStorageArea
- (instancetype)initWithCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion {
    self = [super init];
    if (self) {
        _subAreas = [NSMutableArray new];
        _locationItems = [NSMutableArray new];
        _coordinateRegion = aCoordinateRegion;
    }
    return self;
}

- (void)addLocationItem:(id<MKDLocationItem>)aLocationItem {
    // should do more, but for now just add it
    [self.locationItems addObject:aLocationItem];
}

- (MKDMutableLocationItemStorageArea *)subAreaForCoordinate:(CLLocationCoordinate2D)aCoordinate {
    // TODO: find it
    return nil;
}

- (void)removeLocationItem:(id<MKDLocationItem>)aLocationItem {
    MKDMutableLocationItemStorageArea *area = [self subAreaForCoordinate:aLocationItem.coordinate];
    if (area) {
        [area removeLocationItem:aLocationItem];
    } else {
        [self.locationItems removeObject:aLocationItem];
    }
}

- (void)retrieveLocationItemsForCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion toMutableArray:(NSMutableArray *)anArray {
    if (MKDCoordinateRegionContainsRegion(aCoordinateRegion,self.coordinateRegion)) {
        // total containment - give it all
        // TODO: fix issues with going over the 180degree area
        [self addAllLocationItemsToMutableArray:anArray];
    } else if (MKDCoordinateRegionIntersectsRegion(aCoordinateRegion, self.coordinateRegion)) {
        // only a subregion intersects, find out the items
        for (id<MKDLocationItem> locationItem in self.locationItems) {
            if (MKDCoordinateRegionContainsCoordinate(aCoordinateRegion, locationItem.coordinate)) {
                [anArray addObject:locationItem];
            }
        }
        for (MKDMutableLocationItemStorageArea *subArea in self.subAreas) {
            [subArea retrieveLocationItemsForCoordinateRegion:aCoordinateRegion toMutableArray:anArray];
        }
    }

}

- (void)addAllLocationItemsToMutableArray:(NSMutableArray *)aMutableArray {
    [aMutableArray addObjectsFromArray:self.locationItems];
    for (MKDMutableLocationItemStorageArea *area in self.subAreas) {
        [area addAllLocationItemsToMutableArray:aMutableArray];
    }
}

// quick path for count of all items and items in the subarea
- (NSUInteger)count {
    NSUInteger result = self.locationItems.count;
    for (MKDMutableLocationItemStorageArea *area in self.subAreas) {
        result += area.count;
    }
    return result;
}

@end

@interface MKDMutableLocationItemStorage ()
@property (nonatomic, strong) MKDMutableLocationItemStorageArea *totalArea;
@property (nonatomic, strong) NSMutableDictionary *locationItemsByLocationItemIdentifier;
@end

@implementation MKDMutableLocationItemStorage
- (id)init {
    self = [super init];
    if (self) {
        self.totalArea = [[MKDMutableLocationItemStorageArea alloc] initWithCoordinateRegion:MKCoordinateRegionMake(CLLocationCoordinate2DMake(0, 0), MKCoordinateSpanMake(90, 180))];
        self.locationItemsByLocationItemIdentifier = [NSMutableDictionary new];
    }
    return self;
}

- (void)addLocationItem:(id<MKDLocationItem>)aLocationItem {
    NSString *identifier = aLocationItem.locationItemIdentifier;
    id<MKDLocationItem> previousItem = [self.locationItemsByLocationItemIdentifier objectForKey:identifier];
    if (previousItem) { // if we have one, remove it first so we don't mess up
        [self removeLocationItem:previousItem];
    }
    [self.locationItemsByLocationItemIdentifier setObject:aLocationItem forKey:aLocationItem.locationItemIdentifier];
    [self.totalArea addLocationItem:aLocationItem];
}

- (void)removeLocationItem:(id<MKDLocationItem>)aLocationItem {
    [self.locationItemsByLocationItemIdentifier removeObjectForKey:aLocationItem.locationItemIdentifier];
    [self.totalArea removeLocationItem:aLocationItem];
}

- (id <MKDLocationItem>)locationItemForItemIdentifier:(NSString *)anItemIdentifier {
    id <MKDLocationItem> result = [self.locationItemsByLocationItemIdentifier objectForKey:anItemIdentifier];
    return result;
}

- (void)removeLocationItemForItemIdentifier:(NSString *)aLocationItemIdentifier {
    id <MKDLocationItem> locationItem = [self locationItemForItemIdentifier:aLocationItemIdentifier];
    if (locationItem) {
        [self removeLocationItem:locationItem];
    }
}



- (NSArray *)allLocationItems {
    NSArray *result = self.locationItemsByLocationItemIdentifier.allValues;
    return result;
}

- (NSUInteger)count {
    return self.locationItemsByLocationItemIdentifier.count;
}

- (NSUInteger)countOfLocationItemsForCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion {
    NSUInteger result = [self.totalArea countOfLocationItemsForCoordinateRegion:aCoordinateRegion];
    return result;
}

- (NSArray *)locationItemsForCoordinateRegion:(MKCoordinateRegion)aCoordinateRegion {
    NSMutableArray *result = [NSMutableArray new];
    [self.totalArea retrieveLocationItemsForCoordinateRegion:aCoordinateRegion toMutableArray:result];
    return result;
}

@end
