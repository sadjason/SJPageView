//
//  PageViewController.h.h
//  SJPageViewDemo
//
//  Created by zhangwei on 2018/03/10.
//  Copyright © 2018年 zhangbuhuai.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PageViewController : UIViewController

@end

@interface UIView (SJPageItemView)

@property (nonatomic, weak) UIViewController *sj_viewController;  // support KVO

@end

@interface UIViewController (SJPageItemViewController)

@property (nonatomic, weak) PageViewController *sj_pageViewController;  // support KVO
@property (nonatomic, assign) NSInteger sj_pageIndex;  // support KVO

@end
