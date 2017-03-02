//
//  MCMessage.h
//  MagicCamera
//
//  Created by 郑志勤 on 2017/3/2.
//  Copyright © 2017年 zzqiltw. All rights reserved.
//

#import <TSMessages/TSMessage.h>

@interface MCMessage : TSMessage

+ (void)showSuccessWithTitle:(NSString *)message;
+ (void)showErrorWithTitle:(NSString *)message;

@end
