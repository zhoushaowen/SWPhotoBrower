//
//  SWShortTapGestureRecognizer.m
//  SWPhotoBrower
//
//  Created by zhoushaowen on 2017/11/2.
//  Copyright © 2017年 Yidu. All rights reserved.
//

#import "SWShortTapGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation SWShortTapGestureRecognizer

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.28 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(self.state != UIGestureRecognizerStateRecognized){
            self.state = UIGestureRecognizerStateFailed;
        }
    });
}

@end
