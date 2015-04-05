//
//  WDLocalPhotoCollectionView.m
//  FlickFlock
//
//  Created by Fred on 23/03/15.
//  Copyright (c) 2015 fred. All rights reserved.
//

#import "WDPhotoCollectionView.h"
#import "WDCollectionViewItem.h"
#import "WDCollectionViewLayoutHelpers.h"
#import "WDCollectionViewItemCache.h"

NSString * const wdCollectionViewElementSizeChanged = @"wdCollectionViewElementSizeChanged";


#pragma mark -
#pragma mark Resize request helpers (does also zoom)
typedef enum WDResizeTypeEnum: NSInteger{
    WDZoomTypeMagnification,    //you request to zoom a given factor. Can be negative
    WDZoomTypeFixed,            //you need to specify both new dimensions
    WDZoomTypeConstantAspect    //you gotta specify only width, optionally a new aspect
}WDZoomType;

@interface WDCollectionViewResizeRequest : NSObject
@property (nonatomic) WDZoomType    zoomType;
@property (nonatomic) CGFloat       requestedMagnification;
@property (nonatomic) CGSize        requestedNewSize;
@property (nonatomic) CGFloat       requestedWidth;
@property (nonatomic) CGFloat       requestedOptionalAspect;
@end

@implementation WDCollectionViewResizeRequest
@synthesize  zoomType;
@synthesize requestedMagnification;
@synthesize requestedNewSize;
@synthesize requestedWidth;
@synthesize requestedOptionalAspect;
@end

/////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////
#pragma mark - 
#pragma mark Private interface
@interface WDPhotoCollectionView()

/* Queries the enclosing scroll view, to get the ara available for this view */
-(CGFloat) enclosingAreaWidthForMe;
-(CGFloat) enclosingAreaHeigthForMe;

- (void)        enclosingViewScrolledOrChangedSize: (NSNotification *)notification;
- (void)        updateViewForDatasetWithId: (NSString*) datasetId
                      datasetIdJustChanged: (BOOL) justChanged;

-(void) handleDatasetIdChange:(NSString*) newDatasetId;
-(void) handleItemCountChange:(NSInteger) newItemCount;
-(NSArray*) collectionViewItemsForCellRange: (WDCellRange) cellRange useLocallyCachedIndices: (BOOL) useIndices;

- (CGRect)  visibleRectOfMe;

-(BOOL) isItemWithIndexInPreloadRangeOfRows: (NSInteger) itemIndex;

//this tells how many rows could be possibly fit in the entire height of the view
//It doesn't necessary mean that there is as many rows, only that the screen height allows for that
@property (readonly, nonatomic) NSInteger rowsPossibleOnTheScreen;

//extreme row indices, which were available during last scroll/data change action
@property (readonly, nonatomic) WDRowRange lastVisibleRowRange;
@property (readonly, nonatomic) WDCellRange lastVisibleCellRange;


//read-only, shows the value of current, real spacing
@property (atomic, strong) NSString *currentDatasourceId;
@property (nonatomic) NSInteger currentItemCount;
@property (nonatomic) NSInteger currentColumnCount;
@property (nonatomic) CGFloat currentItemHorizontalSpacing;
@property (nonatomic, strong) WDCollectionViewItemCache* itemCache;


-(void) resizeDisplayAreaToFitAllItemsIfNeeded;

-(CALayer*) imageLayerForDataset: (NSString *) datasetID;


/** Handling zoom ordered from the main thread.
 *  Access methods need to be synchronized. **/
@property (nonatomic, strong) NSMutableArray *zoomRequestQueue;
-(void) putZoomRequest: (WDCollectionViewResizeRequest*) request;
-(WDCollectionViewResizeRequest*) getNextZoomRequest;

-(void) commonInit;
@end


