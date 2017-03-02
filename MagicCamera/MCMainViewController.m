//
//  MCMainViewController.m
//  MagicCamera
//
//  Created by 郑志勤 on 2017/3/2.
//  Copyright © 2017年 zzqiltw. All rights reserved.
//

#import "MCMainViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define kMainScreenWidth [UIScreen mainScreen].bounds.size.width
#define kMainScreenHeight  [UIScreen mainScreen].bounds.size.height
@interface MCMainViewController ()

@property (nonatomic, strong) UIButton *selectImageButton;
@property (nonatomic, strong) UIButton *takePictureButton;
@property (nonatomic, strong) UIImageView *backgroundImageView;

/**
 *  AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
 */
@property (nonatomic, strong) AVCaptureSession* session;
/**
 *  输入设备
 */
@property (nonatomic, strong) AVCaptureDeviceInput* videoInput;
/**
 *  照片输出流
 */
@property (nonatomic, strong) AVCaptureStillImageOutput* stillImageOutput;
/**
 *  预览图层
 */
//@property (nonatomic, strong) AVCaptureVideoPreviewLayer* previewLayer;

@end

@implementation MCMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self selectImageButton];
    [self takePictureButton];
    [self backgroundImageView];
    
    [self initAVCaptureSession];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.selectImageButton.center = CGPointMake(self.view.center.x, self.view.center.y - 50);
    self.takePictureButton.center = CGPointMake(self.view.center.x, self.view.center.y + 50);
    self.backgroundImageView.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    
    if (self.session) {
        [self.session startRunning];
    }
}


- (void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:YES];
    
    if (self.session) {
        [self.session stopRunning];
    }
}

- (void)onSelectButtonClicked:(UIButton *)sender
{
    
}

- (void)onTakePictureButtonClicked:(UIButton *)sender
{
    AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];
    [stillImageConnection setVideoScaleAndCropFactor:1];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                    imageDataSampleBuffer,
                                                                    kCMAttachmentMode_ShouldPropagate);
        
        ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
        if (author == ALAuthorizationStatusRestricted || author == ALAuthorizationStatusDenied){
            //无权限
            return ;
        }
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
            
        }];
        
    }];
}

- (void)initAVCaptureSession {
    
    self.session = [[AVCaptureSession alloc] init];
    
    NSError *error;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    //设置闪光灯为自动
    [device setFlashMode:AVCaptureFlashModeAuto];
    [device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
//    //初始化预览图层
//    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
//    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
//    self.previewLayer.frame = CGRectMake(0, 0,kMainScreenWidth, kMainScreenHeight - 64);
//    [self.view.layer addSublayer:self.previewLayer];
}

-(AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft ) {
        result = AVCaptureVideoOrientationLandscapeRight;
    } else if ( deviceOrientation == UIDeviceOrientationLandscapeRight ) {
        result = AVCaptureVideoOrientationLandscapeLeft;
    }
    return result;
}


#pragma mark - LazyLoad
- (UIButton *)selectImageButton
{
    if (!_selectImageButton) {
        _selectImageButton = [[UIButton alloc] init];
        
        [_selectImageButton setTitle:@"更换背景" forState:UIControlStateNormal];
        [_selectImageButton addTarget:self action:@selector(onSelectButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_selectImageButton sizeToFit];
        
        [self.view addSubview:_selectImageButton];
    }
    
    return _selectImageButton;
}

- (UIButton *)takePictureButton
{
    if (!_takePictureButton) {
        _takePictureButton = [[UIButton alloc] init];
        
        [_takePictureButton setTitle:@"拍照" forState:UIControlStateNormal];
        [_takePictureButton addTarget:self action:@selector(onTakePictureButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_takePictureButton sizeToFit];
        
        [self.view addSubview:_takePictureButton];
    }
    return _takePictureButton;
}

- (UIImageView *)backgroundImageView
{
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        
        _backgroundImageView.image = [UIImage imageNamed:@"6"];
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        
        [self.view insertSubview:_backgroundImageView atIndex:0];
    }
    return _backgroundImageView;
}

@end
