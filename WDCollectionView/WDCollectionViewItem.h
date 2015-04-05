//
//  WDCollectionViewItem.h
//  FlickFlock
//
//  Created by Fred on 23/03/15.
//  Copyright (c) 2015 fred. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "WDCollectionViewImage.h"
@class WDCollectionViewItem;

@protocol WDCollectionViewCacheProvider <NSObject>
@required
-(NSCache*) cacheForLoadedImages;
@end

@protocol WDCollectionViewItemCallback <NSObject>
-(BOOL) isItemInPreloadArea: (WDCollectionViewItem*) item;
-(void) itemFinishedLoadingImage: (WDCollectionViewItem*) source;
@end

#pragma mark -
#pragma mark Item's interface
@interface WDCollectionViewItem : NSObject <WDCollectionViewImageCallback>

@property (nonatomic, strong, readonly)     NSString* imagePath;
@property (nonatomic, weak, readonly)       NSObject* representedObject;
@property (nonatomic, readonly)             BOOL isVideo;
@property (nonatomic, readonly)             id<WDCollectionViewCacheProvider> cacheProvider;
@property (nonatomic, strong, readonly)     NSString *datasetId;
@property (nonatomic, readonly)             CGImageRef imageToDisplay;
@property (nonatomic, readonly)             CALayer *imageLayer;

@property (nonatomic, weak) id<WDCollectionViewItemCallback> itemCallback; //gets set after object is created
@property (nonatomic) NSInteger lastDisplayedIndex;     //gets set during layout
@property (nonatomic) CGRect itemFrame;  /* don't set position on the CALayer directly! Instead do it here */
@property (nonatomic,strong) NSString* itemKey;

/* WDCollectionViewItem gets created in CollectionViewController, nowhere else.
 * This is a designated constructor.
 */
- (instancetype)initForImageWithPath: (NSString*) imPath
                forRepresentedObject: (NSObject*) repObject
             witchImageCacheProvider: (id<WDCollectionViewCacheProvider>) provider
                             isVideo: (BOOL) isVideo
                    forDatasetWithId: (NSString*) datasetId;


/* Called from CollectionView to inform this item on entering the preload area */
-(void) reachedPreloadArea;


@end