#pragma mark -
#pragma mark Implementation
@implementation WDPhotoCollectionView{
    NSOperationQueue *visibleItemsTaskQueue;
    int lTaskCounter;   //used for visibleItemsTaskQ synchronization
    WDRowRange _lastVisibleRowRange;
    WDCellRange _lastVisibleCellRange;
    NSMutableDictionary *_datasetItemCaches;
    NSMutableDictionary *_layerForDatasetId;  //datasetId <-> it's main CAScrollLayer for displaying items
    NSScrollView* _myScrollView;
    
    CGFloat _itemHeight;
    CGFloat _itemWidth;
    CGFloat _aspect;
    CGFloat _minItemWidth;
    CGFloat _maxItemWidth;
}

/*new take*/
@synthesize zoomRequestQueue;
/*--EOF new take*/

@synthesize itemVerticalSpacing;
@synthesize itemHorizontalSpacingMin;
@synthesize itemWidth = _itemWidth;
@synthesize itemHeight = _itemHeight;
@dynamic rowsPossibleOnTheScreen;
@synthesize lastVisibleRowRange = _lastVisibleRowRange;
@synthesize lastVisibleCellRange = _lastVisibleCellRange;
@synthesize minItemWidth = _minItemWidth;
@synthesize maxItemWidth = _maxItemWidth;
@synthesize aspect = _aspect;
@synthesize useAspectAndWidth;
@synthesize currentColumnCount;
@synthesize currentItemCount;
@synthesize currentDatasourceId;
@synthesize currentItemHorizontalSpacing;
@synthesize itemCache;
@synthesize isMocSavingNow;

#pragma mark -
#pragma mark Setup
- (instancetype)initWithFrame:(NSRect)frame
                andScrollView:(NSScrollView *)scrollView{
    self = [super initWithFrame:frame];
    if (self) {
        _myScrollView = scrollView;
        NSLog(@"WDLocalPhotoCollectionView - INIT WITH FRAME!!!");
        [self commonInit];
    }
    return self;
}

-(void) commonInit{
    
    /** defaults **/
    self.itemHorizontalSpacingMin   = wdCollectionViewHorizontalSpacingMinDef;
    self.itemVerticalSpacing        = wdCollectionViewVerticalSpacingDef;
    _itemWidth                      = wdCollectionItemWidthDef;
    _itemHeight                     = wdCollectionItemHeigthDef;
    _minItemWidth                   = wdCollectionItemWidthMin;
    _maxItemWidth                   = wdCollectionItemWidthMax;
    _aspect                         = wdCollectionItemAspect;
    self.useAspectAndWidth          = wdCollectionUseWidthAndAspectForZoom;
    self.horizontalAlignment    = center;
    self.currentDatasourceId    = @"";
    self.currentItemCount       = 0;
    self.currentColumnCount     = 1;
    self.currentItemHorizontalSpacing =1;
    self.isMocSavingNow = NO;
    
    /** Init variables **/
    visibleItemsTaskQueue = [[NSOperationQueue alloc]init];
    [visibleItemsTaskQueue setMaxConcurrentOperationCount:1];
    lTaskCounter = 0;                                           /*this is used for managing view update operations on queue*/
    _datasetItemCaches = [NSMutableDictionary dictionary];
    _layerForDatasetId = [NSMutableDictionary dictionary];
    self.zoomRequestQueue = [NSMutableArray array];
    self.itemCache = [[WDCollectionViewItemCache alloc]init];
    
    /** Set up notifications. Parent is ready at this time */
    NSClipView *parentScrollContet = [_myScrollView contentView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enclosingViewScrolledOrChangedSize:)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:parentScrollContet];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enclosingViewScrolledOrChangedSize:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:parentScrollContet];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(enclosingViewScrolledOrChangedSize:)
                                                 name: wdCollectionViewElementSizeChanged
                                               object: nil];
    
    /*This is a layer-hosting view */
    [self setLayer: [ self imageLayerForDataset:self.currentDatasourceId]];
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawDuringViewResize];
    [self setWantsLayer:YES];
    
    /** Some initial view properties + additional settings */
  //  self.translatesAutoresizingMaskIntoConstraints = NO;      /* doesn't work with this set... */
    [self setAutoresizingMask:NSViewNotSizable];
    NSSize newSize = CGSizeMake(_myScrollView.bounds.size.width, _myScrollView.bounds.size.height);
    [self setFrameSize:newSize];
    if(self.useAspectAndWidth) {
        [self orderSettingItemSizeWithDefaultAspect:self.itemWidth];
    }
    [self setNeedsDisplay:YES];

    NSLog(@"WDLocalPhotoCollectionView - common init done");
}

