//
//  SJPageView.m
//  SJPageView
//
//  Created by sadjason on 2018/03/08.
//  Copyright © 2018年 zhangbuhuai.com. All rights reserved.
//

#import "SJPageView.h"

@interface SJPageView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) NSInteger numberOfItems;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIView *> *innerLoadedItemViews;

@property (nonatomic, assign) CGFloat pageOffset;
@property (nonatomic, assign) NSInteger currentItemIndex;
@property (nonatomic, copy) NSArray<NSNumber *> *indexesForVisibleItems;

@property (nonatomic, assign) BOOL isStateFrozen;

@end

static NSString * const kPropertyItemKeyPath = @"keyPath";
static NSString * const kPropertyItemAssignmentBlock = @"assignmentBlock";

static void *kScrollViewContentOffsetContext = &kScrollViewContentOffsetContext;

typedef void (^SJPageViewPropertyAssignmentBlock)(void);

@implementation SJPageView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _numberOfItems = 0;
        _currentItemIndex = 0;
        _pageGap = 0.0;
        _isStateFrozen = NO;
        _automaticallyUnloadInvisibleItemView = YES;
        
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.pagingEnabled = YES;
        if (@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _scrollView.bounces = YES;
        _scrollView.scrollEnabled = YES;
        _scrollView.clipsToBounds = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        [self addSubview:_scrollView];
        
        _innerLoadedItemViews = [NSMutableDictionary dictionaryWithCapacity:3];
        [_scrollView addObserver:self
                      forKeyPath:@"contentOffset"
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:kScrollViewContentOffsetContext];
    }
    return self;
}

- (void)dealloc
{
    [_scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // resize scrollView if needed
    CGRect scrollViewFrame = CGRectInset(self.bounds, -self.pageGap / 2.0, 0.0);
    if (!CGRectEqualToRect(self.scrollView.frame, scrollViewFrame)) {
        self.scrollView.frame = scrollViewFrame;
    }
    
    // update scrollView contentSize if needed
    CGSize contentSize = self.scrollView.frame.size;
    if (self.numberOfItems > 0) {
        contentSize.width = contentSize.width * self.numberOfItems;
    }
    if (!CGSizeEqualToSize(contentSize, self.scrollView.contentSize)) {
        self.scrollView.contentSize = contentSize;
    }
    
    // layout item views if needed
    for (NSNumber *indexNumber in self.innerLoadedItemViews.allKeys) {
        [self p_setFrameForItemView:self.innerLoadedItemViews[indexNumber] atIndex:indexNumber.integerValue];
    }
    
    if (self.isStateFrozen) {
        // adjust contentOffsetX by currentIndex
        [self p_setContentOffsetXByPageOffset:self.currentItemIndex animated:NO];
    } else {
        // force update pageState (pageOffset/currentItemIndex/indexesForVisibleItems)
        [self p_updatePageState];
    }
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    if (self.window) {
        [self setNeedsLayout];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kScrollViewContentOffsetContext) {
        if (!self.isStateFrozen && [keyPath isEqualToString:@"contentOffset"]) {
            [self p_updatePageState];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Getter & Setter

- (UIView *)currentItemView
{
    return self.innerLoadedItemViews[@(self.currentItemIndex)];
}

- (NSArray<UIView *> *)visibleItemViews
{
    NSMutableArray<UIView *> *visibleViews = [NSMutableArray arrayWithCapacity:3];
    for (NSNumber *key in self.innerLoadedItemViews.allKeys) {
        if ([self.indexesForVisibleItems containsObject:key]) {
            [visibleViews addObject:self.innerLoadedItemViews[key]];
        }
    }
    return [visibleViews copy];
}

- (void)setDataSource:(id<SJPageViewDataSource>)dataSource
{
    if (_dataSource == dataSource) {
        return;
    }
    _dataSource = dataSource;
    if (_dataSource) {
        [self reloadData];
    }
}

- (void)setDelegate:(id<SJPageViewDelegate>)delegate
{
    _delegate = delegate;
    self.scrollView.delegate = delegate;
}

- (void)setPageGap:(CGFloat)pageGap
{
    if (_pageGap == pageGap) {
        return;
    }
    _pageGap = pageGap;
    [self setNeedsLayout];
}

- (void)setAutomaticallyUnloadInvisibleItemView:(BOOL)automaticallyUnloadInvisibleItemView
{
    if (_automaticallyUnloadInvisibleItemView == automaticallyUnloadInvisibleItemView) {
        return;
    }
    _automaticallyUnloadInvisibleItemView = automaticallyUnloadInvisibleItemView;
    [self setNeedsLayout];
}

#pragma mark - Layout Item View

- (void)p_setFrameForItemView:(UIView *)view atIndex:(NSInteger)index
{
    NSAssert(index >= 0 && index < self.numberOfItems, nil);
    CGSize itemSize = self.frame.size;
    view.frame = CGRectMake(index * CGRectGetWidth(self.scrollView.frame) + (CGRectGetWidth(self.scrollView.frame) - itemSize.width) / 2.0,
                            (CGRectGetHeight(self.scrollView.frame) - itemSize.height) / 2.0,
                            itemSize.width, itemSize.height);
}

#pragma mark - Loading & Removing Item View

- (void)loadViewAtIndex:(NSInteger)index
{
    if (index < 0 || index >= self.numberOfItems) {
        return;
    }
    if (![self.indexesForVisibleItems containsObject:@(index)] && !self.automaticallyUnloadInvisibleItemView) {
        return;
    }
    [self p_loadViewAtIndex:index];
}

- (void)unloadViewAtIndex:(NSInteger)index
{
    UIView *view = self.innerLoadedItemViews[@(index)];
    if (view) {
        [self p_unloadView:view atIndex:index];
    }
}

- (void)p_loadViewAtIndex:(NSInteger)index
{
    UIView *oldView = [self itemViewAtIndex:index];
    
    // fetch itemView at index
    UIView *newView = [self.dataSource itemViewAtIndex:index inPageView:self];
    NSAssert(!self.dataSource || newView, @"new view can't be nil");
    if (!newView) {
        newView = [[UIView alloc] init];
    }
    
    // before load itemView at index
    if ([self.delegate respondsToSelector:@selector(pageView:willLoadItemView:atIndex:)]) {
        [self.delegate pageView:self willLoadItemView:newView atIndex:index];
    }
    
    // unload old itemView at index if needed
    if (oldView && oldView != newView) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(pageView:willUnloadItemView:)]) {
            [self.delegate pageView:self willUnloadItemView:oldView];
        }
        [oldView removeFromSuperview];
        if (self.delegate && [self.delegate respondsToSelector:@selector(pageView:didUnloadItemView:)]) {
            [self.delegate pageView:self didUnloadItemView:oldView];
        }
    }
    
    [self p_setFrameForItemView:newView atIndex:index];
    if (newView.superview != self.scrollView) {
        [self.scrollView addSubview:newView];
    }
    
    self.innerLoadedItemViews[@(index)] = newView;
    
    // after load itemView at index
    if ([self.delegate respondsToSelector:@selector(pageView:didLoadItemView:atIndex:)]) {
        [self.delegate pageView:self didLoadItemView:newView atIndex:index];
    }
}

- (void)p_unloadView:(UIView *)view atIndex:(NSInteger)index
{
    [self.innerLoadedItemViews removeObjectForKey:@(index)];
    if (view.superview != self.scrollView) {
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(pageView:willUnloadItemView:)]) {
        [self.delegate pageView:self willUnloadItemView:view];
    }
    [view removeFromSuperview];
    if (self.delegate && [self.delegate respondsToSelector:@selector(pageView:didUnloadItemView:)]) {
        [self.delegate pageView:self didUnloadItemView:view];
    }
}

