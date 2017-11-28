//
//  ViewController.m
//  ArcFace
//
//  Created by yalichen on 2017/7/31.
//  Copyright © 2017年 ArcSoft. All rights reserved.
//

#import "ViewController.h"
#import "AFCameraController.h"
#import "GLView.h"
#import "Utility.h"
#import "asvloffscreen.h"
#import "AFVideoProcessor.h"

#define IMAGE_WIDTH     720
#define IMAGE_HEIGHT    1280

@interface ViewController ()<AFCameraControllerDelegate, AFVideoProcessorDelegate>
{
    ASVLOFFSCREEN*   _offscreenIn;
}

@property (nonatomic, strong) AFCameraController* cameraController;
@property (nonatomic, strong) AFVideoProcessor* videoProcessor;
@property (nonatomic, strong) NSMutableArray* arrayAllFaceRectView;

@property (weak, nonatomic) IBOutlet GLView *glView;
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UISwitch *switchDetectByFD;

- (IBAction)btnRegisterClicked:(id)sender;
- (IBAction)switchDetectByFDChanged:(id)sender;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIInterfaceOrientation uiOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)uiOrientation;
    
    CGSize sizeTemp = CGSizeZero;
    if(uiOrientation == UIInterfaceOrientationPortrait || uiOrientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        sizeTemp.width = MIN(IMAGE_WIDTH, IMAGE_HEIGHT);
        sizeTemp.height = MAX(IMAGE_WIDTH, IMAGE_HEIGHT);
    }
    else
    {
        sizeTemp.width = MAX(IMAGE_WIDTH, IMAGE_HEIGHT);
        sizeTemp.height = MIN(IMAGE_WIDTH, IMAGE_HEIGHT);
    }
    CGFloat fWidth = self.view.bounds.size.width;
    CGFloat fHeight = self.view.bounds.size.height;
    [Utility CalcFitOutSize:sizeTemp.width oldH:sizeTemp.height newW:&fWidth newH:&fHeight];
    self.glView.frame = CGRectMake((self.view.bounds.size.width-fWidth)/2,(self.view.bounds.size.width-fWidth)/2,fWidth,fHeight);
    [self.glView setInputSize:sizeTemp orientation:videoOrientation];
    
    self.switchDetectByFD.on = NO;
    self.arrayAllFaceRectView = [NSMutableArray arrayWithCapacity:0];

    // Start camera
    self.cameraController = [[AFCameraController alloc]init];
    self.cameraController.delegate = self;
    [self.cameraController setupCaptureSession:videoOrientation];
    [self.cameraController startCaptureSession];
    
    // Video processor
    self.videoProcessor = [[AFVideoProcessor alloc] init];
    self.videoProcessor.delegate = self;
    [self.videoProcessor initProcessor];
}

- (void)dealloc
{
    [self.cameraController stopCaptureSession];
    [self.videoProcessor uninitProcessor];
    
    [Utility freeOffscreen:_offscreenIn];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnRegisterClicked:(id)sender {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Register" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UITextField* nameText = alertController.textFields.firstObject;
        NSString* name = nameText.text;
        if (name != NULL && name.length > 1) {
            if([self.videoProcessor registerDetectedPerson:name])
            {
                UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Register succeed" message:@"" preferredStyle:UIAlertControllerStyleAlert];
                [self presentViewController:alertController animated:YES completion:nil];
                NSTimer *timer = [NSTimer timerWithTimeInterval:5 target:self selector:@selector(timerHideAlertViewController:) userInfo:alertController repeats:NO];
                [timer fire];
            }
        }
    }];
    [alertController addAction:okAction];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"name";
    }];
    
    [self presentViewController:alertController animated:YES completion:^{}];
}

- (void)timerHideAlertViewController:(id)sender {
    NSTimer *timer = (NSTimer*)sender;
    UIAlertController *alertViewController = (UIAlertController*)timer.userInfo;
    [alertViewController dismissViewControllerAnimated:YES completion:nil];
    alertViewController = nil;
}

