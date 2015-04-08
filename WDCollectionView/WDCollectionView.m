//
//  WDCollectionView.m
//  WDCollectionView
//
//  Created by Fred on 06/04/15.
//  Copyright (c) 2015 wd. All rights reserved.
//

#import "WDCollectionView.h"
#import "WDCollectionViewMainView.h"
#import "WDCollectionViewItem.h"

#define WDCollectionNilDataset @"__WD_NIL_DATASET_ID"


#pragma mark -
#pragma mark Private interface

@interface WDCollectionView()
-(void) commonInit;
@property (weak, nonatomic) NSArray* WD_currentDatasource;
@property (strong, nonatomic) NSString* WD_currentDatasourceId;
@end

@implementation WDCollectionView{
    WDCollectionViewMainView *_mainCollectionView;
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
    [self setHasHorizontalScroller:NO];
    [self setHasVerticalScroller:YES];
    [self setBorderType:NSNoBorder];
    [self setAutohidesScrollers:YES];
    [self setVerticalScrollElasticity:NSScrollElasticityAutomatic];
    [self setHorizontalScrollElasticity:NSScrollElasticityNone];
    [[self contentView]setPostsBoundsChangedNotifications:YES];
    [self.contentView setCopiesOnScroll:NO];
    [self setAutoresizesSubviews:NO];
    [self setAutoresizingMask:NSViewNotSizable];
    
    /* Create the main collection view */
    _mainCollectionView = [[WDCollectionViewMainView alloc] initWithFrame:self.bounds
                                                            andScrollView:self];
    [_mainCollectionView setDataSource:[self viewDataSource]];
    [_mainCollectionView setDelegate:[self viewDelegate]];
    NSLog(@"WDCollectionView - common init done");

}

/* This has to return an NSDictionary with indices of changed items. The Data source should maintain
 * a local memory of past hashes or keys of items present in indices. The Data source should also
 * be tracking, when an item just gets shifted to a different index.
 * The index set can contain less indices then the range asked for. That means there is less data then
 * the view can accommodate. This is not a problem, this is a protocol.
 */
-(NSDictionary *)didItemsChange:(NSIndexSet*)indices{
    NSLog(@"Datasource says: view just asked me to check for changes in index set of length %lu", [indices count]);
    NSUInteger itemsInDataset = [self numberOfItemsInCurrentDataset];
    NSRange datasetRange =  NSMakeRange(0, itemsInDataset);
    NSIndexSet *datasetIndexSet = [NSIndexSet indexSetWithIndexesInRange:datasetRange];
    NSIndexSet *availableIndexSet = [indices indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
        return [datasetIndexSet containsIndex:idx];
    }];

    NSMutableDictionary *response = [NSMutableDictionary dictionaryWithCapacity:[availableIndexSet count]];
    [availableIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        //TODO - so far doesn't check which items really changed!
        response[[NSNumber numberWithUnsignedInteger:idx]] = [NSNumber numberWithUnsignedInteger:NSNotFound];
    }];
    return [NSDictionary dictionaryWithDictionary:response];
}

- (WDCollectionViewItem *)itemForIndex:(NSUInteger)index {
    return nil;
}

- (void)changedDatasource:(NSArray *)datasource withDatasourceId:(NSString *)datasourceID {
    NSLog(@"User just reported a data change. Let's roll.");
    if(datasourceID==nil)datasourceID= WDCollectionNilDataset;

    self.WD_currentDatasource = datasource;
    self.WD_currentDatasourceId = datasourceID;
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
@end