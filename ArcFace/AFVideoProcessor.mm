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
#import "Utility.h"
#import "AFRManager.h"
#import <arcsoft_fsdk_face_recognition/arcsoft_fsdk_face_recognition.h>
#import <arcsoft_fsdk_face_tracking/arcsoft_fsdk_face_tracking.h>
#import <arcsoft_fsdk_face_detection/arcsoft_fsdk_face_detection.h>
#import <arcsoft_fsdk_age_estimation/arcsoft_fsdk_age_estimation.h>
#import <arcsoft_fsdk_gender_estimation/arcsoft_fsdk_gender_estimation.h>

#define AFR_DEMO_APP_ID         ""
#define AFR_DEMO_SDK_FR_KEY     ""
#define AFR_DEMO_SDK_FT_KEY     ""
#define AFR_DEMO_SDK_FD_KEY     ""
#define AFR_DEMO_SDK_AGE_KEY    ""
#define AFR_DEMO_SDK_GENDER_KEY ""

#define AFR_FR_MEM_SIZE         1024*1024*40
#define AFR_FT_MEM_SIZE         1024*1024*5
#define AFR_FD_MEM_SIZE         1024*1024*5
#define AFR_AGE_MEM_SIZE        1024*1024*30
#define AFR_GENDER_MEM_SIZE     1024*1024*30

#define AFR_FD_MAX_FACE_NUM     4

@implementation AFVideoFaceInfo
@end

@interface AFVideoProcessor()
{
    MHandle          _arcsoftFD;
    MVoid*           _memBufferFD;
    
    MHandle          _arcsoftFT;
    MVoid*           _memBufferFT;
    
    MHandle          _arcsoftFR;
    MVoid*           _memBufferFR;
    
    MHandle          _arcsoftAge;
    MVoid*           _memBufferAge;
    
    MHandle          _arcsoftGender;
    MVoid*           _memBufferGender;
    
    ASVLOFFSCREEN*   _offscreenForProcessFR;
    dispatch_semaphore_t _processSemaphore;
    dispatch_semaphore_t _processFRSemaphore;
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
    MMemSet(_memBufferFT, 0, AFR_FT_MEM_SIZE);
    AFT_FSDK_InitialFaceEngine((MPChar)AFR_DEMO_APP_ID, (MPChar)AFR_DEMO_SDK_FT_KEY, (MByte*)_memBufferFT, AFR_FT_MEM_SIZE, &_arcsoftFT, AFT_FSDK_OPF_0_HIGHER_EXT, 16, AFR_FD_MAX_FACE_NUM);

    // FD
    _memBufferFD = MMemAlloc(MNull, AFR_FD_MEM_SIZE);
    MMemSet(_memBufferFD, 0, AFR_FD_MEM_SIZE);
    AFD_FSDK_InitialFaceEngine((MPChar)AFR_DEMO_APP_ID, (MPChar)AFR_DEMO_SDK_FD_KEY, (MByte*)_memBufferFD, AFR_FD_MEM_SIZE, &_arcsoftFD, AFD_FSDK_OPF_0_HIGHER_EXT, 16, AFR_FD_MAX_FACE_NUM);

    // FR
    _memBufferFR = MMemAlloc(MNull,AFR_FR_MEM_SIZE);
    MMemSet(_memBufferFR, 0, AFR_FR_MEM_SIZE);
    AFR_FSDK_InitialEngine((MPChar)AFR_DEMO_APP_ID, (MPChar)AFR_DEMO_SDK_FR_KEY, (MByte*)_memBufferFR, AFR_FR_MEM_SIZE, &_arcsoftFR);

    // Age
    _memBufferAge = MMemAlloc(MNull,AFR_AGE_MEM_SIZE);
    MMemSet(_memBufferAge, 0, AFR_AGE_MEM_SIZE);
    ASAE_FSDK_InitAgeEngine((MPChar)AFR_DEMO_APP_ID, (MPChar)AFR_DEMO_SDK_AGE_KEY, (MByte*)_memBufferAge, AFR_AGE_MEM_SIZE, &_arcsoftAge);

    // Gender
    _memBufferGender = MMemAlloc(MNull,AFR_GENDER_MEM_SIZE);
    MMemSet(_memBufferGender, 0, AFR_GENDER_MEM_SIZE);
    ASGE_FSDK_InitGenderEngine((MPChar)AFR_DEMO_APP_ID, (MPChar)AFR_DEMO_SDK_GENDER_KEY, (MByte*)_memBufferGender, AFR_GENDER_MEM_SIZE, &_arcsoftGender);
   
    _processSemaphore = dispatch_semaphore_create(1);
    _processFRSemaphore = dispatch_semaphore_create(1);
    
    self.frManager = [[AFRManager alloc] init];
}

- (void)uninitProcessor
{
    if(0 == dispatch_semaphore_wait(_processSemaphore, DISPATCH_TIME_FOREVER))
    {
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
        
        ASAE_FSDK_UninitAgeEngine(_arcsoftAge);
        _arcsoftAge = MNull;
        if(_memBufferAge != MNull)
        {
            MMemFree(MNull, _memBufferAge);
            _memBufferAge = MNull;
        }
        
        ASGE_FSDK_UninitGenderEngine(_arcsoftGender);
        _arcsoftGender = MNull;
        if(_memBufferGender != MNull)
        {
            MMemFree(MNull, _memBufferGender);
            _memBufferGender = MNull;
        }
        
        dispatch_semaphore_signal(_processSemaphore);
        _processSemaphore = NULL;
    }
    
    if(0 == dispatch_semaphore_wait(_processFRSemaphore, DISPATCH_TIME_FOREVER))
    {
        AFR_FSDK_UninitialEngine(_arcsoftFR);
        _arcsoftFR = MNull;
        if(_memBufferFR != MNull)
        {
            MMemFree(MNull,_memBufferFR);
            _memBufferFR = MNull;
        }
        
        [Utility freeOffscreen:_offscreenForProcessFR];
        _offscreenForProcessFR = MNull;
        
        dispatch_semaphore_signal(_processFRSemaphore);
        _processFRSemaphore = NULL;
    }
}

