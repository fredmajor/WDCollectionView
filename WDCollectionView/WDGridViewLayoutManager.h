//
// Created by Fred on 08/04/15.
// Copyright (c) 2015 wd. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol WDGridViewLayoutManagerProtocol <NSObject>
- (void)layoutSublayers;
@end

@interface WDGridViewLayoutManager : NSObject
+(WDGridViewLayoutManager *)layoutManager;
@end