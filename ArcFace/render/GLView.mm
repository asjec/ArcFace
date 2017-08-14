//
//  GLView.m
//  OpenGLView
//
//  Created by jhzheng on 16/1/15.
//  Copyright © 2016年 jhzheng. All rights reserved.
//

#import "GLView.h"
#import "GLProgram.h"
#import "GLShader.h"

/*-------------------------------------------TextureAttr----------------------------------------*/
@interface TextureAttr : NSObject
{
@public
    int m_nWidth;
    int m_nHeight;
    GLuint m_textureID;
    NSString* m_strTextureFilePath;
}

@end

@implementation TextureAttr

-(id) init
{
    self = [super init];
    if(self)
    {
        m_nWidth = m_nHeight = 0;
        m_textureID = 0;
        m_strTextureFilePath = @"";
    }
    return self;
}

-(void) dealloc
{
    if(m_textureID != 0){
        glDeleteTextures(1, &m_textureID);
    }
}

-(BOOL) createTexture
{
    glGenTextures(1, &m_textureID);
    if(m_textureID == 0)
        return NO;
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, m_textureID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    return YES;
}

@end

/*-------------------------------------------GLView----------------------------------------*/

@interface GLView()
{
    EAGLContext *context;
    
    GLuint displayRenderbuffer;
    GLuint displayFramebuffer;

    GLProgram* pCurrentProgram;
    
    GLProgram* m_pProgramBackground;
    GLuint	m_TextureIds[2];
    GLuint	m_AttributePostion;
    GLuint	m_AttributeTextCoord;
    GLuint  m_textureUniformY;
    GLuint  m_textureUniformUV;
    GLuint  m_roiEnableUniform;
    GLuint  m_roiUniform;
    
    GLProgram* m_pProgramBackground_RGB32;
    GLuint	m_AttributePostion_RGBA32;
    GLuint	m_AttributeTextCoord_RGBA32;
    GLuint 	m_TextureInputTextureUniform;
    GLuint 	m_BgraFlagUniform;
        
    GLfloat imageVertices[8];
    
    NSMutableArray* m_vecTextureCache;// element is TextureAttr;
    
    CGSize boundsSizeAtFrameBufferEpoch;
    CGSize inputImageSize;
    AVCaptureVideoOrientation imageOrientation;
    
    CGSize sizeInPixels;
}
@end

@implementation GLView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        if([self respondsToSelector:@selector(setContentScaleFactor:)])
        {
            self.contentScaleFactor = [[UIScreen mainScreen] scale];
        }
        
        // step 1 init layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = NO;
        eaglLayer.backgroundColor=[UIColor clearColor].CGColor;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                        nil];
    
        // step2 init context
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (context == nil)
            return nil;
        
        [EAGLContext setCurrentContext:context];
        
        // Set up a few global settings for the image processing pipeline
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glEnable(GL_TEXTURE_2D);
        
        [self useAsCurrentContext];
        {
            // background Program
            {
                m_pProgramBackground = [[GLProgram alloc] initWithVertexShaderString:VertexShaderBackgroundString fragmentShaderString:FragmentShaderBackgroundString];
                if(m_pProgramBackground.initialized == NO)
                {
                    [m_pProgramBackground addAttribute:@"a_position"];
                    [m_pProgramBackground addAttribute:@"a_texCoord"];
                    [m_pProgramBackground addAttribute:@"a_weight"];
                    
                    if ([m_pProgramBackground link] == NO)
                    {
                    }
                    
                    m_AttributePostion = [m_pProgramBackground attributeIndex:@"a_position"];
                    m_AttributeTextCoord = [m_pProgramBackground attributeIndex:@"a_texCoord"];
                     m_textureUniformY = [m_pProgramBackground uniformIndex:@"y_texture"];
                    m_textureUniformUV = [m_pProgramBackground uniformIndex:@"uv_texture"];
                    m_roiUniform = [m_pProgramBackground uniformIndex:@"roi"];
                    m_roiEnableUniform = [m_pProgramBackground uniformIndex:@"roiEnable"];
                    
                    [self setCurrentProgram:m_pProgramBackground];
                    
                    glEnableVertexAttribArray(m_AttributePostion);
                    glEnableVertexAttribArray(m_AttributeTextCoord);
                 }
                
                glGenTextures(2, &m_TextureIds[0]);
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, m_TextureIds[0]);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                
                glActiveTexture(GL_TEXTURE1);
                glBindTexture(GL_TEXTURE_2D, m_TextureIds[1]);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            }
            
            // background Program rgb32
            {
                m_pProgramBackground_RGB32 = [[GLProgram alloc] initWithVertexShaderString:VertexShaderBackground_RGBA32String fragmentShaderString:FragmentShaderBackground_RGBA32String];
                if(m_pProgramBackground_RGB32.initialized == NO)
                {
                    [m_pProgramBackground_RGB32 addAttribute:@"position"];
                    [m_pProgramBackground_RGB32 addAttribute:@"inputTextureCoordinate"];
                    
                    if ([m_pProgramBackground_RGB32 link] == NO)
                    {
                    }
                    
                    m_AttributePostion_RGBA32 = [m_pProgramBackground_RGB32 attributeIndex:@"position"];
                    m_AttributeTextCoord_RGBA32 = [m_pProgramBackground_RGB32 attributeIndex:@"inputTextureCoordinate"];
                    m_TextureInputTextureUniform = [m_pProgramBackground_RGB32 uniformIndex:@"inputImageTexture"];
                    m_BgraFlagUniform = [m_pProgramBackground_RGB32 uniformIndex:@"bgraFlag"];
                    
                    [self setCurrentProgram:m_pProgramBackground_RGB32];
                    
                    glEnableVertexAttribArray(m_AttributePostion_RGBA32);
                    glEnableVertexAttribArray(m_AttributeTextCoord_RGBA32);
                }
            }
        }
        
        m_vecTextureCache = [NSMutableArray new];
    }
    
    
    return self;
}

