//
//  WDCollectionViewMainView.h
//  WDCollectionView
//
//  Created by Fred on 06/04/15.
//  Copyright (c) 2015 wd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WDCollectionView.h"
#import "WDGridViewLayoutManager.h"
#import "WDGridViewMainCell.h"

#define WDCollectionNilDataset @"__WD_NIL_DATASET_ID"

#define wdCollectionViewVerticalSpacingDef 30.0F
#define wdCollectionViewHorizontalSpacingMinDef 20.0F
#define wdCollectionItemWidthMin 54.F
#define wdCollectionItemWidthDef 100.0F
#define wdCollectionItemWidthMax 500.F
#define wdCollectionUseWidthAndAspectForZoom YES
#define wdCollectionItemDefaultAspect 0.75F

#define wdCollectionPrepareItemsAreaExtensionUp 200
#define wdCollectionPrepareItemsAreaExtensionDown 300

#define wdCollectionCacheItemsAreaExtensionUp 3000
#define wdCollectionCacheItemsAreaExtensionDown 3000

extern NSString * const wdCollectionViewElementSizeChanged;

@class WDCollectionView, WDGridViewCell;

@interface WDCollectionViewMainView : NSView<WDGridViewLayoutManagerProtocol,WDCollectionViewMainCellCallback>

/* This gets created only from WDCollectionView. Not to be created directly by user */
- (instancetype)initWithFrame:(NSRect)frame
                andScrollView:(WDCollectionView *)scrollView;

#pragma mark -
#pragma mark Data change communication
- (void) datasetChanged:(NSString*)datasetId;   /*dataset id can be changed but doesn't have to. Anything about the data could have changed. DatasetId can be nil*/
- (id) dequeueReusableCell;
- (NSArray*) getAllInUseItemsForCurrentDataset;

- (WDGridViewMainCell*)inUseItemForIndex:(NSUInteger)index;
- (void) removeInUseItemForIndex:(NSUInteger)index;


-(void) setItemSizeBasedOnWidthAndAspect:(CGFloat)newWidth;

#pragma mark -
#pragma Public properties
@property(nonatomic, weak) id<WDCollectionViewDataSource> dataSource;
@property(nonatomic, weak) id<WDCollectionViewDelegate> delegate;
@end
