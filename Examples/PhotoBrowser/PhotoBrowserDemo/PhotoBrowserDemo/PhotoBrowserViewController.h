//
//  PhotoBrowserViewController.h
//  SJPageViewDemo
//
//  Created by sadjason on 2018/03/08.
//  Copyright © 2018年 zhangbuhuai.com. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhotoBrowserViewController : UIViewController

@property (nonatomic, copy) NSArray<NSString *> *photos;
@property (nonatomic, assign) NSInteger selectedIndex;

@end

NS_ASSUME_NONNULL_END
