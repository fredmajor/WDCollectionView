//
// Created by Fred on 08/04/15.
// Copyright (c) 2015 wd. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WDGridViewLayoutManager.h"


@implementation WDGridViewLayoutManager

+(WDGridViewLayoutManager *)layoutManager {
    static WDGridViewLayoutManager *layoutManager = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        layoutManager = [[self alloc]init];
    });
    return layoutManager;
}

- (void)layoutSublayersOfLayer:(CALayer *)theLayer
{
    if([theLayer conformsToProtocol:@protocol(WDGridViewLayoutManagerProtocol)])                 [theLayer layoutSublayers];
    else if([[theLayer delegate] conformsToProtocol:@protocol(WDGridViewLayoutManagerProtocol)]) [[theLayer delegate] layoutSublayers];
}

@end