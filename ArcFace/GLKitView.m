//
//  GLKitView.m
//  OpenGLView
//
//  Created by jhzheng on 16/1/15.
//  Copyright © 2016年 jhzheng. All rights reserved.
//

#import "GLKitView.h"
#import <CoreImage/CoreImage.h>

@interface GLKitView()
{
    CIImage* displayImage;
}

@property (nonatomic , strong) CIContext *ciContext;

@end

@implementation GLKitView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

+ (EAGLContext *)sharedContext
{
    static EAGLContext *sharedContext = nil;
    if (sharedContext == nil)
    {
        sharedContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    }
    return sharedContext;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3 sharegroup:[[self class] sharedContext].sharegroup];
        self.ciContext = [CIContext contextWithEAGLContext:self.context];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3 sharegroup:[[self class] sharedContext].sharegroup];
        self.ciContext = [CIContext contextWithEAGLContext:self.context];
    }
    return self;
}

-(void) renderWithRGBA32Data:(unsigned int) nWidth height:(unsigned int) nHeight imageData:(GLbyte*) imageData format:(CIFormat) format
{

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSData* data = [NSData dataWithBytes:imageData length:nWidth * nHeight * 4];
    CIImage *image = [CIImage imageWithBitmapData:data
                                      bytesPerRow:nWidth * 4
                                             size:CGSizeMake(nWidth, nHeight)
                                           format:format
                                       colorSpace:colorSpace];
    displayImage = image;
    
    CGColorSpaceRelease(colorSpace);
    
    [self setNeedsDisplay];
    
}

-(void) renderWithTexture:(unsigned int) nTextureID width:(unsigned int) nWidth height:(unsigned int) nHeight
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CIImage *image = [CIImage imageWithTexture:nTextureID size:CGSizeMake(nWidth, nHeight) flipped:YES colorSpace:colorSpace];
    
    displayImage = image;
    
    CGColorSpaceRelease(colorSpace);
    
    [self setNeedsDisplay];
}

-(void) renderWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer orientation:(int)nOrientation mirror:(BOOL) bMirror
{
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
/*
     1
     Top, left
     2
     Top, right
     3
     Bottom, right
     4
     Bottom, left
     5
     Left, top
     6
     Right, top
     7
     Right, bottom
     8
     Left, bottom
*/
    
    if(nOrientation != 0 || bMirror == YES)
    {
        int orientation = 1;
        if(nOrientation == 90 && bMirror == YES)
            orientation = 7;
        else if(nOrientation == 90)
            orientation = 6;
        else if(bMirror == YES)
            orientation = 2;
        image = [image imageByApplyingOrientation:orientation];
    }
    
    displayImage = image;
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);    

    if (displayImage)
    {
        CGAffineTransform scale = CGAffineTransformMakeScale(self.contentScaleFactor, self.contentScaleFactor);
        CGRect rectDraw = CGRectApplyAffineTransform(self.bounds, scale);
        [self.ciContext drawImage:displayImage inRect:rectDraw fromRect:[displayImage extent]];
    }
}


@end