- (IBAction)switchDetectByFDChanged:(id)sender {
    self.videoProcessor.detectFaceUseFD = self.switchDetectByFD.isOn;
}

#pragma mark - AFCameraControllerDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (UIApplicationStateActive != [UIApplication sharedApplication].applicationState) {
        return; // OPENGL ES commands could not be excuted in background
    }
    
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = (int) CVPixelBufferGetWidth(cameraFrame);
    int bufferHeight = (int) CVPixelBufferGetHeight(cameraFrame);
    LPASVLOFFSCREEN pOffscreenIn = [self offscreenFromSampleBuffer:sampleBuffer];
    NSArray *arrayFaceInfo = [self.videoProcessor process:pOffscreenIn];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        if (ASVL_PAF_RGB32_B8G8R8A8 == pOffscreenIn->u32PixelArrayFormat || ASVL_PAF_RGB32_R8G8B8A8 == pOffscreenIn->u32PixelArrayFormat)
        {
            [self.glView render:bufferWidth height:bufferHeight textureData:(GLubyte*) pOffscreenIn->ppu8Plane[0] bgra:(ASVL_PAF_RGB32_B8G8R8A8 == pOffscreenIn->u32PixelArrayFormat) textureName:@"BACKGROUND_TEXTURE"];
        }
        else if (ASVL_PAF_NV12 == pOffscreenIn->u32PixelArrayFormat)
        {
            [self.glView render:bufferWidth height:bufferHeight yData:pOffscreenIn->ppu8Plane[0] uvData:pOffscreenIn->ppu8Plane[1]];
        }
        
        if(self.arrayAllFaceRectView.count >= arrayFaceInfo.count)
        {
            for (NSUInteger face=arrayFaceInfo.count; face<self.arrayAllFaceRectView.count; face++) {
                UIView *faceRectView = [self.arrayAllFaceRectView objectAtIndex:face];
                faceRectView.hidden = YES;
            }
        }
        else
        {
            for (NSUInteger face=self.arrayAllFaceRectView.count; face<arrayFaceInfo.count; face++) {
                UIStoryboard *faceRectStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                UIView *faceRectView = [faceRectStoryboard instantiateViewControllerWithIdentifier:@"FaceRectVideoController"].view;
                [self.view addSubview:faceRectView];
                [self.arrayAllFaceRectView addObject:faceRectView];
            }
        }
        
        for (NSUInteger face=0; face<arrayFaceInfo.count; face++) {
            UIView *faceRectView = [self.arrayAllFaceRectView objectAtIndex:face];
            AFVideoFaceInfo *faceInfo = [arrayFaceInfo objectAtIndex:face];
            faceRectView.hidden = NO;
            faceRectView.frame = [self dataFaceRect2ViewFaceRect:faceInfo.faceRect];
            
            UILabel* labelInfo = (UILabel*)[faceRectView viewWithTag:1];
            labelInfo.text = [NSString stringWithFormat:@"age:%d gender:%d", faceInfo.age, faceInfo.gender];
        }
    });
}

#pragma mark - AFVideoProcessorDelegate
- (void)processRecognized:(NSString *)personName
{
    self.labelName.text = personName;
}

