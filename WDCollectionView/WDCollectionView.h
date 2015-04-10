//
//  WDCollectionView.h
//  WDCollectionView
//
//  Created by Fred on 06/04/15.
//  Copyright (c) 2015 wd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WDCollectionViewMainView, WDGridViewCell;
@class WDGridViewCell;


@protocol WDCollectionViewDataSource <NSObject>
@required
-(NSUInteger) numberOfItemsInCurrentDataset;
-(NSDictionary *)didItemsChange:(NSIndexSet*)indices;
-(WDGridViewCell*) itemForIndex:(NSUInteger) index;

@optional
- (NSView*) viewForEmptyDatasetForCollectionView:(WDCollectionViewMainView*)sender;
- (void) collectionView:(WDCollectionViewMainView *)collectionView willBeginEditingItemAtIndex:(NSUInteger)index;
- (void) collectionView:(WDCollectionViewMainView *)collectionView didEndEditingItemAtIndex:(NSUInteger)index;

@end

@protocol WDCollectionViewDelegate <NSObject>
@optional
- (void) collectionView:(WDCollectionViewMainView *)collectionView doubleClickedItemAtIndex:(NSUInteger)index;
- (void) collectionView:(WDCollectionViewMainView *)collectionView magnifiedWithEvent:(NSEvent*)event;
@end


@interface WDCollectionView : NSScrollView<WDCollectionViewDataSource, WDCollectionViewDelegate>

#pragma mark -
#pragma mark Public properties to manage visual attributes
@property (nonatomic) NSSize itemSize;
@property (nonatomic) BOOL useAspectAndWidth;
@property (nonatomic) CGFloat itemAspectOfWToH;


#pragma mark -
#pragma mark Data change handling
- (void) changedDatasource:(NSArray*)datasource withDatasourceId:(NSString*)datasourceID;   /* an user's extension of this class has to call this method after detecting a data change*/

#pragma mark -
#pragma mark Delegate and datasource for WDCollectionViewMain
-(id<WDCollectionViewDelegate>) viewDelegate;
-(id<WDCollectionViewDataSource>) viewDataSource;

-(NSURL*) getImageUrlFromRepresentedObject:(id) representedObject;


@end
