//
//  WDPhotoCollectionView.h
//  FlickFlock
//
//  Created by Fred on 23/03/15.
//  Copyright (c) 2015 fred. All rights reserved.
//
#import <Cocoa/Cocoa.h>

//! Project version number for WDCollectionView.
FOUNDATION_EXPORT double WDCollectionViewVersionNumber;

//! Project version string for WDCollectionView.
FOUNDATION_EXPORT const unsigned char WDCollectionViewVersionString[];

#pragma mark -
#pragma mark Layout defaults

#define wdCollectionViewVerticalSpacingDef 30.0f
#define wdCollectionViewHorizontalSpacingMinDef 20.0f

#define wdCollectionItemHeigthDef 100.0f
#define wdCollectionItemWidthMin 54.f
#define wdCollectionItemWidthDef 100.0f
#define wdCollectionItemWidthMax 500.f
#define wdCollectionUseWidthAndAspectForZoom YES
#define wdCollectionItemAspect 0.75f

#define wdCollectionScrollViewScanInterval 0.1f

#define wdCollectionPrepareItemsAreaPixelsUp 200
#define wdCollectionPrepareItemsAreaPixelsDown 500
#define wdCollectionCacheItemsAreaPixelsUp 400
#define wdColletionCacheItemsAreaPixelsDown 800

extern NSString * const wdCollectionViewElementSizeChanged;

#pragma mark -
#pragma mark Protocols
@protocol WDCollectionViewDataSource <NSObject>
@required
-(WDCollectionViewItem *) itemAtIndex:(NSInteger) index;   //this can return nil. That means that either dataset has changed or simply there's now no item to display. This is because we handle change in different thread
-(NSInteger) itemCount;
-(NSInteger) indexOfItemForRepresentedObject: (NSObject*) representedObject;
@end

typedef enum HorizontalAlignment : NSInteger {
    left,
    right,
    center
} HorizontalAlignment;

#pragma mark -
#pragma mark Main interface
@interface WDPhotoCollectionView : NSView <WDCollectionViewItemCallback>

/* A designated constructor */
- (instancetype)initWithFrame:(NSRect)frame andScrollView:(NSScrollView*) scrollView;

/* Used by layout */
@property (nonatomic) CGFloat itemVerticalSpacing;
@property (nonatomic) CGFloat itemHorizontalSpacingMin;
@property (nonatomic) HorizontalAlignment horizontalAlignment;  //currently not used

/* Current values. RO. Can get set only via  a request */
@property (nonatomic, readonly) CGFloat itemHeight;
@property (nonatomic, readonly) CGFloat itemWidth;

/* Zoom % resize */
@property (nonatomic, readonly) CGFloat minItemWidth;     //min allowed for zoom. Accessible from main thread. Consider making it atomic.
@property (nonatomic, readonly) CGFloat maxItemWidth;     //max allowed for zoom
@property (nonatomic, readonly) CGFloat aspect;           //aspect for zooming
@property (nonatomic) BOOL useAspectAndWidth;   //aspect zoom mode (default)

@property (nonatomic) BOOL isMocSavingNow;
#pragma mark Data source communication
/* Data soure and related, public methods called from data source and controller */
@property (nonatomic, weak) id<WDCollectionViewDataSource> dataSource;

/* From data source. Runs a layout update in the same thread */
-(void) refreshViewAfterDataSourceChange: (NSString*) datasourceId;

-(WDCollectionViewItem*) cachedItemForKey:(NSString*) itemKey;
#pragma resize
-(void) orderSettingItemSizeWithDefaultAspect:(CGFloat) width;   //resize util called from NSSlider

@end
