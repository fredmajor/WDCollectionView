//
//  WDCollectionViewMainView.h
//  WDCollectionView
//
//  Created by Fred on 06/04/15.
//  Copyright (c) 2015 wd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WDCollectionView.h"
#define WDCollectionNilDataset @"__WD_NIL_DATASET_ID"

#define wdCollectionViewVerticalSpacingDef 30.0F
#define wdCollectionViewHorizontalSpacingMinDef 20.0F
#define wdCollectionItemWidthMin 54.F
#define wdCollectionItemWidthDef 100.0F
#define wdCollectionItemWidthMax 500.F
#define wdCollectionUseWidthAndAspectForZoom YES
#define wdCollectionItemDefaultAspect 0.75F

#define wdCollectionPrepareItemsAreaExtensionUp 100
#define wdCollectionPrepareItemsAreaExtensionDown 300

#define wdCollectionCacheItemsAreaExtensionUp 300
#define wdCollectionCacheItemsAreaExtensionDown 600

@class WDCollectionView;





@interface WDCollectionViewMainView : NSView

/* This gets created only from WDCollectionView. Not to be created directly by user */
- (instancetype)initWithFrame:(NSRect)frame
                andScrollView:(WDCollectionView *)scrollView;

#pragma mark -
#pragma mark Data change communication
- (void) datasetChanged:(NSString*)datasetId;   /*dataset id can be changed but doesn't have to. Anything about the data could have changed. DatasetId can be nil*/
- (void) dataInDatasetChanged:(NSString*)datasetId;
- (void) indicesOfChangedItemsInCurrentDataset:(NSIndexSet *)indexSet;


#pragma mark -
#pragma Public properties
@property(nonatomic, weak) id<WDCollectionViewDataSource> dataSource;
@property(nonatomic, weak) id<WDCollectionViewDelegate> delegate;
@end