-(BOOL) isFlipped{
    return YES;
}

- (BOOL) wantsLayer{
    return YES;
}

/** some clues in case of future problems.. **/
//invalidateIntrinsicContentSize
//NSViewShowAlignmentRects
//translates​Autoresizing​Mask​Into​Constraints = NO
//layoutSubviews

#pragma mark -
#pragma mark LAYOUT Refreshing, recounting, checking what's displayed
-(void) resizeDisplayAreaToFitAllItemsIfNeeded{
    
    CGRect newFrame = [WDCollectionViewLayoutHelpers geFrameSizeToFitNumberOfItems:[self.dataSource itemCount]
                                                               intoNumberOfColumns:self.currentColumnCount
                                                                     withViewWidth:[self enclosingAreaWidthForMe]
                                                                        itemHeigth:self.itemHeight
                                                               verticalITemSpacing:self.itemVerticalSpacing];
    if(!CGRectEqualToRect([self bounds], newFrame)){
        NSLog(@"Will resize the display area. New size:");
        RECTLOG(newFrame);
        [self setFrameSize:newFrame.size];
    //    self.layer.frame = newFrame;  //can be needed, dunno yet
    //    [self setNeedsDisplay:YES];
    }
}

-(CGFloat) enclosingAreaWidthForMe{
    return _myScrollView.bounds.size.width - 1;
}

-(CGFloat) enclosingAreaHeigthForMe{
    return _myScrollView.bounds.size.height - 1;
}

#pragma mark -
#pragma mark reaction to change
-(void) refreshViewAfterDataSourceChange: (NSString*) datasourceId{
    NSLog(@"Refresh data called.");
    
    //needed in a couple of places during the pass, so let's calculate it now and just use the latched value
    self.currentColumnCount = [WDCollectionViewLayoutHelpers columnCountForViewWithWidth:[self enclosingAreaWidthForMe]
                                                             andItemHorizontalSpacingMin:self.itemHorizontalSpacingMin
                                                                            forItemWidth:self.itemWidth];
    
    self.currentItemHorizontalSpacing = [WDCollectionViewLayoutHelpers itemHorizontalSpacingForItemWidth:self.itemWidth
                                                                                          andColumnCount:self.currentColumnCount
                                                                                       onScreenWithWidth:[self enclosingAreaWidthForMe]];
    
    if(datasourceId == nil) datasourceId=@"";
    if(![self.currentDatasourceId isEqualToString:datasourceId]){
        [self handleDatasetIdChange:datasourceId];
    }
    
    NSInteger newItemCount = [self.dataSource itemCount];
    if(self.currentItemCount != newItemCount){
        [self handleItemCountChange:newItemCount];
    }
    
    /*Re-layout all the items in range. This is a new/changed source */
    WDCellRange indicesOfItemsToLayout = [self indicesOfItemsInPrepareArea];
    NSArray *itemsToLayoutAndPreload = [self collectionViewItemsForCellRange:indicesOfItemsToLayout useLocallyCachedIndices:NO]; /*data has changed, so we can't trust indices */
    
    NSArray* changedValuesWithRects = [WDCollectionViewLayoutHelpers layoutItems:itemsToLayoutAndPreload
                                                                  forViewIndices:indicesOfItemsToLayout
                                                             withCurrentColCount:self.currentColumnCount
                                                    currentItemHorizontalSpacing:self.currentItemHorizontalSpacing
                                                                       itemWidth:self.itemWidth
                                                                      itemHeight:self.itemHeight
                                                             itemVerticalSpacing:self.itemVerticalSpacing];
    
    [itemsToLayoutAndPreload enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(WDCollectionViewItem*)obj reachedPreloadArea];    /*this starts data loading in background */
    }];
    
    NSLog(@"Rects to preload: %lu", [itemsToLayoutAndPreload count] );
    
}

