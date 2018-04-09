//
//  Utility.h
//  ArcFace
//
//  Created by yalichen on 2017/7/31.
//  Copyright © 2017年 ArcSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGBase.h>
#import "asvloffscreen.h"
#import <UIKit/UIKit.h>

@interface Utility : NSObject

+ (LPASVLOFFSCREEN) createOffscreen:(MInt32) width height:( MInt32) height format:( MUInt32) format;
+ (void) freeOffscreen:(LPASVLOFFSCREEN) pOffscreen;
+ (LPASVLOFFSCREEN) createOffscreenwithUImage:(UIImage*)image;
@end