/// update multiple kvo properties synchronously
- (void)p_updateKVOProperties:(NSArray<NSDictionary *> *)propertyItems
{
    NSMutableArray<NSString *> *keyPaths = [NSMutableArray arrayWithCapacity:propertyItems.count];
    NSMutableArray<SJPageViewPropertyAssignmentBlock> *assignmentBlocks = [NSMutableArray arrayWithCapacity:propertyItems.count];
    for (NSDictionary *dict in propertyItems) {
        if (dict[kPropertyItemKeyPath] && dict[kPropertyItemAssignmentBlock]) {
            [keyPaths addObject:dict[kPropertyItemKeyPath]];
            [assignmentBlocks addObject:dict[kPropertyItemAssignmentBlock]];
        }
    }
    for (NSString *keyPath in keyPaths) {
        [self willChangeValueForKey:keyPath];
    }
    for (SJPageViewPropertyAssignmentBlock block in assignmentBlocks) {
        block();
    }
    for (NSString *keyPath in keyPaths) {
        [self didChangeValueForKey:keyPath];
    }
}

#pragma mark - Others

- (void)p_setContentOffsetXByPageOffset:(CGFloat)pageOffset animated:(BOOL)animated
{
    CGPoint targetOffset = CGPointMake(pageOffset * CGRectGetWidth(self.scrollView.frame), 0);
    if (CGPointEqualToPoint(targetOffset, self.scrollView.contentOffset)) {
        return;
    }
    [self.scrollView setContentOffset:targetOffset animated:animated];
}

