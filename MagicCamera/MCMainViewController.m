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
//#import "MCActionButton.h"
#import "MCDefine.h"
#import "MCMessage.h"

static NSString * const kMCBackgroundImageStoreKey = @"kMCBackgroundImageStoreKey";

@interface MCMainViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

//@property (nonatomic, strong) MCActionButton *selectImageButton;
//@property (nonatomic, strong) MCActionButton *takePictureButton;

/**
 上半部分全是
 */
@property (nonatomic, strong) UIButton *selectImageButton;

/**
 下半部分全是
 */
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

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Life Cycle
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

    [self layoutUI];
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

#pragma mark - Actions
- (void)onSelectButtonClicked:(UIButton *)sender
{
    // 1.判断相册是否可以打开
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [MCMessage showErrorWithTitle:@"无法打开相册"];
        return;
    }
    
    // 2. 创建图片选择控制器
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    
    // 3. 设置打开照片相册类型(显示所有相簿)
    ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    // 4.设置代理
    ipc.delegate = self;
    // 5.modal出这个控制器
    [self presentViewController:ipc animated:YES completion:nil];
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
            [MCMessage showErrorWithTitle:@"拍摄失败，请检查相册权限"];
            //无权限
            return ;
        }
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
            if (!error) {
                [MCMessage showSuccessWithTitle:@"已保存到相册中"];
            } else {
                [MCMessage showErrorWithTitle:@"保存失败"];
            }
        }];
        
    }];
}

- (void)layoutUI
{
    self.selectImageButton.frame = (CGRect){{0, 0}, {kMainScreenWidth, kMainScreenHeight * 0.5}};
    self.takePictureButton.frame = (CGRect){{0, CGRectGetMaxY(self.selectImageButton.frame)}, {kMainScreenWidth, self.selectImageButton.frame.size.height}};
    self.backgroundImageView.frame = self.view.bounds;
}

- (void)initAVCaptureSession {
    
    self.session = [[AVCaptureSession alloc] init];
    
    NSError *error;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    //设置闪光灯为关闭
    [device setFlashMode:AVCaptureFlashModeOff];
    [device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
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
}

- (UIImage *)prefetchImageWithDefaultImage:(UIImage *)image
{
    NSString *imageBase64 = [[NSUserDefaults standardUserDefaults] objectForKey:kMCBackgroundImageStoreKey];
    if (imageBase64) {
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:imageBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
        if (imageData) {
            image = [UIImage imageWithData:imageData];
        }
    }
    
    return image;
}

- (void)saveImage:(UIImage *)image
{
    NSData *imageData = UIImageJPEGRepresentation(image, 1.f);
    NSString *imageBase64 = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    [[NSUserDefaults standardUserDefaults] setObject:imageBase64 forKey:kMCBackgroundImageStoreKey];
}

- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft ) {
        result = AVCaptureVideoOrientationLandscapeRight;
    } else if ( deviceOrientation == UIDeviceOrientationLandscapeRight ) {
        result = AVCaptureVideoOrientationLandscapeLeft;
    }
    return result;
}

#pragma mark -- <UIImagePickerControllerDelegate>
// 获取图片后的操作
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    // 销毁控制器
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    // 设置图片
    self.backgroundImageView.image = info[UIImagePickerControllerOriginalImage];
    
    // 持久化这个图片
    [self saveImage:info[UIImagePickerControllerOriginalImage]];
}

#pragma mark - LazyLoad
- (UIButton *)selectImageButton
{
    if (!_selectImageButton) {
        _selectImageButton = [[UIButton alloc] init];
        
//        [_selectImageButton setTitle:@"更换背景" forState:UIControlStateNormal];
//        _selectImageButton.titleLabel.font = [UIFont systemFontOfSize:15];
//        [_selectImageButton setTitleColor:ZQColor(61, 186, 188, 1) forState:UIControlStateNormal];
        [_selectImageButton addTarget:self action:@selector(onSelectButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
//        [_selectImageButton sizeToFit];
        
        [self.view addSubview:_selectImageButton];
    }
    
    return _selectImageButton;
}

- (UIButton *)takePictureButton
{
    if (!_takePictureButton) {
        _takePictureButton = [[UIButton alloc] init];
        
//        [_takePictureButton setTitle:@"拍照" forState:UIControlStateNormal];
//        _takePictureButton.titleLabel.font = [UIFont systemFontOfSize:15];
//        [_takePictureButton setTitleColor:ZQColor(61, 186, 188, 1) forState:UIControlStateNormal];
        [_takePictureButton addTarget:self action:@selector(onTakePictureButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
//        [_takePictureButton sizeToFit];
        
        [self.view addSubview:_takePictureButton];
    }
    return _takePictureButton;
}

- (UIImageView *)backgroundImageView
{
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        
        UIImage *image = [self prefetchImageWithDefaultImage:[UIImage imageNamed:@"Background"]];
        
        _backgroundImageView.image = image;
        
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        
        [self.view insertSubview:_backgroundImageView atIndex:0];
    }
    return _backgroundImageView;
}



@end
