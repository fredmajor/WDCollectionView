//
//  WDCollectionViewMainView.m
//  WDCollectionView
//
//  Created by Fred on 06/04/15.
//  Copyright (c) 2015 wd. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WDCollectionViewMainView.h"
#import "WDCollectionView.h"
#import "WDCollectionLayoutHelpers.h"
#import "WDGridViewCell.h"
#import "WDGridViewCell+WDCollectionViewMainView.h"


@interface WDCollectionViewMainView()
-(void)WD_commonInit;
-(void)WD_handleGraphicalChangeOfDataset:(NSString*) oldDatasetId;
-(void)WD_calculateCachedStaticViewAndCellProperties;
-(void)WD_clearViewCachesAndDisplayNoItemsViewIfAvailable;
-(void)WD_initDefaultValuesForANewDataset;

-(void)WD_enqueueCellsAtIndexes:(NSIndexSet *)indexes;
-(void)WD_reloadCellsAtIndexes:(NSIndexSet *)indexes;
-(void)WD_setViewSize:(NSSize)newSize;
-(CALayer*)WD_RootLayerForDataset:(NSString *)datasetID;
-(void)WD_reorderSublayers;
- (void)WD_updateDecorativeLayers;
- (void)WD_layoutGridViewIfNeeded;
- (void)WD_layoutGridView;
- (void)WD_setNeedsLayoutGridView;
@end

@implementation WDCollectionViewMainView{
    WDCollectionView *_enclosingScrollView;

    /*-----cached values-----*/

    /*--- DATASET PROPERTIES ---*/
    NSString *_cachedDatasetId; /*dataset for which data we hold now*/
    NSMutableDictionary *_cachedNumberOfItemsInDataset;
    NSMutableDictionary *_didDatasetHaveItemsLastTime;
    NSMutableSet        *_knownDatasets;

    /*--- VIEW ITEM PROPERTIES ---*/
    /* Every value in a dictionary of some indices is an NSMutableIndexSet*/
    NSMutableDictionary *_cachedIndicesOfRealItemsInVisibleArea;  /* last visible items, in my view items coordinates*/
    NSMutableDictionary *_cachedIndicesOfRealItemsInPrepareArea;
    NSMutableDictionary *_cachedIndicesOfRealItemsInCacheArea; /*items within area, where we still keep the ready view items, without preparing them to reuse*/

    /*--- POTENTIAL ITEM PROPERTIES ---*/
    NSMutableDictionary *_cachedRangesOfPotentialItemsInVisibleArea;  /* last visible items, in my view items coordinates*/
    NSMutableDictionary *_cachedRangesOfPotentialItemsInPrepareArea;
    NSMutableDictionary *_cachedRangesOfPotentialItemsInCacheArea; /*items within area, where we still keep the ready view items, without preparing them to reuse*/

    NSMutableDictionary *_itemCurrentSizes;
    NSMutableDictionary *_itemMaxSizes;
    NSMutableDictionary *_itemMinSizes;
    NSMutableDictionary *_viewUsesAspectAndWidthResizeMode;
    NSMutableDictionary *_itemAspectForAspectMode;
    NSMutableDictionary *_itemVerticalSpacing;
    NSMutableDictionary *_itemMinHorizontalSpacing;

    /*--- VIEW-RELATED PROPERTIES ---*/
    NSMutableDictionary *_cachedPositionsOfScrollView;
    NSMutableDictionary *_cachedAvailableEnclosingViewBounds;
    NSMutableDictionary *_cachedCollectionViewSize;

    /*--- LAYOUT-RELATED PROPERTIES ---*/
    NSMutableDictionary *_itemCurrentHorizontalSpacing;
    NSMutableDictionary *_cachedNumberOfColumns;

    /*--- LAYERS ---*/
    NSMutableDictionary *_rootLayerForDatasetId;
    NSMutableDictionary *_foregroundLayerForDatasetId;
    NSMutableDictionary *_backgroundLayerForDatasetId;
    NSMutableDictionary *_selectionLayerForDatasetId;
    NSMutableDictionary *_trackingAreaForDatasetId;
    NSMutableDictionary *_needsLayoutGridViewForDatasetId;


    /*--- ITEM HANDLING ---*/
    NSMutableDictionary *_visibleItemByIndexForADataset;    //dictionary of dictionaries
    NSMutableDictionary *_reusableItemsForADataset;         //dictionary of NSMutableSets

}

