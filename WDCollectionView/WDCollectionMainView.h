//
//  WDCollectionMainView.h
//  FlickFlock
//
//  Created by Fred on 02/04/15.
//  Copyright (c) 2015 fred. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class WDLocalPhotoCollectionView;

@interface WDCollectionMainView : NSScrollView

/* This gets created internally by this class, from code */
@property (strong, readonly) WDLocalPhotoCollectionView *collectionView;

@end
