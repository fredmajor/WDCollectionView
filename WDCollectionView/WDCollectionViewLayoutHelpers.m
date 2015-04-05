//
//  WDCollectionViewLayoutHelpers.m
//  FlickFlock
//
//  Created by Fred on 04/04/15.
//  Copyright (c) 2015 fred. All rights reserved.
//

#import "WDCollectionViewLayoutHelpers.h"
#import "WDCollectionUtils.h"
#import "WDCollectionViewItem.h"

@implementation WDCollectionViewLayoutHelpers

+ (NSInteger) totalAmountOfRowsToFitItems:(NSInteger) itemCount
                         withNumberOfColumns:(NSInteger) columnNumber{
    return ceil((double)itemCount / (double)columnNumber);
}

+ (CGRect) geFrameSizeToFitNumberOfItems: (NSInteger) itemCount
                     intoNumberOfColumns: (NSInteger) columnCount
                           withViewWidth: (CGFloat) width
                              itemHeigth: (CGFloat) itHeight
                     verticalITemSpacing: (CGFloat) vertSpacing{
    CGFloat heigth;
    NSInteger totalRows = [WDCollectionViewLayoutHelpers
                           totalAmountOfRowsToFitItems:itemCount
                           withNumberOfColumns:columnCount];
    NSLog(@"total rows to fit stuff: %ld", totalRows);
    heigth = totalRows*(itHeight+vertSpacing) + vertSpacing;
    CGRect properFrame = NSMakeRect(0, 0, width, heigth);
    return properFrame;
}

+(WDRowRange) rowsInVisiblePartOfView: (CGRect) visiblePart
                      extendedOnTopBy: (CGFloat) extensionTop
                   extendedOnBottomBy: (CGFloat) extensionBottom
                        forItemHeight: (CGFloat) itemHeight
               andItemVerticalSpacing: (CGFloat) iVerticalSpacing{
    //  CGRect visible = [self getVisibleRectOfCollView];
    
    CGFloat findX = visiblePart.origin.x;
    CGFloat findY = visiblePart.origin.y - extensionTop;
    CGFloat findW = visiblePart.size.width;
    CGFloat findH = visiblePart.size.height + extensionTop + extensionBottom;
    
    CGRect rectToFindRows = CGRectMake(findX, findY, findW, findH);
    WDRowRange rowsOfInterest = [WDCollectionViewLayoutHelpers rowsVisibleInPartOfView:rectToFindRows forItemHeight:itemHeight andVerticalItemSpacing:iVerticalSpacing];
    return rowsOfInterest;
}

//This is pure math, based on item sizes
+(WDRowRange) rowsVisibleInPartOfView: (CGRect) visiblePart
                        forItemHeight: (CGFloat) itemHei
               andVerticalItemSpacing: (CGFloat) verSpacing{
    
    NSInteger nmin, nmax;  //min and max rows to be visible, starting from 0
    CGFloat yrmin = visiblePart.origin.y;
    if(yrmin<0) yrmin=0;                            //FIXME - to moze byc zle
    CGFloat yrmax = visiblePart.origin.y + visiblePart.size.height;
    
    nmin = floor((yrmin - verSpacing)/(verSpacing+itemHei));
    if(nmin<0) nmin=0;
    nmax = floor((yrmax-verSpacing)/(verSpacing+itemHei));
    return WDMakeRowRangeForIndexPair(WDMakeIndexPairWithFirst(nmin, nmax));
}

+(WDCellRange) cellRangeWithOverflowCheckVisibleInRowRange: (WDRowRange) rowRange
                                            forColumnCount: (NSInteger) colCount
                                 andItemsInCollectionTotal: (NSInteger) itemCount{
    if(itemCount<=0) return WDMakeCellRangeWithMincell(0, 0);
    NSInteger cellMin = rowRange.minrow * colCount;
    if(cellMin<0) cellMin=0;
    WDIndexPair rowRangeIndices =  WDMakeIndexPairFromRowRange(rowRange);
    NSInteger maxRow = rowRangeIndices.last;
    NSInteger celMax = maxRow * colCount + colCount -1;
    if(celMax >= itemCount) celMax = itemCount-1;
    if(celMax < 0) celMax=0;
    return WDMakeCellRangeForIndexPair(WDMakeIndexPairWithFirst(cellMin, celMax));
}

