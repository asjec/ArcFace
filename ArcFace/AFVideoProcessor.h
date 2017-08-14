//
//  AFVideoProcessor.h
//  ArcFace
//
//  Created by yalichen on 2017/8/1.
//  Copyright © 2017年 ArcSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "asvloffscreen.h"

@class AFRPerson;
@protocol AFVideoProcessorDelegate <NSObject>

- (void)processRecognized:(NSString*)personName;

@end

@interface AFVideoFaceRect : NSObject
@property(nonatomic,assign) MRECT faceRect;
@end

@interface AFVideoProcessor : NSObject

@property(atomic, assign) BOOL detectFaceUseFD;
@property(nonatomic, weak) id<AFVideoProcessorDelegate> delegate;

- (void)initProcessor;
- (void)uninitProcessor;
- (NSArray*)process:(LPASVLOFFSCREEN)offscreen;
- (BOOL)registerDetectedPerson:(NSString*)personName;

@end
