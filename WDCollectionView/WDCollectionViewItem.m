//
//  WDCollectionViewItem.m
//  FlickFlock
//
//  Created by Fred on 23/03/15.
//  Copyright (c) 2015 fred. All rights reserved.
//

#import "WDCollectionViewItem.h"
#import "WDCollectionViewImage.h"



@implementation WDCollectionViewItem{
    NSString *_imagePath;
    __weak NSObject *_repObject;
    BOOL _isVideo;
    id<WDCollectionViewCacheProvider> _imageCacheProvider;
    NSString *_datasetID;
    CALayer *_imageLayer;
    
    WDCollectionViewImage* _image;  //this doesn't back any property
}

@synthesize imagePath = _imagePath;
@synthesize representedObject = _repObject;
@synthesize isVideo = _isVideo;
@synthesize cacheProvider = _imageCacheProvider;
@synthesize datasetId = _datasetID;
@dynamic  imageToDisplay;
@synthesize imageLayer = _imageLayer;
@synthesize itemCallback;
@synthesize lastDisplayedIndex;
@synthesize itemFrame;
@synthesize itemKey;

/* This is a designated constructor */
- (instancetype)initForImageWithPath: (NSString*) imPath
                forRepresentedObject: (NSObject*) repObject
             witchImageCacheProvider: (id<WDCollectionViewCacheProvider>) provider
                             isVideo: (BOOL) isVideo
                    forDatasetWithId: (NSString *)datasetId{
    
    self = [super init];
    if (self) {
        _imageCacheProvider = provider;
        _isVideo = isVideo;
        _imagePath = imPath;
        _repObject = repObject;
        _datasetID = datasetId;
        _imageLayer = nil;
        _imageLayer.frame = CGRectZero;
        self.itemFrame = CGRectZero;
      //  [_imageLayer setNeedsDisplayOnBoundsChange:YES];
    }
    return self;
}

/* So far doesn't have to be thread-safe */
-(void) reachedPreloadArea{
    if(!_image){
        _image = [[WDCollectionViewImage alloc] initWithImagePath:_imagePath
                                                         andCache: [_imageCacheProvider cacheForLoadedImages]
                                                          isVideo:_isVideo
                                                withCallbackTarger:self];
    }
    [_image loadImage];
}

-(CGImageRef) imageToDisplay{
    return [_image imageToDisplay];
}


#pragma mark -
#pragma mark WDCollectionViewImageCallback
-(BOOL) isImageStillInPreloadArea:(WDCollectionViewImage *)image{
    if(self.itemCallback){
        return [self.itemCallback isItemInPreloadArea:self];
    }
    return YES;
}

/* I can add checking if an item is in prerender area here */
-(void) imageFinishedLoading{
    _imageLayer = [CALayer layer];
    [self.imageLayer setContents: (id)self.imageToDisplay];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.imageLayer setFrame:self.itemFrame];
        [self.itemCallback itemFinishedLoadingImage:self];
    });
    [CATransaction flush];
}



@end
