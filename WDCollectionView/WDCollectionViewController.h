//
//  WDLocalPhotoCollectionViewController.h
//  FlickFlock
//
//  Created by Fred on 23/03/15.
//  Copyright (c) 2015 fred. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WDLocalPhotoCollectionView.h"
#import "WDCollectionViewItem.h"

@class WDCollectionMainView;

@interface WDLocalPhotoCollectionViewController : NSViewController <WDCollectionViewDataSource, WDCollectionViewCacheProvider>

@property (weak, nonatomic) IBOutlet NSArrayController *dataSourceArrayController;
@property (weak, nonatomic) IBOutlet NSArrayController *albumArrayController;

@end