+(NSInteger) rowsPossibleOnTheViewWithHeight: (CGFloat) viewH
                      forItemVerticalSpacing: (CGFloat) itemVerSpacing
                               andItemHeight: (CGFloat) itemHeight{
    NSInteger rowNo = ceil((viewH-itemVerSpacing)/(itemHeight+itemVerSpacing));
    return rowNo;
}

//this says how many cols can fit in current layout
+(NSInteger) columnCountForViewWithWidth: (CGFloat) viewWidth
             andItemHorizontalSpacingMin: (CGFloat) itemMinHorSpacing
                            forItemWidth: (CGFloat) itemWidth{
    NSInteger colNo = floor((viewWidth-itemMinHorSpacing)/(itemWidth+itemMinHorSpacing));
    return colNo;
}

+(CGFloat) itemHorizontalSpacingForItemWidth: (CGFloat) itemWidth
                              andColumnCount: (NSInteger) columnCount
                           onScreenWithWidth: (CGFloat) screenW{
    CGFloat fw = screenW;
    CGFloat x = columnCount;
    CGFloat w = itemWidth;
    CGFloat horSp = (fw-x*w)/(x+1.0f);
    return horSp;
}

+(CGRect) countFrameForItemAtIndex:(NSInteger) index
                   withColumnCount:(NSInteger) colCou
         withItemHorizontalSpacing:(CGFloat) hs
                     withItemWidth:(CGFloat) wid
                    withItemHeigth:(CGFloat) hei
           withItemVerticalSpacing:(CGFloat) vs{
    
    NSInteger rowNo = index/colCou;
    NSInteger colNo = index%colCou;
    
    CGFloat x = hs+colNo*(hs+wid);
    CGFloat y = vs+rowNo*(vs+hei);
    
    return CGRectMake(x, y, wid, hei);
}

//returns an array of rectangles to be refreshed (or items, dunno yet)
+(NSArray*) layoutItems:(NSArray*) items
         forViewIndices:(WDCellRange)indexRange
    withCurrentColCount:(NSInteger) colCount
currentItemHorizontalSpacing:(CGFloat) currItemHorSpacing
              itemWidth:(CGFloat) itemW
             itemHeight:(CGFloat) itemH
    itemVerticalSpacing:(CGFloat) vertSpacing{
    
    NSMutableArray *cgRectsToRedraw = [NSMutableArray array];  //to redraw
    if([items count] != indexRange.cellnumber) NSLog(@"WRONG ITEMS VS RANGE!!");
    NSInteger itemIndex=indexRange.mincell;
    
    for(WDCollectionViewItem* item in items){
        
        CGRect newFrame = [WDCollectionViewLayoutHelpers countFrameForItemAtIndex: itemIndex
                                                                  withColumnCount: colCount
                                                        withItemHorizontalSpacing: currItemHorSpacing
                                                                    withItemWidth: itemW
                                                                   withItemHeigth: itemH
                                                          withItemVerticalSpacing: vertSpacing];
        
        if(!CGRectEqualToRect(newFrame, item.itemFrame)){
            [cgRectsToRedraw addObject: [NSValue valueWithRect: newFrame]];
            [cgRectsToRedraw addObject: [NSValue valueWithRect: item.itemFrame]];
            //            CGPoint newPos = CGPointMake(newFrame.origin.x+ floor(newFrame.size.width/2.0f), newFrame.origin.y+floor(newFrame.size.height/2.0f));
            //            CABasicAnimation* posAnim = [CABasicAnimation animationWithKeyPath:@"position"];
            //            posAnim.fromValue = [NSValue valueWithPoint: NSPointFromCGPoint(item.imageLayer.position)];
            //            posAnim.toValue = [NSValue valueWithPoint: NSPointFromCGPoint(newPos)];
            //            posAnim.duration = 0.1;
            //
            //  item.imageLayer.position = newPos;
            //            [item.imageLayer addAnimation:posAnim forKey:@"position"];
            //            item.imageLayer.bounds = CGRectMake(0,0,newFrame.size.width, newFrame.size.height);
            item.itemFrame = newFrame;
            
        }
        item.lastDisplayedIndex = itemIndex;
        
        itemIndex++;
    }
    return cgRectsToRedraw;
}

@end
