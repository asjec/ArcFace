//
//  Utility.m
//  ArcFace
//
//  Created by yalichen on 2017/7/31.
//  Copyright © 2017年 ArcSoft. All rights reserved.
//

#import "Utility.h"


@implementation Utility

+ (void)CalcFitOutSize:(CGFloat)nOldW oldH:(CGFloat)nOldH newW:(CGFloat*)nW newH:(CGFloat*)nH
{
    if (!nOldW || !nOldH || !nW || !nH || !(*nW) || !(*nH))
    {
        *nW = 0;
        *nH = 0;
        return;
    }
    
    if(nOldW * (*nH) > nOldH * (*nW))
        *nW = round((nOldW * (*nH))/nOldH);
    else
        *nH = round((nOldH * (*nW))/nOldW);
    
    *nW = MAX(1, *nW);
    *nH = MAX(1, *nH);
}

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
            
            pOffscreen->ppu8Plane[0] = (MUInt8*)malloc(height * pOffscreen->pi32Pitch[0] ) ;    // Y
            memset(pOffscreen->ppu8Plane[0], 0, height * pOffscreen->pi32Pitch[0]);
            
            pOffscreen->ppu8Plane[1] = (MUInt8*)malloc(height / 2 * pOffscreen->pi32Pitch[1]);  // UV
            memset(pOffscreen->ppu8Plane[1], 0, height * pOffscreen->pi32Pitch[0] / 2);
        }
        else if (ASVL_PAF_RGB32_R8G8B8A8 == format
                 || ASVL_PAF_RGB32_B8G8R8A8 == format)
        {
            pOffscreen->pi32Pitch[0] = pOffscreen->i32Width * 4;
            pOffscreen->ppu8Plane[0] = (MUInt8*)malloc(height * pOffscreen->pi32Pitch[0]);
        }
        else if (ASVL_PAF_RGB24_R8G8B8 == format)
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
        
        if (MNull != pOffscreen->ppu8Plane[1])
        {
            free(pOffscreen->ppu8Plane[1]);
            pOffscreen->ppu8Plane[1] = MNull;
        }
        
        if (MNull != pOffscreen->ppu8Plane[2])
        {
            free(pOffscreen->ppu8Plane[2]);
            pOffscreen->ppu8Plane[2] = MNull;
        }
        
        free(pOffscreen);
        pOffscreen = MNull;
    }
}

@end