- (void)p_updatePageState
{
    // page offset
    CGFloat pageOffset = self.scrollView.contentOffset.x / MAX(CGRectGetWidth(self.scrollView.frame), 1.0);
    pageOffset = MIN(MAX(0.0, self.numberOfItems - 1.0), MAX(0.0, pageOffset));
    
    // current item index
    NSInteger currentItemIndex = MIN(MAX(0, round(pageOffset)), MAX(self.numberOfItems - 1, 0));
    
    // visible indexes
    NSInteger startIndex = floor(pageOffset);
    NSInteger numberOfVisibleItems = ceil(1 + (pageOffset - startIndex));
    numberOfVisibleItems = MIN(self.numberOfItems, numberOfVisibleItems);
    NSAssert(numberOfVisibleItems <= 2, nil);
    NSMutableArray *visibleIndexes = [NSMutableArray arrayWithCapacity:numberOfVisibleItems];
    for (NSInteger i = startIndex; i < numberOfVisibleItems + startIndex; ++i) {
        [visibleIndexes addObject:@(i)];
    }
    
    // indexes for visible items
    NSArray *indexesForVisibleItems = [visibleIndexes copy];
    
    // KVO properties
    NSMutableArray<NSDictionary *> *propertyItems = [NSMutableArray arrayWithCapacity:3];
    if (self.pageOffset != pageOffset) {
        SJPageViewPropertyAssignmentBlock block = ^{
            self->_pageOffset = pageOffset;
        };
        [propertyItems addObject:@{
                                   kPropertyItemKeyPath : @"pageOffset",
                                   kPropertyItemAssignmentBlock : [block copy]
                                   }];
    }
    if (self.currentItemIndex != currentItemIndex) {
        SJPageViewPropertyAssignmentBlock block = ^{
            self->_currentItemIndex = currentItemIndex;
        };
        [propertyItems addObject:@{
                                   kPropertyItemKeyPath : @"currentItemIndex",
                                   kPropertyItemAssignmentBlock : [block copy]
                                   }];
    }
    if (![indexesForVisibleItems isEqual:self.indexesForVisibleItems]) {
        SJPageViewPropertyAssignmentBlock block = ^{
            self->_indexesForVisibleItems = indexesForVisibleItems;
        };
        [propertyItems addObject:@{
                                   kPropertyItemKeyPath : @"indexesForVisibleItems",
                                   kPropertyItemAssignmentBlock : [block copy]
                                   }];
    }
    
    // remove invisible views if needed
    if (self.automaticallyUnloadInvisibleItemView) {
        NSArray<NSNumber *> *allLoadedItemIndexes = self.innerLoadedItemViews.allKeys;
        for (NSNumber *indexNumber in allLoadedItemIndexes) {
            if (![visibleIndexes containsObject:indexNumber]) {
                UIView *view = self.innerLoadedItemViews[indexNumber];
                [self p_unloadView:view atIndex:indexNumber.integerValue];
            }
        }
    }
    
    // load missing views if needed
    if (self.window) {
        for (NSNumber *indexNumber in visibleIndexes) {
            UIView *view = self.innerLoadedItemViews[indexNumber];
            if (!view || view.superview != self.scrollView) {
                [self p_loadViewAtIndex:indexNumber.integerValue];
            }
        }
    }
    
    // update KVO properties
    if (propertyItems.count > 0) {
        [self p_updateKVOProperties:propertyItems];
    }
}

#pragma mark - Public

- (void)reloadData
{
    if (self.indexesForVisibleItems != nil) {
        SJPageViewPropertyAssignmentBlock block = ^{
            self->_indexesForVisibleItems = nil;
        };
        [self p_updateKVOProperties:@[@{
                                          kPropertyItemKeyPath : @"indexesForVisibleItems",
                                          kPropertyItemAssignmentBlock : [block copy]
                                        }]];
    }
    NSArray<NSNumber *> *allLoadIndexes = self.innerLoadedItemViews.allKeys;
    for (NSNumber *indexNumber in allLoadIndexes) {
        [self p_unloadView:self.innerLoadedItemViews[indexNumber] atIndex:indexNumber.integerValue];
    }
    [self.innerLoadedItemViews removeAllObjects];
    
    if ([self.dataSource respondsToSelector:@selector(numberOfItemsInPageView:)]) {
        self.numberOfItems = [self.dataSource numberOfItemsInPageView:self];
        self.scrollView.scrollEnabled = (!self.isStateFrozen && self.numberOfItems > 1);
    } else {
        self.numberOfItems = 0;
    }
    
    [self setNeedsLayout];
}

- (UIView *)itemViewAtIndex:(NSInteger)index
{
    return self.innerLoadedItemViews[@(index)];
}

- (NSInteger)indexOfItemView:(UIView *)view
{
    if (view == nil) {
        return NSNotFound;
    }
    for (NSNumber *indexNumber in self.innerLoadedItemViews.allKeys) {
        if (self.innerLoadedItemViews[indexNumber] == view) {
            return indexNumber.integerValue;
        }
    }
    return NSNotFound;
}

- (void)scrollToPageOffset:(CGFloat)pageOffset animated:(BOOL)animated
{
    NSParameterAssert(pageOffset >= 0.0 && pageOffset <= MAX(0.0, self.numberOfItems - 1.0));
    if (self.isStateFrozen) {
        return;
    }
    pageOffset = MAX(0, MIN(self.numberOfItems - 1.0, pageOffset));
    [self layoutIfNeeded];
    [self p_setContentOffsetXByPageOffset:pageOffset animated:animated];
}

- (void)freezeStateIfNeeded
{
    if (self.isStateFrozen) {
        return;
    }
    self.isStateFrozen = YES;
    self.scrollView.scrollEnabled = NO;
}

- (void)unfreezeStateIfNeeded
{
    if (!self.isStateFrozen) {
        return;
    }
    self.isStateFrozen = NO;
    self.scrollView.scrollEnabled = (self.numberOfItems > 1);
    [self setNeedsLayout];
}

@end

