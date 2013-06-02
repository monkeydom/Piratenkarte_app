//
//  PIKPlakat.h
//  Piratenkarte
//
//  Created by Dominik Wagner on 23.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKDMutableLocationItemStorage.h"
#import <CoreLocation/CoreLocation.h>
#import "Api.pb.h"


NSString * const PIKPlakatTypeDefault   ;
NSString * const PIKPlakatTypeA0        ;
NSString * const PIKPlakatTypeStolen    ;
NSString * const PIKPlakatTypeNicePlace;
NSString * const PIKPlakatTypeOK      ;
NSString * const PIKPlakatTypeWrecked;
NSString * const PIKPlakatTypeWall   ;   
NSString * const PIKPlakatTypeWallOK;


@interface PIKPlakat : NSObject <MKDLocationItem, MKAnnotation>
@property (nonatomic) uint32_t plakatID;
@property (nonatomic, readonly, strong) NSString *locationItemIdentifier;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) NSString *plakatType;
@property (nonatomic, strong) NSDate *lastModifiedDate;
@property (nonatomic, readonly) NSString *localizedLastModifiedDate;
@property (nonatomic, strong) NSDate *lastServerFetchDate;
@property (nonatomic, readonly) NSString *localizedLastServerFetchDate;
@property (nonatomic, strong) NSString *comment;
@property (nonatomic, strong) NSString *imageURLString;
@property (nonatomic, strong) NSString *usernameOfLastChange;
@property (nonatomic, readonly) NSString *localizedType;

@property (nonatomic, readonly) UIImage *annotationImage;
@property (nonatomic, readonly) UIImage *pinImage;
@property (nonatomic, readonly) CGPoint pinImageCenterOffset;

// initializer for server based plakate
- (instancetype)initWithPlakat:(Plakat *)aPlakat serverFetchDate:(NSDate *)aServerFetchDate;
// initializer for newly created plakate
- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)aCoordinate plakatType:(NSString *)aPlakatType;


+ (NSDateFormatter *)dateFormatter;

+ (NSArray *)orderedPlakatTypes;
+ (UIImage *)annotationImageForPlakatType:(NSString *)aPlakatType;

@end
