//
//  WDCollectionView.m
//  WDCollectionView
//
//  Created by Fred on 06/04/15.
//  Copyright (c) 2015 wd. All rights reserved.
//

#import "WDCollectionView.h"
#import "WDCollectionViewMainView.h"
#import "WDGridViewMainCell.h"


#pragma mark -
#pragma mark Private interface

@interface WDCollectionView()
-(void) commonInit;
@property (weak, nonatomic) NSArray* WD_currentDatasource;
@property (strong, nonatomic) NSString* WD_currentDatasourceId;

- (WDGridViewMainCell *)tryToFindItemAskedForAtDifferentIndex:(NSUInteger)askedIndex;
- (void)initForNewDataset;
@end

@implementation WDCollectionView{
    WDCollectionViewMainView *_mainCollectionView;
    NSCache* _cacheForImages;
    NSMutableDictionary *_cachedUidsOfDataItemsForIndices;
    NSMutableSet *_knownDatasets;
}
//public
@synthesize itemSize;
@synthesize useAspectAndWidth;
@synthesize itemAspectOfWToH;

//private
@synthesize WD_currentDatasource;
@synthesize WD_currentDatasourceId;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

-(void) commonInit{
    _cacheForImages = [[NSCache alloc]init];
    _cachedUidsOfDataItemsForIndices = [NSMutableDictionary dictionary];
    _knownDatasets = [NSMutableSet set];
    [self setHasHorizontalScroller:NO];
    [self setHasVerticalScroller:YES];
    [self setBorderType:NSNoBorder];
    [self setAutohidesScrollers:YES];
    [self setVerticalScrollElasticity:NSScrollElasticityAutomatic];
    [self setHorizontalScrollElasticity:NSScrollElasticityNone];
    [[self contentView]setPostsBoundsChangedNotifications:YES];
    [[self contentView]setPostsFrameChangedNotifications:YES];
    [self.contentView setCopiesOnScroll:NO];
    [self setAutoresizesSubviews:NO];
    [self setAutoresizingMask:NSViewNotSizable];
    
    /* Create the main collection view */
    _mainCollectionView = [[WDCollectionViewMainView alloc] initWithFrame:self.bounds andScrollView:self];
    [_mainCollectionView setDataSource:[self viewDataSource]];
    [_mainCollectionView setDelegate:[self viewDelegate]];
    [self setDocumentView:_mainCollectionView];
    
    NSLog(@"WDCollectionView - common init done");
}

- (void)initForNewDataset{
    _cachedUidsOfDataItemsForIndices[self.WD_currentDatasourceId] = [NSMutableDictionary dictionary];
}

/* This has to return an NSDictionary with indices of changed items. The Data source should maintain
 * a local memory of past hashes or keys of items present in indices. The Data source should also
 * be tracking, when an item just gets shifted to a different index.
 * The index set can contain less indices then the range asked for. That means there is less data then
 * the view can accommodate. This is not a problem, this is a protocol.
 */
/* Returns NSNotFound (require reload) if a data item changed, or the item is not in use and require reload.
   The view calls this method only if it wants to display the items in question. */
-(NSDictionary *)doItemsRequireReload:(NSIndexSet*)indices{
   // NSLog(@"Datasource says: view just asked me to check for changes in index set of length %lu", [indices count]);
    NSUInteger itemsInDataset = [self numberOfItemsInCurrentDataset];
    NSRange datasetRange =  NSMakeRange(0, itemsInDataset);
    NSIndexSet *datasetIndexSet = [NSIndexSet indexSetWithIndexesInRange:datasetRange];
    NSIndexSet *availableIndexSet = [indices indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
        return [datasetIndexSet containsIndex:idx];
    }];
    
    NSMutableDictionary *response = [NSMutableDictionary dictionaryWithCapacity:[availableIndexSet count]];
    [availableIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {

        id newDataItemIdForIndexInQuestion = [[self class] uniqueIdOfDataObject:self.WD_currentDatasource[idx]];
        id cachedDataItemIdForIndexInQuestion = _cachedUidsOfDataItemsForIndices[self.WD_currentDatasourceId][[NSNumber numberWithUnsignedInteger:idx]];
        id inUseItem = [_mainCollectionView inUseItemForIndex:idx];
        if([newDataItemIdForIndexInQuestion isEqual:cachedDataItemIdForIndexInQuestion] && inUseItem){
            response[[NSNumber numberWithUnsignedInteger:idx]] = [NSNumber numberWithUnsignedInteger:1];
        }else{
            response[[NSNumber numberWithUnsignedInteger:idx]] = [NSNumber numberWithUnsignedInteger:NSNotFound];
        }
        
    }];
    return [NSDictionary dictionaryWithDictionary:response];
}

