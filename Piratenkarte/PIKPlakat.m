//
//  PIKPlakat.m
//  Piratenkarte
//
//  Created by Dominik Wagner on 23.05.13.
//  Copyright (c) 2013 Dominik Wagner. All rights reserved.
//

#import "PIKPlakat.h"

NSString * const PIKPlakatTypeDefault   = @"plakat_default";
NSString * const PIKPlakatTypeA0        = @"plakat_a0";
NSString * const PIKPlakatTypeStolen    = @"plakat_dieb";
NSString * const PIKPlakatTypeNicePlace = @"plakat_niceplace";
NSString * const PIKPlakatTypeOK        = @"plakat_ok";
NSString * const PIKPlakatTypeWrecked   = @"plakat_wrecked";
NSString * const PIKPlakatTypeWall      = @"wand";
NSString * const PIKPlakatTypeWallOK    = @"wand_ok";

@interface PIKPlakat ()
@property (nonatomic, strong, readwrite) NSString *locationItemIdentifier;
@end

@implementation PIKPlakat

+ (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *formatter;
    if (!formatter) {
        formatter = [NSDateFormatter new];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return formatter;
}

- (instancetype)initWithPlakat:(Plakat *)aPlakat serverFetchDate:(NSDate *)aServerFetchDate {
    self = [self init];
    if (self) {
        self.lastServerFetchDate = aServerFetchDate;
        [self updateValuesWithPlakat:(Plakat *)aPlakat];
    }
    return self;
}

+ (NSArray *)orderedPlakatTypes {
    return @[
             PIKPlakatTypeNicePlace,
             PIKPlakatTypeOK,
             PIKPlakatTypeA0,
             PIKPlakatTypeStolen,
             PIKPlakatTypeWrecked,
             PIKPlakatTypeWall,
             PIKPlakatTypeWallOK,
             ];
}

+ (UIImage *)annotationImageForPlakatType:(NSString *)aPlakatType {
    UIImage *result = [UIImage imageNamed:[NSString stringWithFormat:@"PIKAnnotation_%@",aPlakatType]];
    return result;
}

- (UIImage *)annotationImage {
    UIImage *result = [UIImage imageNamed:[NSString stringWithFormat:@"PIKAnnotation_%@",self.plakatType]];
    return result;
}

- (UIImage *)pinImage {
    UIImage *result = [UIImage imageNamed:[NSString stringWithFormat:@"PIKPin_%@",self.plakatType]];
    return result;
}

- (CGPoint)pinImageCenterOffset {
    CGPoint result = CGPointMake(8, -21);
    return result;
}

- (NSString *)localizedLastModifiedDate {
    NSString *result = [[self.class dateFormatter] stringFromDate:self.lastModifiedDate];
    return result;
}

- (NSString *)localizedLastServerFetchDate {
    NSString *result = [[self.class dateFormatter] stringFromDate:self.lastServerFetchDate];
    return result;
}

- (NSString *)localizedType {
    NSString *type = self.plakatType;
    if ([type isEqualToString:PIKPlakatTypeDefault]) {
        return @"??";
    } else if ([type isEqualToString:PIKPlakatTypeOK]) {
        return @"Hängt";
    } else if ([type isEqualToString:PIKPlakatTypeA0]) {
        return @"A0 steht";
    } else if ([type isEqualToString:PIKPlakatTypeStolen]) {
        return @"Gestohlen";
    } else if ([type isEqualToString:PIKPlakatTypeNicePlace]) {
        return @"Gute Stelle";
    } else if ([type isEqualToString:PIKPlakatTypeWrecked]) {
        return @"Beschädigt";
    } else if ([type isEqualToString:PIKPlakatTypeWall]) {
        return @"Plakatwand";
    } else if ([type isEqualToString:PIKPlakatTypeWallOK]) {
        return @"Plakat an Plakatwand";
    } else {
        return type;
    }
}

- (void)setPlakatID:(uint32_t)aPlakatID {
    _plakatID = aPlakatID;
    self.locationItemIdentifier = [@(aPlakatID) stringValue];
}

- (void)updateValuesWithPlakat:(Plakat *)aPlakat {
    self.plakatID = aPlakat.id;
    self.coordinate = CLLocationCoordinate2DMake(aPlakat.lat, aPlakat.lon);
    self.plakatType = aPlakat.type;
    self.usernameOfLastChange = aPlakat.lastModifiedUser;
    self.lastModifiedDate = [NSDate dateWithTimeIntervalSince1970:aPlakat.lastModifiedTime];
    self.imageURLString = aPlakat.imageUrl;
    self.comment = aPlakat.comment;
}

@end
