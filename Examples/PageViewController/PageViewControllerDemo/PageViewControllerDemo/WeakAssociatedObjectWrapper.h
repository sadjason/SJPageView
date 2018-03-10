//
//  WeakAssociatedObjectWrapper.h
//  SJPageViewDemo
//
//  Created by zhangwei on 2018/03/08.
//  Copyright © 2018年 zhangbuhuai.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WeakAssociatedObjectWrapper : NSObject

@property (nonatomic, weak, readonly) id object;

+ (instancetype)wrapperWithObject:(id)object;

@end

NS_ASSUME_NONNULL_END