-(void) setInputSize:(CGSize) inputSize orientation:(AVCaptureVideoOrientation) videoOrientation
{
    inputImageSize = inputSize;
    imageOrientation = videoOrientation;
    
    if(AVCaptureVideoOrientationLandscapeRight == videoOrientation || AVCaptureVideoOrientationLandscapeLeft == videoOrientation)
    {
        inputImageSize.width = inputSize.height;
        inputImageSize.height = inputSize.width;
    }
    
    [self recalculateViewGeometry];
}

- (void)recalculateViewGeometry;
{
    CGFloat heightScaling, widthScaling;
    CGSize currentViewSize = self.bounds.size;
    
    CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(inputImageSize, self.bounds);
    
    widthScaling = insetRect.size.width / currentViewSize.width;
    heightScaling = insetRect.size.height / currentViewSize.height;
    
    imageVertices[0] = -widthScaling;
    imageVertices[1] = -heightScaling;
    
    imageVertices[2] = widthScaling;
    imageVertices[3] = -heightScaling;
    
    imageVertices[4] = -widthScaling;
    imageVertices[5] = heightScaling;
    
    imageVertices[6] = widthScaling;
    imageVertices[7] = heightScaling;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // The frame buffer needs to be trashed and re-created when the view size changes.
    if (!CGSizeEqualToSize(self.bounds.size, boundsSizeAtFrameBufferEpoch)
        && !CGSizeEqualToSize(self.bounds.size, CGSizeZero))
    {
        [self destroyDisplayFramebuffer];
        [self createDisplayFramebuffer];
        [self recalculateViewGeometry];
    }
}

- (void) dealloc
{
    [self destroyDisplayFramebuffer];
    
    for(int i=0;i<2;i++)
    {
        if(m_TextureIds[i] != 0)
        {
            glDeleteTextures(1, &m_TextureIds[i]);
            m_TextureIds[i] = 0;
        }
    }
    
    [self clearAllTextureCache];
}

- (void) setCurrentProgram:(GLProgram*) program
{
    [self useAsCurrentContext];
    
    if(pCurrentProgram != program)
    {
        pCurrentProgram = program;
        [pCurrentProgram use];
    }
}

- (void) useAsCurrentContext;
{
    if ([EAGLContext currentContext] != context)
    {
        [EAGLContext setCurrentContext:context];
    }
}

-(CGSize) getSizeInPixels
{
    return sizeInPixels;
}

- (void)createDisplayFramebuffer;
{
    [self useAsCurrentContext];
    
    glGenFramebuffers(1, &displayFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
    
    // bind render buffer
    glGenRenderbuffers(1, &displayRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    
    GLint backingWidth, backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    if ( (backingWidth == 0) || (backingHeight == 0) )
    {
        [self destroyDisplayFramebuffer];
        return;
    }
    
    sizeInPixels.width = (CGFloat)backingWidth;
    sizeInPixels.height = (CGFloat)backingHeight;
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, displayRenderbuffer);
    
    // bind depth buffer
    
    glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
    
    GLuint framebufferCreationStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(framebufferCreationStatus == GL_FRAMEBUFFER_COMPLETE, @"Failure with display framebuffer generation for display of size: %f, %f", self.bounds.size.width, self.bounds.size.height);
    
    boundsSizeAtFrameBufferEpoch = self.bounds.size;
}

- (void)destroyDisplayFramebuffer;
{
    [self useAsCurrentContext];
    
    if (displayFramebuffer)
    {
        glDeleteFramebuffers(1, &displayFramebuffer);
        displayFramebuffer = 0;
    }
    
    if (displayRenderbuffer)
    {
        glDeleteRenderbuffers(1, &displayRenderbuffer);
        displayRenderbuffer = 0;
    }
}

- (void)setDisplayFramebuffer;
{
    if (displayFramebuffer == 0)
        [self createDisplayFramebuffer];
    
    glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
    glViewport(0, 0, (GLsizei)sizeInPixels.width, (GLsizei)sizeInPixels.height);
}

- (void)presentFramebuffer;
{
    glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

-(void)  clearAllTextureCache
{
    [m_vecTextureCache removeAllObjects];
}

-(TextureAttr*) findTextureAttrByImagePath:(NSString*) strImagePath
{
    for (TextureAttr* textureAttr in m_vecTextureCache)
    {
        if([textureAttr->m_strTextureFilePath isEqualToString:strImagePath])
            return textureAttr;
    }
    return nil;
}

-(void) removeTextureAttrByImagePath:(NSString*) strImagePath
{
    for (TextureAttr* textureAttr in m_vecTextureCache)
    {
        if([textureAttr->m_strTextureFilePath isEqualToString:strImagePath])
        {
            [m_vecTextureCache removeObject:textureAttr];
            break;
        }
    }
}

-(const GLfloat*) getTextureCoordinates
{
    static const GLfloat PortraitTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    static const GLfloat UpsideDwonTextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 1.0f,
    };
    static const GLfloat LandscapeRightTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };
    static const GLfloat LandscapeLeftTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };
    
    switch (imageOrientation) {
        case AVCaptureVideoOrientationPortrait:return PortraitTextureCoordinates;
        case AVCaptureVideoOrientationPortraitUpsideDown:return UpsideDwonTextureCoordinates;
        case AVCaptureVideoOrientationLandscapeRight:return LandscapeRightTextureCoordinates;
        case AVCaptureVideoOrientationLandscapeLeft:return LandscapeLeftTextureCoordinates;
    }
}

