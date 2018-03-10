//
//  PageItemViewController.m
//  SJPageViewDemo
//
//  Created by zhangwei on 2018/03/10.
//  Copyright © 2018年 zhangbuhuai.com. All rights reserved.
//

#import "PageItemViewController.h"

@interface PageItemViewController ()

@property (nonatomic, strong) UILabel *contentLabel;

@end

@implementation PageItemViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.contentLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    self.contentLabel.text = self.content;
    self.contentLabel.textColor = [UIColor whiteColor];
    self.contentLabel.textAlignment = NSTextAlignmentCenter;
    self.contentLabel.font = [UIFont boldSystemFontOfSize:60.0];
    [self.view addSubview:self.contentLabel];
}

- (void)setContent:(NSString *)content
{
    _content = [content copy];
    self.contentLabel.text = _content;
}

@end