#pragma mark -
#pragma mark Setup
- (instancetype)initWithFrame:(NSRect)frame
                andScrollView:(WDCollectionView *)scrollView{
    self = [super initWithFrame:frame];
    if (self) {
        _enclosingScrollView = scrollView;
        NSLog(@"WDCollectionViewMainView - INIT WITH FRAME.");
        [self WD_commonInit];
    }
    return self;
}

- (void) WD_commonInit{

    /*--- set up KVO to track the enclosing view ---*/



    /*--- initialize all the stuff ---*/
    _cachedDatasetId=@"";
    _cachedNumberOfItemsInDataset = [NSMutableDictionary dictionary];
    _didDatasetHaveItemsLastTime = [NSMutableDictionary dictionary];
    _knownDatasets = [NSMutableSet set];

    _cachedIndicesOfRealItemsInVisibleArea = [NSMutableDictionary dictionary];
    _cachedIndicesOfRealItemsInPrepareArea = [NSMutableDictionary dictionary];
    _cachedIndicesOfRealItemsInCacheArea = [NSMutableDictionary dictionary];

    _cachedRangesOfPotentialItemsInVisibleArea = [NSMutableDictionary dictionary];
    _cachedRangesOfPotentialItemsInPrepareArea = [NSMutableDictionary dictionary];
    _cachedRangesOfPotentialItemsInCacheArea = [NSMutableDictionary dictionary];

    _itemCurrentSizes = [NSMutableDictionary dictionary];
    _itemMaxSizes = [NSMutableDictionary dictionary];
    _itemMinSizes = [NSMutableDictionary dictionary];
    _viewUsesAspectAndWidthResizeMode = [NSMutableDictionary dictionary];
    _itemAspectForAspectMode = [NSMutableDictionary dictionary];
    _itemVerticalSpacing = [NSMutableDictionary dictionary];
    _itemMinHorizontalSpacing = [NSMutableDictionary dictionary];

    _cachedPositionsOfScrollView = [NSMutableDictionary dictionary];
    _cachedAvailableEnclosingViewBounds = [NSMutableDictionary dictionary];
    _cachedCollectionViewSize = [NSMutableDictionary dictionary];

    _itemCurrentHorizontalSpacing = [NSMutableDictionary dictionary];
    _cachedNumberOfColumns = [NSMutableDictionary dictionary];

    _rootLayerForDatasetId = [NSMutableDictionary dictionary];
    _foregroundLayerForDatasetId = [NSMutableDictionary dictionary];
    _backgroundLayerForDatasetId = [NSMutableDictionary dictionary];
    _selectionLayerForDatasetId = [NSMutableDictionary dictionary];
    _trackingAreaForDatasetId = [NSMutableDictionary dictionary];

    _visibleItemByIndexForADataset = [NSMutableDictionary dictionary];
    _reusableItemsForADataset = [NSMutableDictionary dictionary];
    _needsLayoutGridViewForDatasetId = [NSMutableDictionary dictionary];

    [self setLayer:[self WD_RootLayerForDataset:WDCollectionNilDataset]];
    [self setFrameSize:_enclosingScrollView.contentView.bounds.size];
    //[self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawDuringViewResize];
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
    [self setWantsLayer:YES];
    //  self.translatesAutoresizingMaskIntoConstraints = NO;      /* doesn't work with this set... */
    [self setAutoresizingMask:NSViewNotSizable];
    [self WD_setNeedsLayoutGridView];
//    [self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Communication on data change with the data source
- (void)datasetChanged:(NSString *)datasetId {
    NSLog(@"----------------------------------------");
    NSLog(@"View is handling a dataset change for a dataset with id=%@", datasetId);
    NSString *oldDatasetID = [NSString stringWithString:_cachedDatasetId];

    //dataset id has changed?
    if(![_cachedDatasetId isEqualToString:datasetId]){
        _cachedDatasetId=datasetId;

        //do we already know the new dataset?
        if(![_knownDatasets containsObject:_cachedDatasetId]){
            [self WD_initDefaultValuesForANewDataset];
            [self WD_calculateCachedStaticViewAndCellProperties];
            [_knownDatasets addObject:_cachedDatasetId];
        }
        [self WD_handleGraphicalChangeOfDataset:oldDatasetID];
    }

    //update view size if needed
    NSUInteger datasetItemCount = [self.dataSource numberOfItemsInCurrentDataset];
    NSUInteger cachedDatasetItemCount =  [((NSNumber*)_cachedNumberOfItemsInDataset[datasetId]) unsignedIntegerValue];
    if(datasetItemCount!=cachedDatasetItemCount){
        CGFloat requiredViewHeight = WDGetViewHeightToFitAllItems(datasetItemCount,
                [((NSNumber*)_cachedNumberOfColumns[datasetId]) unsignedIntegerValue],
                [((NSValue*)_itemCurrentSizes[datasetId]) sizeValue].height,
                [((NSNumber*)_itemVerticalSpacing[_cachedDatasetId]) floatValue]);

        NSSize newViewSize = NSMakeSize([((NSValue *) _cachedAvailableEnclosingViewBounds[_cachedDatasetId]) rectValue].size.width, requiredViewHeight);
        NSSize cachedVieSize = [((NSValue*)_cachedCollectionViewSize[_cachedDatasetId]) sizeValue];
        if(!NSEqualSizes(newViewSize, cachedVieSize)){
            _cachedCollectionViewSize[_cachedDatasetId] = [NSValue valueWithSize:newViewSize];
            [self WD_setViewSize:newViewSize];
        }
        _cachedNumberOfItemsInDataset[datasetId] = @(datasetItemCount);
    }

    if(datasetItemCount >0){ //dataset not empty

        //ITEMS TO BE REMOVED (ENQUEUE FOR REUSE) = OLD CACHED INDICES - NEW CACHED INDICES
        NSRange potentialItemInCacheRange = [((NSValue *) _cachedRangesOfPotentialItemsInCacheArea[_cachedDatasetId]) rangeValue]; //purely graphical information
        NSIndexSet *currentIndicesInCacheRange = [WDCollectionViewLayoutHelper realIndexSetForPotentialRange:potentialItemInCacheRange andNumberOfItemsInDataset:datasetItemCount];
        NSMutableIndexSet *indicesToBeRemovedFromCacheRange =[((NSIndexSet *) _cachedIndicesOfRealItemsInCacheArea[_cachedDatasetId]) mutableCopy];
        [indicesToBeRemovedFromCacheRange removeIndexes:currentIndicesInCacheRange];
        NSLog(@"Number of items to be removed from cache area due to data change: %lu. Items remaining in the cache range: %lu", [indicesToBeRemovedFromCacheRange count], [currentIndicesInCacheRange count]);
        [self WD_enqueueCellsAtIndexes:indicesToBeRemovedFromCacheRange];
        _cachedIndicesOfRealItemsInCacheArea[_cachedDatasetId] = currentIndicesInCacheRange;

        //ITEMS TO BE ASKED FOR CHANGES AND LATER RELOADED
        NSRange potentialItemInPrepareAreaRange =[((NSValue *) _cachedRangesOfPotentialItemsInPrepareArea[_cachedDatasetId]) rangeValue];
        NSIndexSet *realItemInPrepareAreIndices = [WDCollectionViewLayoutHelper realIndexSetForPotentialRange:potentialItemInPrepareAreaRange andNumberOfItemsInDataset:datasetItemCount];
        _cachedIndicesOfRealItemsInPrepareArea[_cachedDatasetId] = realItemInPrepareAreIndices;

        NSRange potentialItemInViewAreaRange = [((NSValue *) _cachedRangesOfPotentialItemsInVisibleArea[_cachedDatasetId]) rangeValue];
        NSIndexSet *realItemInViewAreaIndices = [WDCollectionViewLayoutHelper realIndexSetForPotentialRange:potentialItemInViewAreaRange andNumberOfItemsInDataset:datasetItemCount];
        _cachedIndicesOfRealItemsInVisibleArea[_cachedDatasetId] = realItemInViewAreaIndices;

        NSArray* indexSetsToAskForChanges = [WDCollectionViewLayoutHelper WDCalculateReloadIndicesSetsFromRealCacheIndices:currentIndicesInCacheRange realPrepareIndices:realItemInPrepareAreIndices realVisibleIndices:realItemInViewAreaIndices];

        //ask datasource for changed on indices and reload changed cells. Woohoo!
        for(NSIndexSet *setToAskForChanges in indexSetsToAskForChanges){
            NSDictionary *changes =  [self.dataSource didItemsChange:setToAskForChanges];
            NSIndexSet *changedIndices = [WDCollectionViewLayoutHelper WDIndexesWhichChanged:changes];
            [self WD_reloadCellsAtIndexes:changedIndices];
        }

        _didDatasetHaveItemsLastTime[datasetId] = @YES;
    }else{ //dataset empty
        if([_didDatasetHaveItemsLastTime[datasetId] boolValue]){
            [self WD_clearViewCachesAndDisplayNoItemsViewIfAvailable];
            _didDatasetHaveItemsLastTime[datasetId] = @NO;
        }
    }
}

- (void) WD_calculateCachedStaticViewAndCellProperties{
    NSLog(@"Calcuating cacahed view and cell properties.");

    //Number of columns
    NSRect availableView = [((NSValue *) _cachedAvailableEnclosingViewBounds[_cachedDatasetId]) rectValue];
    CGFloat itemMinHorSpacing = [((NSNumber*)_itemMinHorizontalSpacing[_cachedDatasetId]) floatValue];
    CGFloat itemW = [((NSValue*)_itemCurrentSizes[_cachedDatasetId]) sizeValue].width;
    NSUInteger noOfColumns = WDCalculateNumberOfColumns(availableView.size.width, itemMinHorSpacing, itemW);
    _cachedNumberOfColumns[_cachedDatasetId] = @(noOfColumns);
    NSLog(@"number of columns is: %lu", noOfColumns);

    //Current horizontal item spacing
    CGFloat currentHorSpacing = WDCalculateItemCurrentHorizontalSpacing(itemW, noOfColumns, availableView.size.width);
    _itemCurrentHorizontalSpacing[_cachedDatasetId] = [NSNumber numberWithFloat: currentHorSpacing];
    NSLog(@"current hor spacing is: %f", currentHorSpacing);

    //cell range possibly visible in the visible part of the screen
    CGFloat itemH = [((NSValue*)_itemCurrentSizes[_cachedDatasetId]) sizeValue].height;
    CGFloat itemVerticalSpacing = [((NSNumber*)_itemVerticalSpacing[_cachedDatasetId]) floatValue];
    NSRange cellRangePossiblyVisible =  WDCellRangePossiblyVisibleInPartOfViewWithExtension(availableView, 0,0,itemH,itemVerticalSpacing,noOfColumns);
    NSLog(@"possibly vis cell range: (%lu,%lu)", cellRangePossiblyVisible.location, cellRangePossiblyVisible.length);
    _cachedRangesOfPotentialItemsInVisibleArea[_cachedDatasetId] = [NSValue valueWithRange:cellRangePossiblyVisible];

    //cell range possibly visible in prepare area
    NSRange cellRangePossiblyToPrepare =  WDCellRangePossiblyVisibleInPartOfViewWithExtension(availableView,
            wdCollectionPrepareItemsAreaExtensionUp,wdCollectionPrepareItemsAreaExtensionDown,itemH,itemVerticalSpacing,noOfColumns);
    NSLog(@"possibly prepare cell range: (%lu,%lu)", cellRangePossiblyToPrepare.location, cellRangePossiblyToPrepare.length);
    _cachedRangesOfPotentialItemsInPrepareArea[_cachedDatasetId] = [NSValue valueWithRange:cellRangePossiblyToPrepare];

    //cell range possibly visible in cache area
    NSRange cellRangePossiblyToCache =  WDCellRangePossiblyVisibleInPartOfViewWithExtension(availableView,
            wdCollectionCacheItemsAreaExtensionUp,wdCollectionCacheItemsAreaExtensionDown,itemH,itemVerticalSpacing,noOfColumns);
    NSLog(@"possibly cache cell range: (%lu,%lu)", cellRangePossiblyToCache.location, cellRangePossiblyToCache.length);
    _cachedRangesOfPotentialItemsInCacheArea[_cachedDatasetId] = [NSValue valueWithRange:cellRangePossiblyToCache];

}

- (void)WD_initDefaultValuesForANewDataset {
    NSLog(@"initializing cached values for a new dataset");
    //_cachedDatasetId = @"";
    _didDatasetHaveItemsLastTime[_cachedDatasetId]=@YES;
    _itemCurrentSizes[_cachedDatasetId] =[NSValue valueWithSize:WDCalculateSize(wdCollectionItemWidthDef, wdCollectionItemDefaultAspect)];
    _itemMaxSizes[_cachedDatasetId] = [NSValue valueWithSize:WDCalculateSize(wdCollectionItemWidthMax, wdCollectionItemDefaultAspect)];
    _itemMinSizes[_cachedDatasetId] = [NSValue valueWithSize:WDCalculateSize(wdCollectionItemWidthMin, wdCollectionItemDefaultAspect)];
    _viewUsesAspectAndWidthResizeMode[_cachedDatasetId] = @(wdCollectionUseWidthAndAspectForZoom);
    _itemAspectForAspectMode[_cachedDatasetId] = @wdCollectionItemDefaultAspect;
    _itemVerticalSpacing[_cachedDatasetId] = @wdCollectionViewVerticalSpacingDef;
    _itemMinHorizontalSpacing[_cachedDatasetId] = @wdCollectionViewHorizontalSpacingMinDef;
    _cachedPositionsOfScrollView[_cachedDatasetId] = [NSValue valueWithPoint:_enclosingScrollView.contentView.bounds.origin];
    _cachedAvailableEnclosingViewBounds[_cachedDatasetId] = [NSValue valueWithRect:[[_enclosingScrollView contentView] bounds]];
    _cachedIndicesOfRealItemsInVisibleArea[_cachedDatasetId] = [NSIndexSet indexSet];
    _cachedIndicesOfRealItemsInPrepareArea[_cachedDatasetId] = [NSIndexSet indexSet];
    _cachedIndicesOfRealItemsInCacheArea[_cachedDatasetId] = [NSIndexSet indexSet];
    _cachedNumberOfItemsInDataset[_cachedDatasetId] = [NSNumber numberWithUnsignedInteger:0];
    _cachedCollectionViewSize[_cachedDatasetId] = [NSValue valueWithSize:_enclosingScrollView.contentView.bounds.size];
    _reusableItemsForADataset[_cachedDatasetId] = [NSMutableSet set];
    _visibleItemByIndexForADataset[_cachedDatasetId] = [NSMutableDictionary dictionary];
}

//change main layer, scroll to old position if available, etc
-(void)WD_handleGraphicalChangeOfDataset:(NSString*) oldDatasetId{
    NSLog(@"Handling graphical change of a dataset");
    _cachedCollectionViewSize[oldDatasetId] = [NSValue valueWithSize:self.frame.size];
    _cachedPositionsOfScrollView[oldDatasetId] = [NSValue valueWithPoint:_enclosingScrollView.contentView.bounds.origin];
    [self setLayer:[self WD_RootLayerForDataset:_cachedDatasetId]];
    NSSize cachedVieSize = [((NSValue*)_cachedCollectionViewSize[_cachedDatasetId]) sizeValue];
    NSPoint pointToScrollTo = [((NSValue*)_cachedPositionsOfScrollView[_cachedDatasetId]) pointValue];
    [self WD_setViewSize:cachedVieSize];
    [[_enclosingScrollView documentView] scrollPoint:pointToScrollTo];
   // [self setNeedsDisplay:YES];
    [self WD_setNeedsLayoutGridView];
}

- (void) WD_clearViewCachesAndDisplayNoItemsViewIfAvailable{
    NSLog(@"Will clear caches and display no items view.");
}

- (void)WD_enqueueCellsAtIndexes:(NSIndexSet *)indexes{
    if(!indexes || [indexes count] == 0) return;

    [indexes enumerateIndexesUsingBlock:
            ^ (NSUInteger idx, BOOL *stop)
            {
                NSNumber *key = [NSNumber numberWithUnsignedInteger:idx];
                WDGridViewCell *cell =  ((NSMutableDictionary *)_visibleItemByIndexForADataset[_cachedDatasetId])[key];
                if(cell){
//                    if([_fieldEditor delegate] == cell) [self OE_cancelFieldEditor];

                    [_visibleItemByIndexForADataset[_cachedDatasetId] removeObjectForKey:key];
                    [_reusableItemsForADataset[_cachedDatasetId] addObject:cell];
                    [cell removeFromSuperlayer];
                }
            }];
}

- (void)WD_reloadCellsAtIndexes:(NSIndexSet *)indexes{
    // If there is no index set or no items in the index set, then there is nothing to update
    if([indexes count] == 0) return;
    
    [indexes enumerateIndexesUsingBlock:
     ^ (NSUInteger idx, BOOL *stop){
         
         WDGridViewCell *newCell = [_dataSource itemForIndex:idx];
         WDGridViewCell *oldCell = _visibleItemByIndexForADataset[_cachedDatasetId][[NSNumber numberWithUnsignedInteger:idx]];
         if(newCell != oldCell)
         {
             if(oldCell) [newCell setFrame:[oldCell frame]];
             
             // Prepare the new cell for insertion
             if (newCell)
             {
                 [newCell WD_setIndex:idx];
                 //                        [newCell setSelected:[_selectionIndexes containsIndex:idx] animated:NO];
                 //
                 //                        // Replace the old cell with the new cell
                 if(oldCell)
                 {
                     [self WD_enqueueCellsAtIndexes:[NSIndexSet indexSetWithIndex:[oldCell WD_index]]];
                 }
                 [newCell setOpacity:1.0];
                 [newCell setHidden:NO];
                 //
                 
                 if(!oldCell) [newCell setFrame:[WDCollectionViewLayoutHelper countFrameForItemAtIndex:idx
                                                                                       withColumnCount:[((NSNumber*) _cachedNumberOfColumns[_cachedDatasetId]) unsignedIntegerValue]
                                                                             withItemHorizontalSpacing:[((NSNumber*)_itemCurrentHorizontalSpacing[_cachedDatasetId]) floatValue]
                                                                                          withItemSize:[((NSValue*) _itemCurrentSizes[_cachedDatasetId]) sizeValue]
                                                                               withItemVerticalSpacing:[((NSNumber*) _itemVerticalSpacing[_cachedDatasetId]) floatValue]] ];
                 
                 _visibleItemByIndexForADataset[_cachedDatasetId][[NSNumber numberWithUnsignedInteger:idx]] = newCell;
                 [_rootLayerForDatasetId[_cachedDatasetId] addSublayer:newCell];
             }
             
             [self WD_setNeedsLayoutGridView];
         }
         
     }];
    [self WD_reorderSublayers];
}

-(id) dequeueReusableCell{
    if([_reusableItemsForADataset[_cachedDatasetId] count] ==0 )return nil;
    WDGridViewCell * cell = [_reusableItemsForADataset[_cachedDatasetId] anyObject];
    [_reusableItemsForADataset[_cachedDatasetId] removeObject:cell];
    [cell prepareForReuse];
    return cell;
}

-(void)WD_setViewSize:(NSSize)newSize{
    NSLog(@"Setting new view size: (%f,%f)", newSize.width, newSize.height);
    [self setFrameSize:newSize];
    //[self setNeedsDisplay:YES];
    [self WD_setNeedsLayoutGridView];
}

//- (OEGridViewCell *)cellForItemAtIndex:(NSUInteger)index makeIfNecessary:(BOOL)necessary
//{
//    OEGridViewCell *result = [_visibleCellByIndex objectForKey:[NSNumber numberWithUnsignedInt:index]];
//    if(result == nil && necessary)
//    {
//        result = [_dataSource gridView:self cellForItemAtIndex:index];
//        [result OE_setIndex:index];
//        [result setSelected:[_selectionIndexes containsIndex:index] animated:NO];
//        [result setFrame:[self rectForCellAtIndex:index]];
//    }
//
//    return result;
//}


#pragma mark -
#pragma mark View setup
- (BOOL)isFlipped{
    return YES;
}

- (BOOL) wantsLayer{
    return YES;
}

-(CALayer*)WD_RootLayerForDataset:(NSString *)datasetID{
    if(datasetID == nil || [datasetID length] ==0){
        datasetID = WDCollectionNilDataset;
    }

    WDGridLayer* lay;
    lay = _rootLayerForDatasetId[datasetID];
    if(!lay){
        lay = [[WDGridLayer alloc]init];
        [lay setInteractive:YES];
        [lay setLayoutManager:[WDGridViewLayoutManager layoutManager]];
        [lay setDelegate:self];
        lay.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        [lay setFrame:self.bounds];
        //[lay setNeedsDisplayOnBoundsChange:NO];
        [lay setMasksToBounds:NO];
       // lay.autoresizingMask = kCALayerNotSizable;
        lay.backgroundColor = (randomNiceColor()).CGColor;
        _rootLayerForDatasetId[datasetID] = lay;
        [self WD_reorderSublayers];
        [lay setNeedsLayout];
    }
    return lay;
}

-(void)WD_reorderSublayers{
    [_rootLayerForDatasetId[_cachedDatasetId] insertSublayer:_backgroundLayerForDatasetId[_cachedDatasetId] atIndex:0];

    unsigned int index = (unsigned int)[[_rootLayerForDatasetId[_cachedDatasetId] sublayers] count];
    [_rootLayerForDatasetId[_cachedDatasetId]  insertSublayer:_foregroundLayerForDatasetId[_cachedDatasetId] atIndex:index];
    [_rootLayerForDatasetId[_cachedDatasetId]  insertSublayer:_selectionLayerForDatasetId[_cachedDatasetId] atIndex:index];
    //[_rootLayerForDatasetId[_cachedDatasetId]  insertSublayer:_dragIndicationLayer atIndex:index];
}

- (void)layoutSublayers{
    NSLog(@"WDCollectionViewMainView.layoutSublayers");
   // [self OE_reloadDataIfNeeded];
    [self WD_updateDecorativeLayers];
    [self WD_layoutGridViewIfNeeded];

}

- (void)WD_updateDecorativeLayers {
    if( !_backgroundLayerForDatasetId[_cachedDatasetId]  && !_foregroundLayerForDatasetId[_cachedDatasetId]) return;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    const NSRect decorativeFrame = [_enclosingScrollView documentVisibleRect];
    [_backgroundLayerForDatasetId[_cachedDatasetId] setFrame:decorativeFrame];
    [_foregroundLayerForDatasetId[_cachedDatasetId] setFrame:decorativeFrame];
   // [_dragIndicationLayer setFrame:NSInsetRect(decorativeFrame, 1.0, 1.0)];
    [CATransaction commit];
}

- (void)WD_layoutGridViewIfNeeded {
    if([((NSNumber*)_needsLayoutGridViewForDatasetId[_cachedDatasetId]) boolValue] ) [self WD_layoutGridView];
}

- (void)WD_layoutGridView{
    if([_visibleItemByIndexForADataset[_cachedDatasetId] count] == 0) return;
    NSLog(@"layOut grid view - recalculating positions for cells.");

    [_visibleItemByIndexForADataset[_cachedDatasetId] enumerateKeysAndObjectsUsingBlock:
            ^ (NSNumber *key, WDGridViewCell *obj, BOOL *stop)
            {
                NSUInteger keyU = [key unsignedIntegerValue];
                [obj setFrame:[WDCollectionViewLayoutHelper countFrameForItemAtIndex:keyU
                                                                     withColumnCount:[((NSNumber*) _cachedNumberOfColumns[_cachedDatasetId]) unsignedIntegerValue]
                                                           withItemHorizontalSpacing:[((NSNumber*)_itemCurrentHorizontalSpacing[_cachedDatasetId]) floatValue]
                                                                        withItemSize:[((NSValue*) _itemCurrentSizes[_cachedDatasetId]) sizeValue]
                                                             withItemVerticalSpacing:[((NSNumber*) _itemVerticalSpacing[_cachedDatasetId]) floatValue]] ];
            }];

    _needsLayoutGridViewForDatasetId[_cachedDatasetId] = @NO;
}

- (void)WD_setNeedsLayoutGridView {
    _needsLayoutGridViewForDatasetId[_cachedDatasetId] = @YES;
    [_rootLayerForDatasetId[_cachedDatasetId] setNeedsLayout];
}

@end