-(void) handleDatasetIdChange:(NSString*) newDatasetId{
    self.currentDatasourceId = newDatasetId;    //here and only here
    CALayer *dsLay = [self imageLayerForDataset: self.currentDatasourceId];  //from now on
    [self setLayer:dsLay];
}

-(void) handleItemCountChange:(NSInteger) newItemCount{
    self.currentItemCount = newItemCount;
    [self resizeDisplayAreaToFitAllItemsIfNeeded];
}

-(WDCellRange) indicesOfItemsInPrepareArea{
    WDRowRange rowsToPrepare = [WDCollectionViewLayoutHelpers rowsInVisiblePartOfView:[self visibleRectOfMe]
                                                                      extendedOnTopBy:wdCollectionPrepareItemsAreaPixelsUp
                                                                   extendedOnBottomBy:wdCollectionPrepareItemsAreaPixelsDown
                                                                        forItemHeight:self.itemHeight
                                                               andItemVerticalSpacing:self.itemVerticalSpacing];
    
    return [WDCollectionViewLayoutHelpers cellRangeWithOverflowCheckVisibleInRowRange:rowsToPrepare
                                                                       forColumnCount:self.currentColumnCount
                                                            andItemsInCollectionTotal:self.currentItemCount];
}

-(NSScrollView*) enclosingScrollView{
    return _myScrollView;
}

- (CGRect) visibleRectOfMe{
    return NSRectToCGRect(self.visibleRect);
}

-(void) enclosingViewScrolledOrChangedSize: (NSNotification *)notification{
 //  NSLog(@"Enclosing view scrolled or changed size.");

//    
  //  if([self.currentDatasourceId length]>0){
  //      [self updateViewForDatasetWithId:self.currentDatasourceId datasetIdJustChanged:NO];
  //  }
}


#pragma mark -
#pragma mark CollectionViewItems
/* This resets the local itemCache index mapping */
-(NSArray*) collectionViewItemsForCellRange: (WDCellRange) cellRange
                    useLocallyCachedIndices: (BOOL) useIndices{
    
    /* it's not that expensive, just flush it*/
    if(!useIndices)[self.itemCache clearIndexMapping];
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:cellRange.cellnumber];
    
    for(NSInteger index=cellRange.mincell; index<cellRange.mincell+cellRange.cellnumber; index++){
        WDCollectionViewItem *item;
        item = [self.itemCache getCachedItemByIndex:index];
        if(!item){ /* Item not present in cache. We need to go to the data source and ask.*/
            item = [self.dataSource itemAtIndex:index]; /*this call results in a callback to me, to get an item based on a key */
            if(item){   /*can be nil, if not present in the controller for some reason*/
                item.itemCallback = self;
                item.lastDisplayedIndex = index;
                [self.itemCache cacheItemIfNeeded:item forIndex:index];
            }

            if(item){
                [items addObject:item];
            }else{
                [items addObject:[NSNull null]];
            }
        }
    }
    
    return items;
}

-(WDCollectionViewItem*) cachedItemForKey:(NSString*) itemKey{
    return [self.itemCache getCachedItemByKey:itemKey];
}

