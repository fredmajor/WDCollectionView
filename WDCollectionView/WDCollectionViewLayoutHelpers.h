//
//  WDCollectionViewLayoutHelpers.h
//  FlickFlock
//
//  Created by Fred on 04/04/15.
//  Copyright (c) 2015 fred. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WDCollectionUtils.h"

@interface WDCollectionViewLayoutHelpers : NSObject

+(NSInteger) totalAmountOfRowsToFitItems:(NSInteger) itemCount
                         withNumberOfColumns:(NSInteger) columnNumber;

+(CGRect) geFrameSizeToFitNumberOfItems: (NSInteger) itemCount
                     intoNumberOfColumns: (NSInteger) columnCount
                           withViewWidth: (CGFloat) width
                              itemHeigth: (CGFloat) itHeight
                     verticalITemSpacing: (CGFloat) vertSpacing;

+(WDRowRange) rowsVisibleInPartOfView: (CGRect) visiblePart
                        forItemHeight: (CGFloat) itemHei
               andVerticalItemSpacing: (CGFloat) verSpacing;

+(WDRowRange) rowsInVisiblePartOfView: (CGRect) visiblePart
                      extendedOnTopBy: (CGFloat) extensionTop
                   extendedOnBottomBy: (CGFloat) extensionBottom
                        forItemHeight: (CGFloat) itemHeight
               andItemVerticalSpacing: (CGFloat) iVerticalSpacing;

+(WDCellRange) cellRangeWithOverflowCheckVisibleInRowRange: (WDRowRange) rowRange
                                            forColumnCount: (NSInteger) colCount
                                 andItemsInCollectionTotal: (NSInteger) itemCount;

+(NSInteger) rowsPossibleOnTheViewWithHeight: (CGFloat) viewH
                      forItemVerticalSpacing: (CGFloat) itemVerSpacing
                               andItemHeight: (CGFloat) itemHeight;

+(NSInteger) columnCountForViewWithWidth: (CGFloat) viewWidth
             andItemHorizontalSpacingMin: (CGFloat) itemMinHorSpacing
                            forItemWidth: (CGFloat) itemWidth;

+(CGFloat) itemHorizontalSpacingForItemWidth: (CGFloat) itemWidth
                              andColumnCount: (NSInteger) columnCount
                           onScreenWithWidth: (CGFloat) screenW;

+(CGRect) countFrameForItemAtIndex:(NSInteger) index
                   withColumnCount:(NSInteger) colCou
         withItemHorizontalSpacing:(CGFloat) hs
                     withItemWidth:(CGFloat) wid
                    withItemHeigth:(CGFloat) hei
           withItemVerticalSpacing:(CGFloat) vs;

+(NSArray*) layoutItems:(NSArray*) items
         forViewIndices:(WDCellRange)indexRange
    withCurrentColCount:(NSInteger) colCount
currentItemHorizontalSpacing:(CGFloat) currItemHorSpacing
              itemWidth:(CGFloat) itemW
             itemHeight:(CGFloat) itemH
    itemVerticalSpacing:(CGFloat) vertSpacing;

@end