-(WDGridViewCell*) itemForIndex:(NSUInteger) index {
    WDGridViewMainCell *cell;
    cell = [self tryToFindItemAskedForAtDifferentIndex:index];
    if(cell)NSLog(@"Controller found item asked for at a different index.");
    
    if(!cell){
        cell = [_mainCollectionView dequeueReusableCell];
        if(cell)NSLog(@"Controller dequeued a reusable item");
        if(!cell){
            cell = [[NSClassFromString([[self class] classNameToUseAsMainCell]) alloc]init];
            NSLog(@"Controller created a new item");
        }
        
        id object = [self.WD_currentDatasource objectAtIndex:index];
        cell.representedObject = object;
        cell.delegate = self;
        cell.itemCallback = _mainCollectionView;
        cell.cacheProvider = self;
    }
    id newDataItemIdForIndexInQuestion = [[self class] uniqueIdOfDataObject:self.WD_currentDatasource[index]];
    NSArray *oldKeysToRemove =  [_cachedUidsOfDataItemsForIndices[self.WD_currentDatasourceId] allKeysForObject:newDataItemIdForIndexInQuestion];
    [_cachedUidsOfDataItemsForIndices[self.WD_currentDatasourceId] removeObjectsForKeys:oldKeysToRemove];
    _cachedUidsOfDataItemsForIndices[self.WD_currentDatasourceId][[NSNumber numberWithUnsignedInteger:index]] = newDataItemIdForIndexInQuestion;
    return cell;
}

-(WDGridViewMainCell *)tryToFindItemAskedForAtDifferentIndex:(NSUInteger)askedIndex{
    id newDataItemIdForIndexInQuestion = [[self class] uniqueIdOfDataObject:self.WD_currentDatasource[askedIndex]]; //potrzebujemy itema z takim key. Pytanie gdzie/czy on wczesniej byl
    NSArray* oldIndicesForAskedItem =  [_cachedUidsOfDataItemsForIndices[self.WD_currentDatasourceId] allKeysForObject:newDataItemIdForIndexInQuestion];
    if([oldIndicesForAskedItem count] == 1){
        NSUInteger oldIndexOfTheItem = [((NSNumber*)[oldIndicesForAskedItem firstObject]) unsignedIntegerValue];
    //    NSLog(@"seems like an item from index %lu was before at index %lu", (unsigned long)askedIndex, oldIndexOfTheItem);
        WDGridViewMainCell* oldItemForNewIdex = [_mainCollectionView inUseItemForIndex:oldIndexOfTheItem];
        [_mainCollectionView removeInUseItemForIndex:oldIndexOfTheItem];    //now the item is not dequeued but also not visible under its old index
        return oldItemForNewIdex;
    }else if([oldIndicesForAskedItem count] == 0){
        return nil;
    }else{
        NSLog(@"Something is wrong in here! Like the same item was displayed @ more than 1 index!!!");
        return nil;
    }
}

- (void)changedDatasource:(NSArray *)datasource withDatasourceId:(NSString *)datasourceID {
    NSLog(@"User just reported a data change. Let's roll.");
    if(datasourceID==nil)datasourceID= WDCollectionNilDataset;

    self.WD_currentDatasource = datasource;
    self.WD_currentDatasourceId = datasourceID;
    if(![_knownDatasets containsObject:datasourceID]){
        [self initForNewDataset];
        [_knownDatasets addObject:datasourceID];
    }
    [_mainCollectionView datasetChanged:datasourceID];
}

-(NSUInteger) numberOfItemsInCurrentDataset{
    return [self.WD_currentDatasource count];
}

#pragma mark -
#pragma mark Delegate and datasource for WDCollectionViewMain
-(id<WDCollectionViewDelegate>) viewDelegate{           /*user can override in order to use a different object */
    return self;
}

-(id<WDCollectionViewDataSource>)viewDataSource {       /*user can override in order to use a different object */
    return self;
}

/* Overloaded in a subclass*/
+ (NSString*)classNameToUseAsMainCell{
    return @"WDGridViewMainCell";
}

-(NSCache*) cacheForLoadedImages{
    return _cacheForImages;
}

/* Overloaded in a subclass*/
+ (id)uniqueIdOfDataObject:(id)dataObject{
    return nil;
}

@end
