//
//  ImageZoomView.m
//  SJPageViewDemo
//
//  Created by sadjason on 2018/03/08.
//  Copyright © 2018年 zhangbuhuai.com. All rights reserved.
//

#import "ImageZoomView.h"

@interface ImageZoomView () <UIScrollViewDelegate>

@property (nonatomic, strong) UIView *tapView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@property (nonatomic, assign) CGFloat secondBestZoomScale;

@end

static void *kImageViewImageContext = &kImageViewImageContext;

@implementation ImageZoomView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _tapView = [[UIView alloc] init];
        _tapView.userInteractionEnabled = YES;
        _tapView.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_handleSingleTap:)];
        singleTapGesture.numberOfTapsRequired = 1;
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_handleDoubleTap:)];
        doubleTapGesture.numberOfTapsRequired = 2;
        [_tapView addGestureRecognizer:singleTapGesture];
        [_tapView addGestureRecognizer:doubleTapGesture];
        [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
        [self addSubview:_tapView];
        
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [_imageView addObserver:self
                     forKeyPath:@"image"
                        options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                        context:kImageViewImageContext];
        [self addSubview:_imageView];
        
        _hideIndicator = YES;
        
        _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _loadingIndicator.hidesWhenStopped = YES;
        [self addSubview:_loadingIndicator];
        
        self.delegate = self;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.minimumZoomScale = 1.0;
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return self;
}

- (void)dealloc
{
    [_imageView removeObserver:self forKeyPath:@"image"];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.tapView.frame = self.bounds;
    
    CGSize boundsSize = self.bounds.size;
    CGRect imageViewFrame = self.imageView.frame;
    if (imageViewFrame.size.width < boundsSize.width) {
        imageViewFrame.origin.x = floor((boundsSize.width - imageViewFrame.size.width) / 2.0);
    } else {
        imageViewFrame.origin.x = 0.0;
    }
    if (imageViewFrame.size.height < boundsSize.height) {
        imageViewFrame.origin.y = floor((boundsSize.height - imageViewFrame.size.height) / 2.0);
    } else {
        imageViewFrame.origin.y = 0.0;
    }
    if (!CGRectEqualToRect(self.imageView.frame, imageViewFrame)) {
        self.imageView.frame = imageViewFrame;
    }
    
    self.loadingIndicator.center = self.imageView.center;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kImageViewImageContext) {
        [self p_boundsSizeOrImageChanged];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Setter

- (void)setFrame:(CGRect)frame
{
    CGSize oldBoundsSize = self.bounds.size;
    [super setFrame:frame];
    if (!CGSizeEqualToSize(self.bounds.size, oldBoundsSize)) {
        [self p_boundsSizeOrImageChanged];
    }
}

- (void)setHideIndicator:(BOOL)hideIndicator
{
    if (_hideIndicator == hideIndicator) {
        return;
    }
    if (_hideIndicator) {
        [self.loadingIndicator stopAnimating];
    } else {
        [self.loadingIndicator startAnimating];
    }
}

#pragma mark - Public

- (void)prepareForReuse
{
    self.imageView.image = nil;
    self.hideIndicator = YES;
}

#pragma mark - Private

- (void)p_boundsSizeOrImageChanged
{
    self.zoomScale = 1.0;
    self.maximumZoomScale = 1.0;
    self.contentSize = CGSizeZero;
    self.imageView.frame = CGRectZero;
    
    CGSize boundsSize = self.bounds.size;
    
    if (!self.imageView.image
        || self.imageView.image.size.width < 1.0
        || self.imageView.image.size.height < 1.0
        || boundsSize.width < 1.0
        || boundsSize.height < 1.0) {
        return;
    }
    
    CGFloat xScale = boundsSize.width / self.imageView.image.size.width;
    CGFloat yScale = boundsSize.height / self.imageView.image.size.height;
    CGFloat minScale = MIN(xScale, yScale);
    CGSize imageViewSize = CGSizeMake(minScale * self.imageView.image.size.width, minScale * self.imageView.image.size.height);
    imageViewSize.width = MIN(boundsSize.width, ceil(imageViewSize.width));
    imageViewSize.height = MIN(boundsSize.height, ceil(imageViewSize.height));
    CGRect imageViewFrame = self.imageView.frame;
    imageViewFrame.size = imageViewSize;
    self.imageView.frame = imageViewFrame;
    self.contentSize = imageViewSize;
    
    self.secondBestZoomScale = MAX(2.0, MAX(xScale, yScale) / minScale);
    
    // set maxZoomScale
    self.maximumZoomScale = MAX(self.secondBestZoomScale, 3.0);
    
    // set zoomScale
    self.zoomScale = self.minimumZoomScale;
    
    // disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in image
    self.scrollEnabled = NO;
    
    [self setNeedsLayout];
}

#pragma mark - Target Action

- (void)p_handleSingleTap:(UITapGestureRecognizer *)tapGesture
{
    if (self.singleTapTriggeredBlock) {
        self.singleTapTriggeredBlock();
    }
}

- (void)p_handleDoubleTap:(UITapGestureRecognizer *)tapGesture
{
    if (self.zoomScale != self.minimumZoomScale) {
        // zoom out
        [self setZoomScale:self.minimumZoomScale animated:YES];
    } else {
        CGPoint location = [tapGesture locationInView:self.tapView];
        // fixup location with zoomScale and contentOffset
        location.x *= 1.0 / self.zoomScale;
        location.y *= 1.0 / self.zoomScale;
        location.x += self.contentOffset.x;
        location.y += self.contentOffset.y;
        
        // zoom into twice the size
        CGFloat newZoomScale = self.secondBestZoomScale;//((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(location.x - xsize / 2.0, location.y - ysize / 2.0, xsize, ysize) animated:YES];
    }
    if (self.doubleTapTriggeredBlock) {
        self.doubleTapTriggeredBlock();
    }
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    self.scrollEnabled = YES;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end

