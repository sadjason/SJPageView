//
//  SJPageView.h
//  SJPageView
//
//  Created by sadjason on 2018/03/08.
//  Copyright © 2018年 zhangbuhuai.com. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SJPageViewDataSource;
@protocol SJPageViewDelegate;

/**
 PageView for Photo.
    * Don't support reuse management.
    * Support Orientation.
 */
@interface SJPageView : UIView

@property (nonatomic, weak) id<SJPageViewDataSource> dataSource;
@property (nonatomic, weak) id<SJPageViewDelegate> delegate;

/// Default `0.0`, gap between adjacent itemViews
@property (nonatomic, assign) CGFloat pageGap;

/// default `YES`. It means that pageView will remove all invisible item views from superview
@property (nonatomic, assign) BOOL automaticallyUnloadInvisibleItemView;

/// The following three properties, are considered to be state properties, and there are all support KVO.
@property (nonatomic, assign, readonly) CGFloat pageOffset;  //`0.0 <= pageOffset <= MAX(numberOfItems-1.0, 0.0)`
@property (nonatomic, assign, readonly) NSInteger currentItemIndex;
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *indexesForVisibleItems;

/// Make sure `0.0 <= pageOffset <= MAX(numberOfItems-1.0, 0.0)`
- (void)scrollToPageOffset:(CGFloat)pageOffset animated:(BOOL)animated;

/// return `nil` if view at index has not been loaded
- (nullable UIView *)itemViewAtIndex:(NSInteger)index;
/// return `NSNotFound` if view has not been loaded
- (NSInteger)indexOfItemView:(UIView *)view;

- (void)reloadData;

/// Before transitioning (such as rotating) view, you should call `freezeStateIfNeeded`, and call `unfreezeStateIfNeeded` after finishing transition.
- (void)freezeStateIfNeeded;
- (void)unfreezeStateIfNeeded;

// When `automaticallyUnloadInvisibleItemView` equal to `NO`, you may need to manage invisible item view manually.
- (void)loadViewAtIndex:(NSInteger)index;
- (void)unloadViewAtIndex:(NSInteger)index;

@end

@protocol SJPageViewDataSource <NSObject>

@required
- (NSInteger)numberOfItemsInPageView:(SJPageView *)pageView;
- (UIView *)itemViewAtIndex:(NSInteger)index inPageView:(SJPageView *)pageView;

@end

@protocol SJPageViewDelegate <UIScrollViewDelegate>

@optional
- (void)pageView:(SJPageView *)pageView willLoadItemView:(UIView *)view atIndex:(NSInteger)index;
- (void)pageView:(SJPageView *)pageView didLoadItemView:(UIView *)view atIndex:(NSInteger)index;
- (void)pageView:(SJPageView *)pageView willUnloadItemView:(UIView *)itemView;
- (void)pageView:(SJPageView *)pageView didUnloadItemView:(UIView *)itemView;

@end

NS_ASSUME_NONNULL_END
