//
// Created by Fred on 07/04/15.
// Copyright (c) 2015 wd. All rights reserved.
//
#ifndef WDCollectionWorkspace_WDCollectionLayoutHelpers_h
#define WDCollectionWorkspace_WDCollectionLayoutHelpers_h

#import <Foundation/Foundation.h>
#define RECTLOG(rect)    (NSLog(@""  #rect @" x:%f y:%f w:%f h:%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height ));

static inline NSSize WDCalculateSize(CGFloat width, CGFloat aspect){
    return NSMakeSize(width, aspect*width);
}

static inline NSRange WDRowsVisibleInPartOfView(CGRect partOfView, CGFloat itemH, CGFloat vertSpacing){
    CGFloat yrmin = partOfView.origin.y;
    if(yrmin<0)yrmin=0;
    CGFloat yrmax = partOfView.origin.y + partOfView.size.height;
    CGFloat rowMinF = floorf((yrmin - vertSpacing)/(vertSpacing+itemH));
    if(rowMinF<0) rowMinF=0;
    CGFloat rowMaxF = floorf((yrmax-vertSpacing)/(vertSpacing+itemH));
    return NSMakeRange((NSUInteger)rowMinF, (NSUInteger)rowMaxF);
}

static inline NSRange WDRowsInVisiblePartOfViewWithExtension(CGRect visiblePartOfView, CGFloat extendVisibleOnTop,
        CGFloat extendVisibleOnBottom, CGFloat itemHeight, CGFloat itemVerticalSpacing){
    CGFloat findX = visiblePartOfView.origin.x;
    CGFloat findY = visiblePartOfView.origin.y - extendVisibleOnTop;
    CGFloat findW = visiblePartOfView.size.width;
    CGFloat findH = visiblePartOfView.size.height + extendVisibleOnTop + extendVisibleOnBottom;
    CGRect rectToFindRows = CGRectMake(findX, findY, findW, findH);
    return WDRowsVisibleInPartOfView(rectToFindRows, itemHeight, itemVerticalSpacing);
}

static inline NSRange WDCellRangeInRowRange(NSRange rowRange, NSUInteger numberOfColumns){
    NSUInteger startCellIndex = rowRange.location*numberOfColumns;
    NSUInteger stopRowInex = rowRange.location + rowRange.length -1;
    NSUInteger stopCellIndex = stopRowInex*numberOfColumns + numberOfColumns -1;
    NSInteger cellSizeInt = stopCellIndex - startCellIndex +1;
    if(cellSizeInt<0) cellSizeInt=0;
    return NSMakeRange(startCellIndex, cellSizeInt);
}

static inline NSRange WDCellRangePossiblyVisibleInPartOfViewWithExtension(CGRect visiblePartOfView, CGFloat extendVisibleOnTop,
        CGFloat extendVisibleOnBottom, CGFloat itemHeight, CGFloat itemVerticalSpacing, NSUInteger numberOfColumns){

    NSRange rowsVisible = WDRowsInVisiblePartOfViewWithExtension(visiblePartOfView, extendVisibleOnTop, extendVisibleOnBottom, itemHeight, itemVerticalSpacing);
    return WDCellRangeInRowRange(rowsVisible, numberOfColumns);
}

static inline NSRange WDCellRangeWithOverflowCheck(NSRange rowRange, NSUInteger visibleColNumber, NSUInteger itemsInCollectionTotal){
    if(itemsInCollectionTotal<=0) return NSMakeRange(0, 0);
    NSUInteger cellMin = rowRange.location * visibleColNumber;
    NSIndexSet * rowRangeIndices = [NSIndexSet indexSetWithIndexesInRange:rowRange];
    NSUInteger maxRow = [rowRangeIndices lastIndex];
    NSUInteger cellMax = maxRow * visibleColNumber + visibleColNumber -1;
    if(cellMax >= itemsInCollectionTotal) cellMax = itemsInCollectionTotal -1;
    return NSMakeRange(cellMin, cellMax - cellMin +1);
}

static inline NSUInteger WDCalculateNumberOfColumns(CGFloat viewWidth, CGFloat itemMinHorSpacing, CGFloat itemWidth){
    NSInteger colNoInt = floor((viewWidth-itemMinHorSpacing)/(itemWidth+itemMinHorSpacing));
    if(colNoInt<0) colNoInt=0;
    return (NSUInteger)colNoInt;
}

static inline CGFloat WDCalculateItemCurrentHorizontalSpacing(CGFloat itemWidth, NSUInteger numberOfColumns, CGFloat screenWidth){
    CGFloat fw = screenWidth;
    CGFloat x = numberOfColumns;
    CGFloat w = itemWidth;
    CGFloat horSp = (fw-x*w)/(x+1.0f);
    return horSp;
}

static inline NSUInteger WDTotalAmountOfRowsToFitItems(NSUInteger numberOfItems, NSUInteger withNumberOfColumns){
    return  (NSUInteger)ceilf((float)numberOfItems/(float)withNumberOfColumns);
}

static inline CGFloat WDGetViewHeightToFitAllItems(NSUInteger numberOfItems, NSUInteger numberOfColumns,
        CGFloat itemHeight, CGFloat verticalItemSpacing){

    NSUInteger rowsNeeded = WDTotalAmountOfRowsToFitItems(numberOfItems, numberOfColumns);
    NSLog(@"Total rows required to fit all the stuff: %lu", rowsNeeded);
    return rowsNeeded*(itemHeight+verticalItemSpacing) + verticalItemSpacing;
}

