//
//  PhotoBrowserViewController.m
//  SJPageViewDemo
//
//  Created by sadjason on 2018/03/08.
//  Copyright © 2018年 zhangbuhuai.com. All rights reserved.
//

#import "PhotoBrowserViewController.h"
#import "ImageZoomView.h"
#import "SJPageView.h"

@interface PhotoBrowserViewController () <SJPageViewDataSource, SJPageViewDelegate>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) SJPageView *pageView;

@end

static void *kPageViewCurrentItemIndexContext = &kPageViewCurrentItemIndexContext;

@implementation PhotoBrowserViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    self.pageView = [[SJPageView alloc] initWithFrame:self.view.bounds];
    self.pageView.dataSource = self;
    self.pageView.delegate = self;
    [self.pageView scrollToPageOffset:self.selectedIndex animated:NO];
    [self.view addSubview:self.pageView];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 44)];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont systemFontOfSize:16.0];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];
    
    [self.pageView addObserver:self
                    forKeyPath:@"currentItemIndex"
                       options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                       context:kPageViewCurrentItemIndexContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == kPageViewCurrentItemIndexContext) {
        self.titleLabel.text = [NSString stringWithFormat:@"%@/%@", @(self.pageView.currentItemIndex+1), @(self.photos.count)];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc
{
    [_pageView removeObserver:self forKeyPath:@"currentItemIndex" context:kPageViewCurrentItemIndexContext];
}

#pragma mark - SJPageViewDataSource

- (NSInteger)numberOfItemsInPageView:(SJPageView *)pageView
{
    return self.photos.count;
}

- (UIView *)itemViewAtIndex:(NSInteger)index inPageView:(SJPageView *)pageView
{
    ImageZoomView *imageView = [[ImageZoomView alloc] init];
    imageView.backgroundColor = [UIColor blackColor];
    imageView.imageView.image = [UIImage imageNamed:self.photos[index]];
    __weak typeof(self) weakSelf = self;
    imageView.singleTapTriggeredBlock = ^{
        typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf dismissViewControllerAnimated:NO completion:nil];
    };
    return imageView;
}

@end
