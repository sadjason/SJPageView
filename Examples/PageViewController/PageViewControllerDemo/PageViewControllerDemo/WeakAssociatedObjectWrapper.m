//
//  WeakAssociatedObjectWrapper.m
//  SJPageViewDemo
//
//  Created by zhangwei on 2018/03/08.
//  Copyright © 2018年 zhangbuhuai.com. All rights reserved.
//

#import "WeakAssociatedObjectWrapper.h"

@interface WeakAssociatedObjectWrapper ()

@property (nonatomic, weak) id object;

@end

@implementation WeakAssociatedObjectWrapper

+ (instancetype)wrapperWithObject:(id)object
{
    WeakAssociatedObjectWrapper *wrapper = [[WeakAssociatedObjectWrapper alloc] init];
    wrapper.object = object;
    return wrapper;
}

@end