static inline NSColor* randomNiceColor(){
    // This method returns a random color in a range of nice ones,
    // using HSB coordinates.

    // Random hue from 0 to 359 degrees.

    CGFloat hue = (arc4random() % 360) / 359.0f;

    // Random saturation from 0.0 to 1.0

    CGFloat saturation = (float)arc4random() / UINT32_MAX;

    // Random brightness from 0.0 to 1.0

    CGFloat brightness = (float)arc4random() / UINT32_MAX;

    // Limit saturation and brightness to get a nice colors palette.
    // Remove the following 2 lines to generate a color from the full range.

    saturation = saturation < 0.5 ? 0.5 : saturation;
    brightness = brightness < 0.9 ? 0.9 : brightness;

    // Return a random UIColor.

    return [NSColor colorWithHue:hue
                      saturation:saturation
                      brightness:brightness
                           alpha:1];
}

@interface WDCollectionViewLayoutHelper :NSObject
+ (NSIndexSet *)arrayWithNumbersToIndexSet:(NSArray*) array;
+ (NSIndexSet *)intersectGraphicalRangeWithDatasetItemNumber:(NSRange)potentialRange andNumberOfItemsInDataset:(NSUInteger)itemsInDs;
+ (NSArray*)WDCalculateReloadIndicesSetsFromRealCacheIndices:(NSIndexSet *)cacheIndices
                                         realPrepareIndices:(NSIndexSet*)prepareIndices
                                         realVisibleIndices:(NSIndexSet*)visibleIndices;
+ (NSIndexSet *)WDIndexesWhichChanged:(NSDictionary*) dictionaryFromDatasource;
+ (CGRect) countFrameForItemAtIndex:(NSUInteger) index
                   withColumnCount:(NSUInteger) colCou
         withItemHorizontalSpacing:(CGFloat) hs
                      withItemSize:(CGSize) itemSize
           withItemVerticalSpacing:(CGFloat) vs;
@end

@implementation WDCollectionViewLayoutHelper
+(NSIndexSet *) arrayWithNumbersToIndexSet:(NSArray*) array{
    NSMutableIndexSet *result = [NSMutableIndexSet indexSet];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [result addIndex:[((NSNumber*)obj) unsignedIntegerValue]];
    }];
    return result;
}
+(NSIndexSet *)intersectGraphicalRangeWithDatasetItemNumber:(NSRange)potentialRange andNumberOfItemsInDataset:(NSUInteger)itemsInDs{
    NSRange datasetItemRange = NSMakeRange(0, itemsInDs);
    NSRange realRange = NSIntersectionRange(potentialRange, datasetItemRange);
    return [NSIndexSet indexSetWithIndexesInRange:realRange];
}

//ITEMS TO BE ASKED FOR CHANGES AND LATER RELOADED
//now we need to come up with which items should be reloaded (based on which items the data has changed for)
//order of asking for data reload matters, because in that order the images will be ordering async load. And we want user
//to see visible images in first order
//  visible range:              ----------
//  preload range:         -------------------
//    cache range:    ------------------------------
//                   |....|....|.........|....|.....|
//order of reload:     5    3       1       2    4
// 3 ranges in - 5 ranges out. Let's call it rangesInReloadOrder
+(NSArray*) WDCalculateReloadIndicesSetsFromRealCacheIndices:(NSIndexSet *)cacheIndices
                                          realPrepareIndices:(NSIndexSet*)prepareIndices
                                          realVisibleIndices:(NSIndexSet*)visibleIndices{

    NSMutableArray *res = [NSMutableArray array];
    [res addObject:visibleIndices];

    NSMutableIndexSet *mutablePrepare = [prepareIndices mutableCopy];
    [mutablePrepare removeIndexes:visibleIndices];
    [mutablePrepare enumerateRangesWithOptions:NSEnumerationReverse usingBlock:^(NSRange range, BOOL *stop) {
        [res addObject:[NSIndexSet indexSetWithIndexesInRange:range]];
    }];

    NSMutableIndexSet *mutableCache = [cacheIndices mutableCopy];
    [mutableCache removeIndexes:prepareIndices];
    [mutableCache enumerateRangesWithOptions:NSEnumerationReverse usingBlock:^(NSRange range, BOOL *stop) {
        [res addObject:[NSIndexSet indexSetWithIndexesInRange:range]];
    }];

    return res;
}

+(NSIndexSet *)WDIndexesWhichChanged:(NSDictionary*) dictionaryFromDatasource{
    NSMutableIndexSet *res = [NSMutableIndexSet indexSet];

    [dictionaryFromDatasource enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSUInteger keyU = [((NSNumber *) key) unsignedIntegerValue];
        NSUInteger valU = [((NSNumber *) obj) unsignedIntegerValue];
        if( valU == NSNotFound){
            [res addIndex:keyU];
        }
    }];
    return res;
}


+(CGRect) countFrameForItemAtIndex:(NSUInteger) index
                   withColumnCount:(NSUInteger) colCou
         withItemHorizontalSpacing:(CGFloat) hs
                      withItemSize:(CGSize) itemSize
           withItemVerticalSpacing:(CGFloat) vs{

    NSInteger rowNo = index/colCou;
    NSInteger colNo = index%colCou;

    CGFloat wid = itemSize.width;
    CGFloat hei = itemSize.height;
    CGFloat x = hs+colNo*(hs+wid);
    CGFloat y = vs+rowNo*(vs+hei);

    return CGRectMake(x, y, wid, hei);
}


@end

#endif
