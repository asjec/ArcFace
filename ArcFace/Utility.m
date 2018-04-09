//
//  Utility.m
//  ArcFace
//
//  Created by yalichen on 2017/7/31.
//  Copyright © 2017年 ArcSoft. All rights reserved.
//

#import "Utility.h"


@implementation Utility

+ (LPASVLOFFSCREEN) createOffscreen:(MInt32) width height:( MInt32) height format:( MUInt32) format
{
    
    ASVLOFFSCREEN* pOffscreen = MNull;
    do
    {
        pOffscreen = (ASVLOFFSCREEN*)malloc(sizeof(ASVLOFFSCREEN));
        if(!pOffscreen)
            break;
        
        memset(pOffscreen, 0, sizeof(ASVLOFFSCREEN));
        
        pOffscreen->u32PixelArrayFormat = format;
        pOffscreen->i32Width = width;
        pOffscreen->i32Height = height;
        
        if (ASVL_PAF_NV12 == format
            || ASVL_PAF_NV21 == format)
        {
            pOffscreen->pi32Pitch[0] = pOffscreen->i32Width;        //Y
            pOffscreen->pi32Pitch[1] = pOffscreen->i32Width;        //UV
            
            pOffscreen->ppu8Plane[0] = (MUInt8*)malloc(height * 3/2 * pOffscreen->pi32Pitch[0] ) ;    // Y
            pOffscreen->ppu8Plane[1] = pOffscreen->ppu8Plane[0] + pOffscreen->i32Height * pOffscreen->pi32Pitch[0]; // UV
            memset(pOffscreen->ppu8Plane[0], 0, height * 3/2 * pOffscreen->pi32Pitch[0]);
        }
        else if (ASVL_PAF_RGB32_R8G8B8A8 == format
                 || ASVL_PAF_RGB32_B8G8R8A8 == format)
        {
            pOffscreen->pi32Pitch[0] = pOffscreen->i32Width * 4;
            pOffscreen->ppu8Plane[0] = (MUInt8*)malloc(height * pOffscreen->pi32Pitch[0]);
        }
        else if (ASVL_PAF_RGB24_R8G8B8 == format
                 || ASVL_PAF_RGB24_B8G8R8 == format)
        {
            pOffscreen->pi32Pitch[0] = pOffscreen->i32Width * 3;
            pOffscreen->ppu8Plane[0] = (MUInt8*)malloc(height * pOffscreen->pi32Pitch[0]);
        }
        else if (ASVL_PAF_GRAY == format)
        {
            pOffscreen->pi32Pitch[0] = pOffscreen->i32Width;
            pOffscreen->ppu8Plane[0] = (MUInt8*)malloc(height * pOffscreen->pi32Pitch[0]);
        }
        else if (ASVL_PAF_YUYV == format)
        {
            pOffscreen->pi32Pitch[0] = pOffscreen->i32Width * 2;
            pOffscreen->ppu8Plane[0] = (MUInt8*)malloc(height * pOffscreen->pi32Pitch[0]);
        }
        
    }while(false);
    
    return pOffscreen;
}

+ (void) freeOffscreen:(LPASVLOFFSCREEN) pOffscreen
{
    if (MNull != pOffscreen)
    {
        if (MNull != pOffscreen->ppu8Plane[0])
        {
            free(pOffscreen->ppu8Plane[0]);
            pOffscreen->ppu8Plane[0] = MNull;
        }
        
        free(pOffscreen);
        pOffscreen = MNull;
    }
}

+ (LPASVLOFFSCREEN) createOffscreenwithUImage:(UIImage*)image
{
    CGImageRef imageRef = image.CGImage;
    long width = CGImageGetWidth(imageRef);
    long height = CGImageGetHeight(imageRef);
    long pitch = CGImageGetBytesPerRow(imageRef);
    long bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    int bytesPerPixel = (int)bitsPerPixel/8;
    if(bytesPerPixel < 4)
        return MNull;
    
    CFDataRef dataProvider = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    GLubyte *imageBuffer = (GLubyte *)CFDataGetBytePtr(dataProvider);
   
    LPASVLOFFSCREEN pOffscreen = [Utility createOffscreen:(MInt32)width height:(MInt32)height format:ASVL_PAF_RGB24_B8G8R8];
    MUInt32 dstPitch = pOffscreen->pi32Pitch[0];
    MUInt8* dstLine = pOffscreen->ppu8Plane[0];
    GLubyte* sourceLine = imageBuffer;
    for (int j=0; j<height; j++) {
        for (int i=0; i<width; i++) {
            dstLine[i*3] = sourceLine[i*bytesPerPixel+2];
            dstLine[i*3+1] = sourceLine[i*bytesPerPixel+1];
            dstLine[i*3+2] = sourceLine[i*bytesPerPixel];
        }
        
        sourceLine += pitch;
        dstLine += dstPitch;
    }

    CFRelease(dataProvider);
    
    return pOffscreen;
}
@end