#pragma mark main scroll/view move handler
- (void) updateViewForDatasetWithId: (NSString*) datasetId
               datasetIdJustChanged: (BOOL) justChanged{
    
    if( self.hidden || [self superview] == nil || [self window] == nil){
        NSLog(@"!!!!!!!WDLocalPhotoCollectionView not visible!!!!!!!!!!");
        return;
    }
    
    //cool stuff, atomic increment :)
    OSAtomicIncrement32(&(lTaskCounter));
    
    NSBlockOperation *calcOperation = [[NSBlockOperation alloc]init];
    calcOperation.name = [NSString stringWithFormat:@"%d", lTaskCounter];
    NSString *localDatasetId = [NSString stringWithString:datasetId];
    BOOL localJustChanged = justChanged;
    
    __weak NSBlockOperation *weakOp = calcOperation;
    [calcOperation addExecutionBlock:^{
        NSDate* startTime = [NSDate date];
        int myNumber = [weakOp.name intValue];
        
        ///////////////////////////////
        //Some initial checks
        //execute only the last one
        if(myNumber != lTaskCounter){
            return ;
        }
        
        //don't exeute if dataset has changed
//        if(! [[self.dataSource datasetId] isEqualToString:localDatasetId]){
//            NSLog(@"DataSetId changed since this operation has been scheduled. Cleaning view and returning imediately.");
//            [self clearView];
//            return;
//        }
        
        ///////////////////////////////////////////
        //1. get indices of visible items and first/last visible row
//        CGRect visibleArea = [self getVisibleRectOfCollView];
//        WDRowRange visibleRows = [self rowsVisibleInRectangle:visibleArea];
//        _lastVisibleRowRange = visibleRows;
//        WDCellRange visibleCellRange = [self cellRangeVisibleInRowsWithOverCheck:visibleRows];
//        _lastVisibleCellRange = visibleCellRange;
//        
//        WDRowRange rowsToPrepare =  [self preloadAndLayoutRowRangeBasedOnSize];
//        WDCellRange cellsToPrepare = [self cellRangeVisibleInRowsWithOverCheck:rowsToPrepare];
//        NSArray *itemsToPrepare = [self getItemsForIndicesAndCacheThem: cellsToPrepare
//                                                    forDatasourceWithId:localDatasetId];
//        for(WDCollectionViewItem* itemInPreloadArea in itemsToPrepare){
//            [itemInPreloadArea reachedPreloadArea];
//        }
//        NSLog(@"Rects to preload: %lu", [itemsToPrepare count] );
        
     //   NSArray *rectanglesToRedraw = [self layoutItems:itemsToPrepare forViewIndices:cellsToPrepare];
        
        ///////////////////////////////////////////
        //2. tell to load items which have appeared recently.
   //     WDCellRange preloadItemIndices = [self indicesOfItemsInPreloadRange];
   //     NSArray *itemsForPreload = [self getItemsForIndicesAndCacheThem: preloadItemIndices forDatasourceWithId:localDatasetId];
//        for(WDCollectionViewItem* itemInPreloadArea in itemsForPreload){
//            [itemInPreloadArea reachedPreloadArea];
//        }
//        NSLog(@"Rects to preload: %lu", [itemsForPreload count] );
        
        ///////////////////////////////////////////
        //3. get items to layout. TBH here we don't even know if the item is already loaded
//        WDCellRange prerenderItemIndices = [self indicesOfItemsInPrerenderRange];
//        NSInteger subsetStart = prerenderItemIndices.mincell - preloadItemIndices.mincell;
//        NSArray *itemsForPrerender = [itemsForPreload subarrayWithRange:NSMakeRange(subsetStart, prerenderItemIndices.cellnumber)];     //prerender is always a subset of preload
//        
//        NSArray *rectanglesToRedraw = [self layoutItemsAndCreateLayersIfNeeded:itemsForPrerender
//                                  forViewIndices:prerenderItemIndices
//                           dataSourceJustChanged:localJustChanged forDsId:localDatasetId ];
//        NSLog(@"rects to redraw: %lu", [rectanglesToRedraw count]);
//        
        
        ///////////////////////////////////////////
        //4. order display if needed
//        if([rectanglesToRedraw count] > 0) {
//            dispatch_sync(dispatch_get_main_queue(), ^{
//                for(NSValue *valForRect in rectanglesToRedraw){
//                    [self setNeedsDisplayInRect:[valForRect rectValue]];
//                }
//            });
//        }
        [self setNeedsDisplay:YES];
        [CATransaction flush];
    //    NSLog(@"time of view update in background: %f.", [[NSDate date] timeIntervalSinceDate:startTime]);
        if(wdCollectionScrollViewScanInterval !=0 )[NSThread sleepForTimeInterval:wdCollectionScrollViewScanInterval];
    }];
    
    [visibleItemsTaskQueue addOperation:calcOperation];
}



