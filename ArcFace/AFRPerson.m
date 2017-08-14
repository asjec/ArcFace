//
//  AFRPerson.m
//  ARCFaceRecognizeTestbed
//
//  Created by clin on 4/1/17.
//  Copyright © 2017 ArcSoftSpotlight. All rights reserved.
//

#import "AFRPerson.h"
#import "AFRCDPerson+CoreDataClass.h"

@implementation AFRPerson

-(id)initWithCDPerson:(AFRCDPerson *)cdPerson
{
    if (self = [super init]) {
        _Id = cdPerson.personID;
        _name = cdPerson.name;
        _faceID = cdPerson.faceID;
        _faceFeatureData = cdPerson.faceFeatureData;
        _faceThumb = [UIImage imageWithData:cdPerson.faceThumb];
        _faceThumbWidth = cdPerson.faceThumbWidth;
        _faceThumbHeight = cdPerson.faceThumbHeight;
    }
    
    return self;
}

- (void)toCDPersion:(AFRCDPerson*)cdPersson
{
    cdPersson.personID = (int32_t)_Id;
    cdPersson.name = _name;
    cdPersson.faceID = (int32_t)_faceID;
    cdPersson.faceThumb = UIImageJPEGRepresentation(_faceThumb, 0.9);
    cdPersson.faceThumbWidth = (int32_t)_faceThumbWidth;
    cdPersson.faceThumbHeight = (int32_t)_faceThumbHeight;
    cdPersson.faceFeatureData = _faceFeatureData;
}

@end
