//
//  WDCollectionUtils.h
//  FlickFlock
//
//  Created by Fred on 02/04/15.
//  Copyright (c) 2015 fred. All rights reserved.
//

#ifndef FlickFlock_WDCollectionUtils_h
#define FlickFlock_WDCollectionUtils_h

#import <Cocoa/Cocoa.h>
#define RECTLOG(rect)    (NSLog(@""  #rect @" x:%f y:%f w:%f h:%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height ));


#pragma mark -
#pragma mark Range&Index C-style helpers
typedef struct RowRangeStruct{
    NSInteger minrow;
    NSInteger rownumber;
}WDRowRange;

typedef struct CellRangeStruct{
    NSInteger mincell;
    NSInteger cellnumber;
}WDCellRange;

typedef struct IndexPairStruct{
    NSInteger first;
    NSInteger last;
}WDIndexPair;

static inline WDCellRange WDMakeCellRangeForIndexPair (WDIndexPair pair){
    WDCellRange range;
    range.mincell = pair.first;
    range.cellnumber = pair.last - pair.first + 1;
    if(range.cellnumber<0) range.cellnumber = 0;
    return range;
}
static inline WDRowRange  WDMakeRowRangeForIndexPair(WDIndexPair pair){
    WDRowRange range;
    range.minrow = pair.first;
    range.rownumber = pair.last - pair.first + 1;
    return  range;
}
static inline WDIndexPair WDMakeIndexPairFromCellRange(WDCellRange range){
    WDIndexPair pair;
    pair.first = range.mincell;
    pair.last = range.mincell + range.cellnumber -1;
    return pair;
}
static inline WDIndexPair WDMakeIndexPairFromRowRange(WDRowRange range){
    WDIndexPair pair;
    pair.first = range.minrow;
    pair.last = range.minrow + range.rownumber -1;
    return pair;
}
static inline WDCellRange WDMakeCellRangeWithMincell(NSInteger mincell, NSInteger cellnumber){
    WDCellRange range;
    range.mincell = mincell;
    range.cellnumber = cellnumber;
    return  range;
}
static inline WDRowRange WDMakeRowRangeWithMinRow(NSInteger minrow, NSInteger rownumber){
    WDRowRange range;
    range.minrow = minrow;
    range.rownumber = rownumber;
    return range;
}
static inline WDIndexPair WDMakeIndexPairWithFirst(NSInteger first, NSInteger last){
    WDIndexPair pair;
    pair.first = first;
    pair.last = last;
    return pair;
}


#pragma mark - 
#pragma mark Item arrays

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


#endif
