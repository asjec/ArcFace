//
//  AFRPerson.h
//  ARCFaceRecognizeTestbed
//
//  Created by clin on 4/1/17.
//  Copyright © 2017 ArcSoftSpotlight. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>

@class AFRCDPerson;
@interface AFRPerson : NSObject

@property (nonatomic, assign) NSUInteger Id;
@property (nonatomic, copy)   NSString   *name;
@property (nonatomic, assign) NSUInteger faceID;
@property (nonatomic, strong) NSData     *faceFeatureData;
@property (nonatomic, strong) UIImage    *faceThumb;
@property (nonatomic, assign) NSUInteger faceThumbWidth;
@property (nonatomic, assign) NSUInteger faceThumbHeight;

@property (nonatomic, assign) BOOL registered;

- (id)initWithCDPerson:(AFRCDPerson*)cdPerson;
- (void)toCDPersion:(AFRCDPerson*)cdPersson;

@end
