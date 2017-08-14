//
//  AFVideoProcessor.mm
//  ArcFace
//
//  Created by yalichen on 2017/8/1.
//  Copyright © 2017年 ArcSoft. All rights reserved.
//

#import "AFVideoProcessor.h"
#import "ammem.h"
#import "merror.h"
#import "arcsoft_fsdk_face_tracking.h"
#import "arcsoft_fsdk_face_recognition.h"
#import "arcsoft_fsdk_face_detection.h"
#import "Utility.h"
#import "AFRManager.h"

#define AFR_DEMO_APP_ID         ""
#define AFR_DEMO_SDK_FR_KEY     ""
#define AFR_DEMO_SDK_FT_KEY     ""
#define AFR_DEMO_SDK_FD_KEY     ""

#define AFR_FR_MEM_SIZE         1024*1024*40
#define AFR_FT_MEM_SIZE         1024*1024*5
#define AFR_FD_MEM_SIZE         1024*1024*5

#define AFR_FD_MAX_FACE_NUM     4

@implementation AFVideoFaceRect
@end

@interface AFVideoProcessor()
{
    MHandle          _arcsoftFD;
    MVoid*           _memBufferFD;
    
    MHandle          _arcsoftFT;
    MVoid*           _memBufferFT;
    
    MHandle          _arcsoftFR;
    MVoid*           _memBufferFR;
    
    ASVLOFFSCREEN*   _offscreenForProcess;
    dispatch_semaphore_t _processSemaphore;
}

@property (nonatomic, assign) BOOL              frModelVersionChecked;
@property (nonatomic, strong) AFRManager*       frManager;
@property (atomic, strong) AFRPerson*           frPerson;
@end

@implementation AFVideoProcessor

- (void)initProcessor
{
    // FT
    _memBufferFT = MMemAlloc(MNull,AFR_FT_MEM_SIZE);
    AFT_FSDK_InitialFaceEngine((MPChar)AFR_DEMO_APP_ID, (MPChar)AFR_DEMO_SDK_FT_KEY, (MByte*)_memBufferFT, AFR_FT_MEM_SIZE, &_arcsoftFT, AFT_FSDK_OPF_0_HIGHER_EXT, 16, AFR_FD_MAX_FACE_NUM);
    
    // FD
    _memBufferFD = MMemAlloc(MNull, AFR_FD_MEM_SIZE);
    MMemSet(_memBufferFD, 0, AFR_FD_MEM_SIZE);
    AFD_FSDK_InitialFaceEngine((MPChar)AFR_DEMO_APP_ID, (MPChar)AFR_DEMO_SDK_FD_KEY, (MByte*)_memBufferFD, AFR_FD_MEM_SIZE, &_arcsoftFD, AFD_FSDK_OPF_0_HIGHER_EXT, 16, AFR_FD_MAX_FACE_NUM);
   
    // FR
    _memBufferFR = MMemAlloc(MNull,AFR_FR_MEM_SIZE);
    AFR_FSDK_InitialEngine((MPChar)AFR_DEMO_APP_ID, (MPChar)AFR_DEMO_SDK_FR_KEY, (MByte*)_memBufferFR, AFR_FR_MEM_SIZE, &_arcsoftFR);
    
    _processSemaphore = dispatch_semaphore_create(1);
    
    self.frManager = [[AFRManager alloc] init];
}

- (void)uninitProcessor
{
    AFR_FSDK_UninitialEngine(_arcsoftFR);
    _arcsoftFR = MNull;
    if(_memBufferFR != MNull)
    {
        MMemFree(MNull,_memBufferFR);
        _memBufferFR = MNull;
    }
    
    AFT_FSDK_UninitialFaceEngine(_arcsoftFT);
    _arcsoftFT = MNull;
    if(_memBufferFT != MNull)
    {
        MMemFree(MNull, _memBufferFT);
        _memBufferFT = MNull;
    }
    
    AFD_FSDK_UninitialFaceEngine(_arcsoftFD);
    _arcsoftFD = MNull;
    if(_memBufferFD != MNull)
    {
        MMemFree(MNull, _memBufferFD);
        _memBufferFD = MNull;
    }
    
    if(0 == dispatch_semaphore_wait(_processSemaphore, 0))
    {
        [Utility freeOffscreen:_offscreenForProcess];
        _offscreenForProcess = MNull;
        
        _processSemaphore = NULL;
    }
}