- (NSArray*)process:(LPASVLOFFSCREEN)offscreen
{
    NSMutableArray *arrayFaceInfo = nil;
    if(0 == dispatch_semaphore_wait(_processSemaphore, 0))
    {
        MInt32 nFaceNum = 0;
        MRECT* pRectFace = MNull;
        MInt32* pFaceOrientaion = MNull;
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
                
                pFaceOrientaion = new MInt32[nFaceNum];
                MMemCpy(pFaceOrientaion, pFaceResFD->lfaceOrient, nFaceNum*sizeof(MInt32));
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
                
                pFaceOrientaion = new MInt32[nFaceNum];
                for (int face=0; face<nFaceNum; face++) {
                    pFaceOrientaion[face] = pFaceResFT->lfaceOrient;
                }
            }
        }
        
        arrayFaceInfo = [NSMutableArray arrayWithCapacity:0];
        if(nFaceNum > 0)
        {
            ASAE_FSDK_AGEFACEINPUT ageFaceInput = {0};
            ageFaceInput.lFaceNumber = nFaceNum;
            ageFaceInput.pFaceRectArray = pRectFace;
            ageFaceInput.pFaceOrientArray = pFaceOrientaion;
            ASAE_FSDK_AGERESULT ageRes = {0};
            ASAE_FSDK_AgeEstimation_Preview(_arcsoftAge, offscreen, &ageFaceInput, &ageRes);
            
            ASGE_FSDK_GENDERFACEINPUT genderFaceInput = {0};
            genderFaceInput.lFaceNumber = nFaceNum;
            genderFaceInput.pFaceRectArray = pRectFace;
            genderFaceInput.pFaceOrientArray = pFaceOrientaion;
            ASGE_FSDK_GENDERRESULT genderRes = {0};
            ASGE_FSDK_GenderEstimation_Preview(_arcsoftGender, offscreen, &genderFaceInput, &genderRes);
            
            for (int face=0; face<nFaceNum; face++) {
                AFVideoFaceInfo *faceInfo = [[AFVideoFaceInfo alloc] init];
                faceInfo.faceRect = pRectFace[face];
                faceInfo.age = ageRes.pAgeResultArray[face];
                faceInfo.gender = genderRes.pGenderResultArray[face];
                [arrayFaceInfo addObject:faceInfo];
            }
        }
        
        if(pFaceOrientaion)
        {
            delete pFaceOrientaion;
            pFaceOrientaion = MNull;
        }
        
        dispatch_semaphore_signal(_processSemaphore);

        //Process face recoginition in different thread for it cost a little time
        if(0 == dispatch_semaphore_wait(_processFRSemaphore, 0))
        {
            __block LPASVLOFFSCREEN offscreenProcess = [self copyOffscreenForProcessFR:offscreen];
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
                    AFR_FSDK_ExtractFRFeature(_arcsoftFR, offscreenProcess, &faceInput, &faceModel);
                    
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
                
                dispatch_semaphore_signal(_processFRSemaphore);
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if(self.delegate && [self.delegate respondsToSelector:@selector(processRecognized:)])
                        [self.delegate processRecognized:self.frPerson.name];
                });
            });
        }
    }

    return arrayFaceInfo;
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

- (LPASVLOFFSCREEN)copyOffscreenForProcessFR:(LPASVLOFFSCREEN)pOffscreenIn
{
    if (pOffscreenIn == MNull) {
        return  MNull;
    }
    
    if (_offscreenForProcessFR != NULL)
    {
        if (_offscreenForProcessFR->i32Width != pOffscreenIn->i32Width || _offscreenForProcessFR->i32Height != pOffscreenIn->i32Height || _offscreenForProcessFR->u32PixelArrayFormat != pOffscreenIn->u32PixelArrayFormat) {
            [Utility freeOffscreen:_offscreenForProcessFR];
            _offscreenForProcessFR = NULL;
        }
    }
    
    if (_offscreenForProcessFR == NULL) {
        _offscreenForProcessFR = [Utility createOffscreen:pOffscreenIn->i32Width  height:pOffscreenIn->i32Height format:pOffscreenIn->u32PixelArrayFormat];
    }
    
    if (ASVL_PAF_NV12 == pOffscreenIn->u32PixelArrayFormat
        || ASVL_PAF_NV21 == pOffscreenIn->u32PixelArrayFormat)
    {
        memcpy(_offscreenForProcessFR->ppu8Plane[0], pOffscreenIn->ppu8Plane[0], pOffscreenIn->i32Height * pOffscreenIn->pi32Pitch[0]) ;
        
        memcpy(_offscreenForProcessFR->ppu8Plane[1], pOffscreenIn->ppu8Plane[1], pOffscreenIn->i32Height * pOffscreenIn->pi32Pitch[1] / 2);
    }
    else if (ASVL_PAF_RGB32_R8G8B8A8 == pOffscreenIn->u32PixelArrayFormat
             || ASVL_PAF_RGB32_B8G8R8A8 == pOffscreenIn->u32PixelArrayFormat)
    {
        memcpy(_offscreenForProcessFR->ppu8Plane[0], pOffscreenIn->ppu8Plane[0], pOffscreenIn->i32Height * pOffscreenIn->pi32Pitch[0]) ;
        
    }
    
    return _offscreenForProcessFR;
}
@end
