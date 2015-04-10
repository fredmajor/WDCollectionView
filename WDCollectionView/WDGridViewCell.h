//
// Created by Fred on 08/04/15.
// Copyright (c) 2015 wd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WDGridLayer.h"

@class WDCollectionViewMainView;


@interface WDGridViewCell : WDGridLayer {
@private
    NSUInteger _index;
}

- (void)prepareForReuse;
- (void)didBecomeFocused;
- (void)willResignFocus;

#pragma mark -
#pragma mark Properties
@property(nonatomic, assign, getter=isEditing)  BOOL editing;
@property(nonatomic, assign, getter=isSelected) BOOL selected;
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;

@property(nonatomic, strong)   CALayer    *foregroundLayer;
@property(nonatomic, readonly) WDCollectionViewMainView *gridView;
@property(nonatomic, readonly) NSRect      hitRect;
@property(nonatomic, readonly) id          draggingImage;
@property(nonatomic, assign) BOOL highlighted;
@property(nonatomic, weak) id representedObject;
@property(nonatomic, strong) NSURL *imageUrl;

@end