#pragma mark - 
#pragma mark Layout pictures



-(CALayer*) imageLayerForDataset: (NSString *) datasetID{
    
    if(datasetID == nil || [datasetID length] ==0){
        datasetID =@"__DEF_WD_COLL_DATASET_FOR_IMLAYER__";
    }
    
    CALayer* lay;
    lay =  [_layerForDatasetId objectForKey:datasetID];
    if(!lay){
        lay = [CAScrollLayer layer];
        [lay setNeedsDisplayOnBoundsChange:NO];
        [lay setMasksToBounds:NO];
        lay.autoresizingMask = kCALayerNotSizable;
//        lay.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        lay.backgroundColor = (randomNiceColor()).CGColor;
        [_layerForDatasetId setObject:lay forKey:datasetID];
    }
    return lay;
}

/* An item is telling me, that it finished loading of image.
* The item runs this on the main thread.
 */

-(void) itemFinishedLoadingImage: (WDCollectionViewItem*) source{
    CALayer *mainLayer = [self imageLayerForDataset:source.datasetId];  //bedzie z tym problem jak jeden obiekt representedOBject bedzie w dwoch roznych datasetach
    [mainLayer addSublayer:source.imageLayer];
}



#pragma mark -
#pragma mark Row&Range calcs




#pragma mark -
#pragma mark Zoom & size

/* Gets called when user does a pinch gesture */
/* Gets called from the main thread */
/* Don't call this method directly */
- (void)magnifyWithEvent:(NSEvent *)event{
    CGFloat mag = [event magnification];
    [self orderResizeForMagnification:mag];
}

/* Gets called from a zoom slider, from main thread */
-(void) orderSettingItemSizeWithDefaultAspect:(CGFloat) width{
    [self orderResizeForNewWidtht:width withAspect:-1.0f];
}

/** NEW, to add header **/
/* Private. Don't call this method directly. Safe to be called from main thread. */
-(void) orderResizeForMagnification: (CGFloat) magnification{
    WDCollectionViewResizeRequest *request = [[WDCollectionViewResizeRequest alloc]init];
    request.requestedMagnification = magnification;
    request.zoomType =WDZoomTypeMagnification;
    [self putZoomRequest:request];
}

/** NEW, to add header **/
/* Private. Don't call this method directly. Safe to be called from main thread. */
/* aspect <=0 means, that aspect is not changed */
-(void) orderResizeForNewWidtht: (CGFloat) newWidth withAspect: (CGFloat) newAspect{
    WDCollectionViewResizeRequest *request = [[WDCollectionViewResizeRequest alloc]init];
    request.requestedWidth = newWidth;
    request.requestedOptionalAspect = newAspect;
    request.zoomType =WDZoomTypeConstantAspect;
    [self putZoomRequest:request];
}

/** NEW, to add header **/
/** Private. Gets called internally from a private thread. */
-(NSSize) getNewSizeForZoomRequest: (WDCollectionViewResizeRequest*) request{
    NSSize targetSize = NSZeroSize;
    
    if(request.zoomType == WDZoomTypeFixed){
        NSLog(@"WDZoomTypeFixed not implemented.");
    
    }else if(request.zoomType == WDZoomTypeMagnification){
        CGFloat currWid  = self.itemWidth;
        CGFloat mag = request.requestedMagnification;
        CGFloat newWidth = currWid + currWid*mag;
        CGFloat newHeight = newWidth * self.aspect;
        targetSize.width = newWidth;
        targetSize.height = newHeight;
    
    }else if(request.zoomType == WDZoomTypeConstantAspect){
        CGFloat newAspect = request.requestedOptionalAspect;
        CGFloat newWidth = request.requestedWidth;
        if(newAspect>0) _aspect = newAspect;
        targetSize.width = newWidth;
        targetSize.height = newWidth * self.aspect;
    
    }else{
        NSLog(@"Zoom type %ld not implemented.", request.zoomType);
    }
    
    //SO far only width based + aspect
    if([self checkItemNewWidth:targetSize.width]){
        return targetSize;
    }else{
        return NSZeroSize;
    }
}

