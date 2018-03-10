//
//  ImageZoomView.h
//  SJPageViewDemo
//
//  Created by sadjason on 2018/03/08.
//  Copyright © 2018年 zhangbuhuai.com. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageZoomView : UIScrollView

@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, assign) BOOL hideIndicator;  // indicate ActivityIndicatorView hidden state, default is YES

@property (nonatomic, copy) void (^singleTapTriggeredBlock)(void);
@property (nonatomic, copy) void (^doubleTapTriggeredBlock)(void);

- (void)prepareForReuse;

@end

NS_ASSUME_NONNULL_END