- (NSArray*)process:(LPASVLOFFSCREEN)offscreen
{
    MInt32 nFaceNum = 0;
    MRECT* pRectFace = MNull;
    
    __block AFR_FSDK_FACEINPUT faceInput = {0};
    if (self.detectFaceUseFD)
    {
        LPAFD_FSDK_FACERES pFaceResFD = MNull;
        AFD_FSDK_StillImageFaceDetection(_arcsoftFD, offscreen, &pFaceResFD);
        if (pFaceResFD) {
            nFaceNum = pFaceResFD->nFace;
            pRectFace = pFaceResFD->rcFace;
        }
        
        if (nFaceNum > 0)
        {
            faceInput.rcFace = pFaceResFD->rcFace[0];
            faceInput.lOrient = pFaceResFD->lfaceOrient[0];
        }
    }
    else
    {
        LPAFT_FSDK_FACERES pFaceResFT = MNull;
        AFT_FSDK_FaceFeatureDetect(_arcsoftFT, offscreen, &pFaceResFT);
        if (pFaceResFT) {
            nFaceNum = pFaceResFT->nFace;
            pRectFace = pFaceResFT->rcFace;
        }
        
        if (nFaceNum > 0)
        {
            faceInput.rcFace = pFaceResFT->rcFace[0];
            faceInput.lOrient = pFaceResFT->lfaceOrient;
        }
    }
    
    NSMutableArray *arrayFaceRect = [NSMutableArray arrayWithCapacity:0];
    for (int face=0; face<nFaceNum; face++) {
        AFVideoFaceRect *faceRect = [[AFVideoFaceRect alloc] init];
        faceRect.faceRect = pRectFace[face];
        [arrayFaceRect addObject:faceRect];
    }
    
    //Process face recoginition in different thread for it cost a little time
    if(0 == dispatch_semaphore_wait(_processSemaphore, 0))
    {
        LPASVLOFFSCREEN pOffscreenForProcess = [self copyOffscreenForProcess:offscreen];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
            
            if(!self.frModelVersionChecked)
            {
                NSUInteger oldFRModelVersion = self.frManager.frModelVersion;
                const AFR_FSDK_Version* version = AFR_FSDK_GetVersion(_arcsoftFR);
                if(version && oldFRModelVersion != version->lFeatureLevel)
                {
                    NSArray* persons = self.frManager.allPersons;
                    for (AFRPerson *person in persons) {
                        //To do: Update person FR model data
                    }
                    [self.frManager updateAllPersonsFeatureData];
                    self.frManager.frModelVersion = version->lFeatureLevel;
                }
                
                self.frModelVersionChecked = YES;
            }
            
            if(nFaceNum > 0)
            {
                AFR_FSDK_FACEMODEL faceModel = {0};
                AFR_FSDK_ExtractFRFeature(_arcsoftFR, pOffscreenForProcess, &faceInput, &faceModel);
                
                AFRPerson* currentPerson = [[AFRPerson alloc] init];
                currentPerson.faceFeatureData = [NSData dataWithBytes:faceModel.pbFeature length:faceModel.lFeatureSize];
                
                AFR_FSDK_FACEMODEL currentFaceModel = {0};
                currentFaceModel.pbFeature = (MByte*)[currentPerson.faceFeatureData bytes];
                currentFaceModel.lFeatureSize = (MInt32)[currentPerson.faceFeatureData length];

                NSArray* persons = self.frManager.allPersons;
                NSString* recognizedName = nil;
                float maxScore = 0.0;
                for (AFRPerson* person in persons)
                {
                    AFR_FSDK_FACEMODEL refFaceModel = {0};
                    refFaceModel.pbFeature = (MByte*)[person.faceFeatureData bytes];
                    refFaceModel.lFeatureSize = (MInt32)[person.faceFeatureData length];
                    
                    MFloat fMimilScore =  0.0;
                    MRESULT mr = AFR_FSDK_FacePairMatching(_arcsoftFR, &refFaceModel, &currentFaceModel, &fMimilScore);
                    if (mr == MOK && fMimilScore >= maxScore) {
                        maxScore = fMimilScore;
                        recognizedName = person.name;
                    }
                }
                
                MFloat scoreThreshold = 0.56;
                if (maxScore > scoreThreshold) {
                    currentPerson.name = recognizedName;
                }
                
                self.frPerson = currentPerson;
            }
            else
            {
                self.frPerson = nil;
            }
        
            if(self.delegate && [self.delegate respondsToSelector:@selector(processRecognized:)])
                [self.delegate processRecognized:self.frPerson.name];

            dispatch_semaphore_signal(_processSemaphore);
        });
    }
    
    return arrayFaceRect;
}

- (BOOL)registerDetectedPerson:(NSString *)personName
{
    AFRPerson *registerPerson = self.frPerson;
    if(registerPerson == nil || registerPerson.registered)
        return NO;
    
    registerPerson.name = personName;
    registerPerson.Id = [self.frManager getNewPersonID];
    registerPerson.registered = [self.frManager addPerson:registerPerson];

    return registerPerson.registered;
}

- (LPASVLOFFSCREEN)copyOffscreenForProcess:(LPASVLOFFSCREEN)pOffscreenIn
{
    if (pOffscreenIn == MNull) {
        return  MNull;
    }
    
    if (_offscreenForProcess != NULL)
    {
        if (_offscreenForProcess->i32Width != pOffscreenIn->i32Width || _offscreenForProcess->i32Height != pOffscreenIn->i32Height || _offscreenForProcess->u32PixelArrayFormat != pOffscreenIn->u32PixelArrayFormat) {
            [Utility freeOffscreen:_offscreenForProcess];
            _offscreenForProcess = NULL;
        }
    }
    
    if (_offscreenForProcess == NULL) {
        _offscreenForProcess = [Utility createOffscreen:pOffscreenIn->i32Width  height:pOffscreenIn->i32Height format:pOffscreenIn->u32PixelArrayFormat];
    }
    
    if (ASVL_PAF_NV12 == pOffscreenIn->u32PixelArrayFormat
        || ASVL_PAF_NV21 == pOffscreenIn->u32PixelArrayFormat)
    {
        memcpy(_offscreenForProcess->ppu8Plane[0], pOffscreenIn->ppu8Plane[0], pOffscreenIn->i32Height * pOffscreenIn->pi32Pitch[0]) ;
        
        memcpy(_offscreenForProcess->ppu8Plane[1], pOffscreenIn->ppu8Plane[1], pOffscreenIn->i32Height * pOffscreenIn->pi32Pitch[1] / 2);
    }
    else if (ASVL_PAF_RGB32_R8G8B8A8 == pOffscreenIn->u32PixelArrayFormat
             || ASVL_PAF_RGB32_B8G8R8A8 == pOffscreenIn->u32PixelArrayFormat)
    {
        memcpy(_offscreenForProcess->ppu8Plane[0], pOffscreenIn->ppu8Plane[0], pOffscreenIn->i32Height * pOffscreenIn->pi32Pitch[0]) ;
        
    }
    
    return _offscreenForProcess;
}
@end
