//
//  AFRCDPerson+CoreDataProperties.h
//  
//
//  Created by yalichen on 17/5/3.
//
//  This file was automatically generated and should not be edited.
//

#import "AFRCDPerson+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface AFRCDPerson (CoreDataProperties)

+ (NSFetchRequest<AFRCDPerson *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSData *faceFeatureData;
@property (nonatomic) int32_t faceID;
@property (nullable, nonatomic, retain) NSData *faceThumb;
@property (nonatomic) int32_t faceThumbHeight;
@property (nonatomic) int32_t faceThumbWidth;
@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic) int32_t personID;

@end

NS_ASSUME_NONNULL_END
