//
//  PhotoCollectionViewController.m
//  SJPageViewDemo
//
//  Created by zhangwei on 2018/03/08.
//  Copyright © 2018年 zhangbuhuai.com. All rights reserved.
//

#import "PhotoCollectionViewController.h"
#import "PhotoBrowserViewController.h"

@interface PhotoCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, copy) NSArray<NSString *> *photos;

@end

@implementation PhotoCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Photos";
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.photos = @[@"photo1@2x.jpg", @"photo3@2x.jpg", @"photo5@2x.jpg", @"photo8@2x.jpg",
                    @"photo2@2x.jpg", @"photo4@2x.jpg", @"photo6@2x.jpg", @"photo7@2x.jpg", @"photo9@2x.jpg"];
    
    CGFloat itemWidth = floor((self.view.frame.size.width - 20 * 2 - 10 * 2) / 3.0);
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(itemWidth, itemWidth);
    layout.minimumInteritemSpacing = 10.0f;
    layout.minimumLineSpacing = 10.0f;
    layout.sectionInset = UIEdgeInsetsZero;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(20, 120, self.view.frame.size.width - 40,
                                                                             self.view.frame.size.width - 40)
                                             collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor lightGrayColor];
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([UICollectionViewCell class])];
    [self.view addSubview:self.collectionView];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([UICollectionViewCell class]) forIndexPath:indexPath];
    cell.backgroundColor = [UIColor redColor];
    for (UIView *subview in cell.contentView.subviews) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            [subview removeFromSuperview];
        }
    }
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:cell.contentView.bounds];
    imageView.image = [UIImage imageNamed:self.photos[indexPath.row]];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [cell.contentView addSubview:imageView];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect collectionViewFrameInScreen = [collectionView.superview convertRect:collectionView.frame toView:nil];
    NSMutableArray<NSValue *> *rectValues = [NSMutableArray arrayWithCapacity:self.photos.count];
    for (NSInteger index = 0; index < self.photos.count; ++index) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        UICollectionViewLayoutAttributes *layoutAttributes = [collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
        CGRect rect = layoutAttributes.frame;
        rect.origin.x += collectionViewFrameInScreen.origin.x;
        rect.origin.y += collectionViewFrameInScreen.origin.y;
        [rectValues addObject:[NSValue valueWithCGRect:rect]];
    }
    
    PhotoBrowserViewController *photoBrowser = [[PhotoBrowserViewController alloc] init];
    photoBrowser.selectedIndex = indexPath.row;
    photoBrowser.photos = self.photos;
    [self presentViewController:photoBrowser animated:NO completion:nil];
}

@end
