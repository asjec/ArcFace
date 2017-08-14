//
//  AFCameraController.m
//  ArcFace
//
//  Created by yalichen on 2017/7/31.
//  Copyright © 2017年 ArcSoft. All rights reserved.
//

#import "AFCameraController.h"
#import <AVFoundation/AVFoundation.h>
#import "amcomdef.h"

@interface AFCameraController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession    *captureSession;
    AVCaptureConnection *videoConnection;
}
@end

@implementation AFCameraController

#pragma mark capture
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (connection == videoConnection) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(captureOutput:didOutputSampleBuffer:fromConnection:)]) {
            [self.delegate captureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
        }
    }
}

#pragma mark - Setup Video Session
- (AVCaptureDevice *)videoDeviceWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
        if ([device position] == position)
            return device;
    
    return nil;
}

- (BOOL) setupCaptureSession:(AVCaptureVideoOrientation)videoOrientation
{
    captureSession = [[AVCaptureSession alloc] init];
    
    [captureSession beginConfiguration];
    
    AVCaptureDevice *videoDevice = [self videoDeviceWithPosition:AVCaptureDevicePositionFront];
    
    AVCaptureDeviceInput *videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
    if ([captureSession canAddInput:videoIn])
        [captureSession addInput:videoIn];
    
    AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    [videoOut setAlwaysDiscardsLateVideoFrames:YES];
    
#ifdef __OUTPUT_BGRA__
    NSDictionary *dic = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
#else
    NSDictionary *dic = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
#endif
    [videoOut setVideoSettings:dic];
    
    dispatch_queue_t videoCaptureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
    [videoOut setSampleBufferDelegate:self queue:videoCaptureQueue];
    
    if ([captureSession canAddOutput:videoOut])
        [captureSession addOutput:videoOut];
    videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
    
    if (videoConnection.supportsVideoMirroring) {
        [videoConnection setVideoMirrored:TRUE];
    }
    
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:videoOrientation];
    }
    
    if ([captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        [captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    
    [captureSession commitConfiguration];
    
    return YES;
}

- (void) startCaptureSession
{
    if ( !captureSession )
        return;
    
    if (!captureSession.isRunning )
        [captureSession startRunning];
}

- (void) stopCaptureSession
{
    [captureSession stopRunning];
    captureSession = nil;
}

@end
