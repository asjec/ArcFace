//
//  StaticImageViewController.m
//  ArcFace
//
//  Created by yalichen on 2018/2/5.
//  Copyright © 2018年 ArcSoft. All rights reserved.
//

#import "StaticImageViewController.h"
#import "Utility.h"
#import "asvloffscreen.h"
#import "ammem.h"
#import <Photos/Photos.h>
#import <arcsoft_fsdk_face_detection/arcsoft_fsdk_face_detection.h>

#define AFR_DEMO_APP_ID         ""
#define AFR_DEMO_SDK_FD_KEY     ""

#define AFR_FD_MEM_SIZE         1024*1024*50
#define AFR_FD_MAX_FACE_NUM     4

@interface AFFaceInfo : NSObject
@property(nonatomic,assign) MRECT faceRect;
@end

@implementation AFFaceInfo
@end

@interface StaticImageViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    MHandle          _arcsoftFD;
    MVoid*           _memBufferFD;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *btnPhotos;

@property (nonatomic, strong) NSMutableArray* arrayAllFaceRectView;
@end

@implementation StaticImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus phstatus) {
        NSLog(@"PHAuthorizationStatus = %d", (int)phstatus);
    }];
    
    // FD
    _memBufferFD = MMemAlloc(MNull, AFR_FD_MEM_SIZE);
    MMemSet(_memBufferFD, 0, AFR_FD_MEM_SIZE);
    AFD_FSDK_InitialFaceEngine((MPChar)AFR_DEMO_APP_ID, (MPChar)AFR_DEMO_SDK_FD_KEY, (MByte*)_memBufferFD, AFR_FD_MEM_SIZE, &_arcsoftFD, AFD_FSDK_OPF_0_HIGHER_EXT, 16, AFR_FD_MAX_FACE_NUM);
    
    self.arrayAllFaceRectView = [NSMutableArray arrayWithCapacity:0];
}

- (void)dealloc {
    AFD_FSDK_UninitialFaceEngine(_arcsoftFD);
    _arcsoftFD = MNull;
    if(_memBufferFD != MNull)
    {
        MMemFree(MNull, _memBufferFD);
        _memBufferFD = MNull;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnPhotosClicked:(id)sender {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (IBAction)btnBackClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:^{
    }];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.imageView.image = image;
    self.btnPhotos.enabled = NO;
    for (NSUInteger face=0; face<self.arrayAllFaceRectView.count; face++) {
        UIView *faceRectView = [self.arrayAllFaceRectView objectAtIndex:face];
        faceRectView.hidden = YES;
    }

    __weak id weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^(){
        LPASVLOFFSCREEN pOffscreen = [Utility createOffscreenwithUImage:image];
        
        LPAFD_FSDK_FACERES pFaceResFD = MNull;
        AFD_FSDK_StillImageFaceDetection(_arcsoftFD, pOffscreen, &pFaceResFD);
        
        NSMutableArray *arrayFaceInfo = [NSMutableArray arrayWithCapacity:0];
        if(pFaceResFD && pFaceResFD->nFace > 0) {
            for (int face=0; face<pFaceResFD->nFace; face++) {
                AFFaceInfo *faceInfo = [[AFFaceInfo alloc] init];
                faceInfo.faceRect = pFaceResFD->rcFace[face];
                [arrayFaceInfo addObject:faceInfo];
            }
        }

        [Utility freeOffscreen:pOffscreen];
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            if(weakSelf)
            {
                self.btnPhotos.enabled = YES;
                
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
                        
                        UILabel* labelInfo = (UILabel*)[faceRectView viewWithTag:1];
                        labelInfo.hidden = YES;
                    }
                }
                
                for (NSUInteger face=0; face<arrayFaceInfo.count; face++) {
                    UIView *faceRectView = [self.arrayAllFaceRectView objectAtIndex:face];
                    AFFaceInfo *faceInfo = [arrayFaceInfo objectAtIndex:face];
                    faceRectView.hidden = NO;
                    faceRectView.frame = [self dataFaceRect2ViewFaceRect:faceInfo.faceRect];
                }
            }
        });
    });
}

- (CGRect)dataFaceRect2ViewFaceRect:(MRECT)faceRect
{
    CGRect frameFaceRect = {0};
    CGRect imageDisplayRect = self.imageView.bounds;
    CGSize imageSize = self.imageView.image.size;
    if(imageSize.width*CGRectGetHeight(self.imageView.bounds) > imageSize.height*CGRectGetWidth(self.imageView.bounds))
    {
        imageDisplayRect.size.height = imageSize.height*CGRectGetWidth(self.imageView.bounds)/imageSize.width;
        imageDisplayRect.origin.y = (CGRectGetHeight(self.imageView.bounds)-imageDisplayRect.size.height)/2;
    }
    else
    {
        imageDisplayRect.size.width = imageSize.width*CGRectGetHeight(self.imageView.bounds)/imageSize.height;
        imageDisplayRect.origin.x = (CGRectGetWidth(self.imageView.bounds)-imageDisplayRect.size.width)/2;
    }
    
    MRECT faceRectInImage = faceRect;
    UIImageOrientation imageOrientation = self.imageView.image.imageOrientation;
    switch (imageOrientation) {
        case UIImageOrientationRight:
        {
            faceRectInImage.left = imageSize.width-faceRect.bottom;
            faceRectInImage.right = imageSize.width-faceRect.top;
            faceRectInImage.top = faceRect.left;
            faceRectInImage.bottom = faceRect.right;
        }
            break;
        case UIImageOrientationLeft:
        {
            faceRectInImage.left = faceRect.top;
            faceRectInImage.right = faceRect.bottom;
            faceRectInImage.top = imageSize.height-faceRect.right;
            faceRectInImage.bottom = imageSize.height-faceRect.left;
        }
            break;
        case UIImageOrientationDown:
        {
            faceRectInImage.left = imageSize.width-faceRect.right;
            faceRectInImage.right = imageSize.width-faceRect.left;
            faceRectInImage.top = imageSize.height-faceRect.bottom;
            faceRectInImage.bottom = imageSize.height-faceRect.top;
        }
            break;
        default:
            break;
    }
    
    frameFaceRect.size.width = CGRectGetWidth(imageDisplayRect)*(faceRectInImage.right-faceRectInImage.left)/imageSize.width;
    frameFaceRect.size.height = CGRectGetHeight(imageDisplayRect)*(faceRectInImage.bottom-faceRectInImage.top)/imageSize.height;
    frameFaceRect.origin.x = imageDisplayRect.origin.x+CGRectGetWidth(imageDisplayRect)*faceRectInImage.left/imageSize.width;
    frameFaceRect.origin.y = imageDisplayRect.origin.y+CGRectGetHeight(imageDisplayRect)*faceRectInImage.top/imageSize.height;
    return frameFaceRect;
}
@end
