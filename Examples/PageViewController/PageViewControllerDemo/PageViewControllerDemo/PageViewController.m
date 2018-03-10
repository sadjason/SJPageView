//
//  PageViewController.h.m
//  SJPageViewDemo
//
//  Created by zhangwei on 2018/03/10.
//  Copyright © 2018年 zhangbuhuai.com. All rights reserved.
//

#import "PageViewController.h"
#import "PageItemViewController.h"
#import "SJPageView.h"
#import "WeakAssociatedObjectWrapper.h"
#import <objc/runtime.h>

static void *kSJViewControllerKey = &kSJViewControllerKey;

@implementation UIView (SJPageItemView)

- (void)setSj_viewController:(UIViewController *)sj_viewController
{
    [self willChangeValueForKey:@"sj_viewController"];
    WeakAssociatedObjectWrapper *wrapper = [WeakAssociatedObjectWrapper wrapperWithObject:sj_viewController];
    objc_setAssociatedObject(self, kSJViewControllerKey, wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"sj_viewController"];
}

- (UIViewController *)sj_viewController
{
    return ((WeakAssociatedObjectWrapper *)objc_getAssociatedObject(self, kSJViewControllerKey)).object;
}

@end

static void *kSJPageViewControllerKey = &kSJPageViewControllerKey;
static void *kSJPageIndexKey = &kSJPageIndexKey;

@implementation UIViewController (SJPageItemViewController)

- (void)setSj_pageViewController:(PageViewController *)sj_pageViewController
{
    [self willChangeValueForKey:@"sj_pageViewController"];
    WeakAssociatedObjectWrapper *wrapper = [WeakAssociatedObjectWrapper wrapperWithObject:sj_pageViewController];
    objc_setAssociatedObject(self, kSJPageViewControllerKey, wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"sj_pageViewController"];
}

- (PageViewController *)sj_pageViewController
{
    return ((WeakAssociatedObjectWrapper *)objc_getAssociatedObject(self, kSJPageViewControllerKey)).object;
}

- (void)setSj_pageIndex:(NSInteger)sj_pageIndex
{
    [self willChangeValueForKey:@"sj_pageIndex"];
    objc_setAssociatedObject(self, kSJPageIndexKey, @(sj_pageIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"sj_pageIndex"];
}

- (NSInteger)sj_pageIndex
{
    NSNumber *number = objc_getAssociatedObject(self, kSJPageIndexKey);
    return number ? number.integerValue : -1;
}

@end

@interface UIViewController (SJPageViewContontrollerPrivate)

@property (nonatomic, assign) BOOL sj_didMoveToPageViewController;

@end

static void *kSJDidMoveToPageViewController = &kSJDidMoveToPageViewController;

@implementation UIViewController (SJPageViewContontrollerPrivate)

- (void)setSj_didMoveToPageViewController:(BOOL)sj_didMoveToPageViewController
{
    objc_setAssociatedObject(self, kSJDidMoveToPageViewController, @(sj_didMoveToPageViewController), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)sj_didMoveToPageViewController
{
    NSNumber *number = objc_getAssociatedObject(self, kSJDidMoveToPageViewController);
    return number ? number.boolValue : false;
}

@end

/****************************************************************************************************/

@interface PageViewController () <SJPageViewDataSource, SJPageViewDelegate>

@property (nonatomic, strong) SJPageView *pageView;
@property (nonatomic, copy) NSMutableSet<PageItemViewController *> *spareVCs;

@end

@implementation PageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    SJPageView *pageView = [[SJPageView alloc] initWithFrame:self.view.bounds];
    pageView.pageGap = 0.0;
    pageView.dataSource = self;
    pageView.delegate = self;
    pageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    self.pageView = pageView;
    [self.view addSubview:self.pageView];
}

#pragma mark - SJPageViewDataSource

- (NSInteger)numberOfItemsInPageView:(SJPageView *)pageView
{
    return 20;
}

- (UIView *)itemViewAtIndex:(NSInteger)index inPageView:(SJPageView *)pageView
{
    PageItemViewController *itemVC = [self.spareVCs anyObject];
    if (!itemVC) {
        itemVC = [[PageItemViewController alloc] init];
    } else {
        [self.spareVCs removeObject:itemVC];
    }
    itemVC.content = [@(index) stringValue];
    itemVC.sj_pageIndex = index;
    itemVC.view.sj_viewController = itemVC;
    return itemVC.view;
}

#pragma mark - SJPageViewDelegate

- (void)pageView:(SJPageView *)pageView willLoadItemView:(nonnull UIView *)view atIndex:(NSInteger)index
{
    if (view.sj_viewController && ![self.childViewControllers containsObject:view.sj_viewController]) {
        [self addChildViewController:view.sj_viewController];
        view.sj_viewController.sj_didMoveToPageViewController = NO;
    }
    view.sj_viewController.sj_pageViewController = self;
    view.sj_viewController.sj_pageIndex = index;
    if (index % 3 == 0) {
        view.backgroundColor = [UIColor redColor];
    } else if (index % 3 == 1) {
        view.backgroundColor = [UIColor greenColor];
    } else {
        view.backgroundColor = [UIColor blueColor];
    }
}

- (void)pageView:(SJPageView *)pageView didLoadItemView:(nonnull UIView *)view atIndex:(NSInteger)index
{
    if (view.sj_viewController && !view.sj_viewController.sj_didMoveToPageViewController) {
        [view.sj_viewController didMoveToParentViewController:self];
    }
}

- (void)pageView:(SJPageView *)pageView didUnloadItemView:(UIView *)itemView
{
    if ([itemView.sj_viewController isKindOfClass:PageItemViewController.class]) {
        itemView.sj_viewController.sj_pageViewController = nil;
        [self.spareVCs addObject:(PageItemViewController *)itemView.sj_viewController];
    }
}

@end