#pragma mark - Private Methods
- (LPASVLOFFSCREEN)offscreenFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (NULL == sampleBuffer)
        return NULL;
    
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = (int) CVPixelBufferGetWidth(cameraFrame);
    int bufferHeight = (int) CVPixelBufferGetHeight(cameraFrame);
    OSType pixelType =  CVPixelBufferGetPixelFormatType(cameraFrame);
    
    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    
    if (kCVPixelFormatType_32BGRA == pixelType)
    {
        if (_offscreenIn != NULL)
        {
            if (_offscreenIn->i32Width != bufferWidth || _offscreenIn->i32Height != bufferHeight || ASVL_PAF_RGB32_B8G8R8A8 != _offscreenIn->u32PixelArrayFormat) {
                [Utility freeOffscreen:_offscreenIn];
                _offscreenIn = NULL;
            }
        }
        
        if (_offscreenIn == NULL) {
            _offscreenIn = [Utility createOffscreen:bufferWidth height:bufferHeight format:ASVL_PAF_RGB32_B8G8R8A8];
        }
        
        ASVLOFFSCREEN* pOff = _offscreenIn;
        
        size_t   rowBytePlane0 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 0);
        uint8_t  *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(cameraFrame);
        
        
        if (rowBytePlane0 == pOff->pi32Pitch[0])
        {
            memcpy(pOff->ppu8Plane[0], baseAddress, bufferHeight * pOff->pi32Pitch[0]);
        }
        else
        {
            for (int i = 0; i < bufferHeight; ++i) {
                memcpy(pOff->ppu8Plane[0] + i * pOff->pi32Pitch[0] , baseAddress + i * rowBytePlane0, pOff->pi32Pitch[0] );
            }
        }
    }
    else if (kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange == pixelType
             || kCVPixelFormatType_420YpCbCr8BiPlanarFullRange == pixelType) // NV12
    {
        if (_offscreenIn != NULL)
        {
            if (_offscreenIn->i32Width != bufferWidth || _offscreenIn->i32Height != bufferHeight || ASVL_PAF_NV12 != _offscreenIn->u32PixelArrayFormat) {
                [Utility freeOffscreen:_offscreenIn];
                _offscreenIn = NULL;
            }
        }
        
        if (_offscreenIn == NULL) {
            _offscreenIn = [Utility createOffscreen:bufferWidth height:bufferHeight format:ASVL_PAF_NV12];
        }
        
        ASVLOFFSCREEN* pOff = _offscreenIn;
        
        uint8_t  *baseAddress0 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 0); // Y
        uint8_t  *baseAddress1 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 1); // UV
        
        size_t   rowBytePlane0 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 0);
        size_t   rowBytePlane1 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 1);
        
        // YData
        if (rowBytePlane0 == pOff->pi32Pitch[0])
        {
            memcpy(pOff->ppu8Plane[0], baseAddress0, rowBytePlane0*bufferHeight);
        }
        else
        {
            for (int i = 0; i < bufferHeight; ++i) {
                memcpy(pOff->ppu8Plane[0] + i * bufferWidth, baseAddress0 + i * rowBytePlane0, bufferWidth);
            }
        }
        // uv data
        if (rowBytePlane1 == pOff->pi32Pitch[1])
        {
            memcpy(pOff->ppu8Plane[1], baseAddress1, rowBytePlane1 * bufferHeight / 2);
        }
        else
        {
            uint8_t  *pPlanUV = pOff->ppu8Plane[1];
            for (int i = 0; i < bufferHeight / 2; ++i) {
                memcpy(pPlanUV + i * bufferWidth, baseAddress1+ i * rowBytePlane1, bufferWidth);
            }
        }
    }
    
    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
    
    return _offscreenIn;
}

- (CGRect)dataFaceRect2ViewFaceRect:(MRECT)faceRect
{
    CGRect frameFaceRect = {0};
    CGRect frameGLView = self.glView.frame;
    frameFaceRect.size.width = CGRectGetWidth(frameGLView)*(faceRect.right-faceRect.left)/IMAGE_WIDTH;
    frameFaceRect.size.height = CGRectGetHeight(frameGLView)*(faceRect.bottom-faceRect.top)/IMAGE_HEIGHT;
    frameFaceRect.origin.x = CGRectGetWidth(frameGLView)*faceRect.left/IMAGE_WIDTH;
    frameFaceRect.origin.y = CGRectGetHeight(frameGLView)*faceRect.top/IMAGE_HEIGHT;
    
    return frameFaceRect;
}
@end
