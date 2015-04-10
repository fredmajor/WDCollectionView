//
//  WDGridViewMainCell.h
//  WDCollectionView
//
//  Created by Fred on 10/04/15.
//  Copyright (c) 2015 wd. All rights reserved.
//

#import "WDGridViewCell.h"
#import "WDCollectionViewImage.h"

@class WDGridViewMainCell;

@protocol WDCollectionViewMainCellCacheProvider <NSObject>
@required
-(NSCache*) cacheForLoadedImages;
@end

@protocol WDCollectionViewMainCellCallback <NSObject>
@required
- (BOOL)isItemInPreloadArea: (WDGridViewMainCell*) item;
@optional
- (void)itemFinishedLoadingImage: (WDGridViewMainCell*) source;
@end

@interface WDGridViewMainCell : WDGridViewCell<WDCollectionViewImageCallback>

@property(nonatomic, weak) id<WDCollectionViewMainCellCallback> itemCallback;
@property(nonatomic, weak) id<WDCollectionViewMainCellCacheProvider> cacheProvider;
@property(nonatomic, weak) id representedObject;
@property(nonatomic, strong) NSURL *imageUrl;

- (void)loadImageIfNeeded;


@end
