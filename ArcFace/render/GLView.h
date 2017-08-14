//
//  GLView.h
//  OpenGLView
//
//  Created by jhzheng on 16/1/15.
//  Copyright © 2016年 jhzheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <AVFoundation/AVFoundation.h>


@interface GLView : UIView

-(CGSize) getSizeInPixels;

-(void) setInputSize:(CGSize) inputSize orientation:(AVCaptureVideoOrientation) videoOrientation;
-(void) render:(int) width height:(int) height yData:(GLubyte*) yData uvData:(GLubyte*) uvData;
-(void) render:(int) width height:(int) height textureData:(GLubyte*) textureData bgra:(BOOL) bgra textureName:(NSString*) strTexturName;

-(void) clearAllTextureCache;

@end