-(void) render:(int) width height:(int) height yData:(GLubyte*) yData uvData:(GLubyte*) uvData
{
    [self setDisplayFramebuffer];
        
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self drawBackTexture:width height:height yData:yData uvData:uvData];
    
    [self presentFramebuffer];
}

-(void) render:(int) width height:(int) height textureData:(GLubyte*) textureData bgra:(BOOL) bgra textureName:(NSString*) strTexturName
{
    [self setDisplayFramebuffer];
    
    glClear(GL_COLOR_BUFFER_BIT);

    [self drawBackRGB32Texture:width height:height rgbaData:textureData bgra:bgra textureName:strTexturName];
    
    [self presentFramebuffer];
}

-(void)  drawBackTexture:(int) width height:(int) height yData:(GLubyte*) yData uvData:(GLubyte*) uvData
{
    do
    {
        if (NULL == yData || NULL == uvData)
            break ;
    
        [self setCurrentProgram:m_pProgramBackground];
        
        {
            glBindTexture(GL_TEXTURE_2D, m_TextureIds[0]);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width, height,0, GL_LUMINANCE, GL_UNSIGNED_BYTE, yData);
            glBindTexture(GL_TEXTURE_2D, m_TextureIds[1]);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA,width>>1, height>>1, 0,	GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, uvData);
            
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, m_TextureIds[0]);
            glUniform1i(m_textureUniformY, 0);
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_2D, m_TextureIds[1]);
            glUniform1i(m_textureUniformUV, 1);
         }
        
        glVertexAttribPointer(m_AttributePostion, 2, GL_FLOAT, 0, 0, imageVertices);
        glVertexAttribPointer(m_AttributeTextCoord, 2, GL_FLOAT, 0, 0,[self getTextureCoordinates]);
        
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
    }while(false);
}

-(void)  drawBackRGB32Texture:(int) width height:(int) height
                     rgbaData:(GLubyte*) rgbaData
                         bgra:(BOOL) bgra
                  textureName:(NSString*) strTextureName
{
    do
    {
        if (NULL == rgbaData)
            break;
        
        [self setCurrentProgram:m_pProgramBackground_RGB32];
        
        GLuint textureID = 0;
        {
            TextureAttr* textureAttr =  [self findTextureAttrByImagePath:strTextureName];
            if(textureAttr != nil)
            {
                textureID = textureAttr->m_textureID;
            }
            else
            {
                textureAttr = [[TextureAttr alloc] init];
                if(textureAttr != nil){
                    if([textureAttr createTexture] == NO || textureAttr->m_textureID == 0){
                        textureAttr = nil;
                    }
                    else{
                        textureAttr->m_nWidth = width;
                        textureAttr->m_nHeight = height;
                        textureAttr->m_strTextureFilePath = strTextureName;
                        [m_vecTextureCache addObject:textureAttr];
                    }
                }
            }
            if(textureAttr != nil)
            {
                textureID = textureAttr->m_textureID;
                glBindTexture(GL_TEXTURE_2D,textureID);
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, (GLenum)GL_UNSIGNED_BYTE, rgbaData);
            }
        }
        
        if(bgra)
            glUniform1i(m_BgraFlagUniform, 1);
        else
            glUniform1i(m_BgraFlagUniform, 0);
        
        glActiveTexture(GL_TEXTURE5);
        glBindTexture(GL_TEXTURE_2D, textureID);
        glUniform1i(m_TextureInputTextureUniform, 5);
        
        glVertexAttribPointer(m_AttributePostion_RGBA32, 2, GL_FLOAT, 0, 0, imageVertices);
        glVertexAttribPointer(m_AttributeTextCoord_RGBA32, 2, GL_FLOAT, 0, 0,[self getTextureCoordinates]);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
    }while(false);
}

@end