/** NEW, add to header */
/* Called internally from a private thead */
-(BOOL) checkItemNewWidth: (CGFloat) newWidth{
    if(newWidth < self.minItemWidth || newWidth > self.maxItemWidth){
        return false;
    }
    return true;
}

#pragma mark resize request queue
-(void) putZoomRequest: (WDCollectionViewResizeRequest*) request{
    @synchronized(self.zoomRequestQueue){
        [self.zoomRequestQueue enqueue:request];
    }
}
/*
 * Can return nil.
 */
-(WDCollectionViewResizeRequest*) getNextZoomRequest{
    @synchronized(self.zoomRequestQueue){
        return [self.zoomRequestQueue dequeue];
    }
}

/** TO BE DISMISSED **/
-(void) setItemSize:(NSSize) size{
//    self.itemWidth  = size.width;
//    self.itemHeight = size.height;

    //////////////
    //scroll to maintain visible elements
    CGRect oldFrame = self.frame;
    [self resizeDisplayAreaToFitAllItemsIfNeeded];
    CGRect newFrame = self.frame;
   
    CGFloat resizeRatio =  newFrame.size.height / oldFrame.size.height;
    NSPoint currentScrollPosition=[[self.enclosingScrollView contentView] bounds].origin;
    
    NSPoint newScrollPosition;
    newScrollPosition.x = currentScrollPosition.x;
    newScrollPosition.y = currentScrollPosition.y * resizeRatio;
    if(newScrollPosition.y<0.0f) newScrollPosition.y = 0.0f;
    CGFloat maxPossibleScrollY = self.frame.size.height - self.visibleRect.size.height;
    if(newScrollPosition.y >= maxPossibleScrollY) newScrollPosition.y = maxPossibleScrollY-1;

 //   [[self.enclosingScrollView documentView] scrollPoint:newScrollPosition];
    [self setNeedsDisplay:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:wdCollectionViewElementSizeChanged
                                                        object:self];
}

#pragma mark -
#pragma mark WDCollectionViewItemCallback - to be called by my items
-(BOOL) isItemInPreloadArea: (WDCollectionViewItem*) item{
    __block BOOL isItem;
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSInteger itemIndex = [self.dataSource indexOfItemForRepresentedObject:item.representedObject]; //this goes to main thread
        if(itemIndex<0){
            isItem = NO;
        }else{
            isItem = [self isItemWithIndexInPreloadRangeOfRows:itemIndex];
        }
    });
    return isItem;
}

-(BOOL) isItemWithIndexInPreloadRangeOfRows: (NSInteger) itemIndex{
    WDCellRange preloadRange = [self indicesOfItemsInPrepareArea];
    if(preloadRange.cellnumber>0){
        WDIndexPair preloadIndices = WDMakeIndexPairFromCellRange(preloadRange);
        return (itemIndex >= preloadIndices.first) && (itemIndex <= preloadIndices.last);
    }else{
        return NO;
    }
}

- (void)notificationHandler: (NSNotification *) notification{
    if([notification.name isEqualToString:@"WDCOL.mainMocWillSave"]){
        self.isMocSavingNow = YES;
    }
    
    if([notification.name isEqualToString:@"WDCOL.mainMocSaved"]){
        self.isMocSavingNow = NO;
    }
}


#pragma mark -
#pragma mark Rendering of images
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}
@end
