//
//  WDLocalPhotoCollectionViewController.m
//  FlickFlock
//
//  Created by Fred on 23/03/15.
//  Copyright (c) 2015 fred. All rights reserved.
//

#import "WDLocalPhotoCollectionViewController.h"
#import "WDLocalPhotoCollectionView.h"
#import "WDCollectionMainView.h"
#import "WDCollectionViewItem.h"
#import "WDCollectionViewDataItem.h"
#import "LocalPicture.h"
#import "Album.h"

#define LOG_LEVEL_DEF ddLogLevel
#import <CocoaLumberjack/CocoaLumberjack.h>
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface WDLocalPhotoCollectionViewController ()

@property (nonatomic, strong) NSString *currentDatasetId;
@property (readonly) WDLocalPhotoCollectionView* collectionView;
-(WDCollectionViewDataItem*) getDataItemAtIndex: (NSInteger) index;
-(void) commonInit;
+(NSString*) getItemUniqueKey:(WDCollectionViewDataItem*) dataItem datasetKey:(NSString*) currentDatasetKey;

-(void) forceMocToProcessChanges;
@end

@implementation WDLocalPhotoCollectionViewController{
    NSCache* _cacheForImages;
}

@dynamic collectionView;


#pragma mark -
#pragma mark Main implementation
-(WDLocalPhotoCollectionView*) collectionView{
    return  ((WDCollectionMainView*)[self view]).collectionView;
}

#pragma mark -
#pragma mark Setup
- (instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

-(void) commonInit{
    _cacheForImages = [[NSCache alloc]init];
}

-(void) awakeFromNib{
    [super awakeFromNib];
    [self addObserver:self
           forKeyPath:@"dataSourceArrayController.arrangedObjects"
              options:0
              context:nil];
}

/* The view to be loaded is assigned via IB */
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.collectionView setDataSource:self];
}

#pragma mark -
#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context{
    /* This means that the data could have changed. To be sure that the data is in sync,
     we're gonna carry out the layout and an update from THIS thread. */
    if([keyPath isEqualToString:@"dataSourceArrayController.arrangedObjects"]){
        if(!self.collectionView.isMocSavingNow){
            NSDate* start = [NSDate date];
            self.currentDatasetId=@"";
            if([self.albumArrayController.selectedObjects count]>0){
                self.currentDatasetId = ((Album*)[[[self albumArrayController] selectedObjects] firstObject]).absPath;
            }
            [self.dataSourceArrayController.arrangedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSLog(@"abs path = %@", ((LocalPicture*)obj).absPath);
            }];
            [self.collectionView refreshViewAfterDataSourceChange:self.currentDatasetId];
            NSLog(@"Total time of handling data change: %f", [[NSDate date] timeIntervalSinceDate:start]);
        }
    }
}

-(void)forceMocToProcessChanges{
    if ([self.dataSourceArrayController.arrangedObjects count]>0 && self.dataSourceArrayController.arrangedObjects[0]!=nil){
        LocalPicture * pic = self.dataSourceArrayController.arrangedObjects[0];
        [pic.managedObjectContext processPendingChanges];
    }
}

#pragma mark -
#pragma mark Handling the data
-(WDCollectionViewDataItem*) getDataItemAtIndex: (NSInteger) index{
    if(index >= [self.dataSourceArrayController.arrangedObjects count]) return nil;
    LocalPicture* showedPic =  self.dataSourceArrayController.arrangedObjects[index];
    
    WDCollectionViewDataItem *dataItem;
    if(showedPic){
        dataItem = [[WDCollectionViewDataItem alloc] init];
        dataItem.imagePath = showedPic.absPath;
        dataItem.representedObject = showedPic;
        dataItem.isVideo = [showedPic.isVideo boolValue];
    }
    return dataItem;
}

+(NSString*) getItemUniqueKey:(WDCollectionViewDataItem*) dataItem datasetKey:(NSString*) currentDatasetKey{
    return [NSString stringWithFormat:@"%@_%@",dataItem.imagePath,currentDatasetKey];
}

#pragma mark -
#pragma mark WDCollectionViewDataSource
-(WDCollectionViewItem*) itemAtIndex:(NSInteger)index{
    
    WDCollectionViewDataItem *dataItem = [self getDataItemAtIndex:index];
    if(!dataItem) return nil;
    
    WDCollectionViewItem *itemToReturn;
    NSString *itemKey = [WDLocalPhotoCollectionViewController getItemUniqueKey:dataItem datasetKey:self.currentDatasetId];
    if(!(itemToReturn = [self.collectionView cachedItemForKey:itemKey] )){
        
        itemToReturn = [[WDCollectionViewItem alloc] initForImageWithPath: dataItem.imagePath
                                                     forRepresentedObject: dataItem.representedObject
                                                  witchImageCacheProvider: self
                                                                  isVideo: dataItem.isVideo
                                                         forDatasetWithId: self.currentDatasetId];
        itemToReturn.itemKey = itemKey;
        
    }else{
        DDLogVerbose(@"got an item from cache.");
    }
    
    //if the view is asking us, we need to de-layout the item. //MAYBE.
    return itemToReturn;
}

-(NSInteger) itemCount{
    return [(NSArray*)[self.dataSourceArrayController arrangedObjects]count];
}

/* This can take some time, it doesn't bother us*/
-(NSInteger) indexOfItemForRepresentedObject: (NSObject*) representedObject{
    NSInteger ind;
    ind =  [self.dataSourceArrayController.arrangedObjects indexOfObject:representedObject];

    
    if(ind== NSNotFound){
        return -1;
    }else{
        return ind;
    }
}

#pragma mark WDCollectionViewCacheProvider
-(NSCache*) cacheForLoadedImages{
    return  _cacheForImages;
}

@end
