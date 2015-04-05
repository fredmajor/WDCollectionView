//
//  WDCollectionViewImage.h
//  FlickFlock
//
//  Created by Fred on 26/03/15.
//  Copyright (c) 2015 fred. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WDCollectionViewImage;
#define wdCollectionLoadingThreads 3
#define wdCollectionThumbnailMaxSize 300
#define wdCollectionLoadThrottleTimeSleep 0.0f


@protocol WDCollectionViewImageCallback <NSObject>
@required
-(BOOL) isImageStillInPreloadArea: (WDCollectionViewImage*) image;
-(void) imageFinishedLoading;
@end

//preloads image data on demand. Caches loaded data
@interface WDCollectionViewImage : NSObject

//returns image data if the image is loaded; returns nil otherwise
@property(nonatomic) CGImageRef imageToDisplay;
@property(strong, nonatomic) NSString *imagePath;
@property(nonatomic) BOOL isVideo;

-(instancetype)initWithImagePath:(NSString*) imPath
                        andCache:(NSCache*) cache
                         isVideo:(BOOL) isV
              withCallbackTarger:(id<WDCollectionViewImageCallback>) callbackTarget;

//called externally to start loading image data from imagePath.
//Caches the data once loaded
-(void) loadImage;


//tries to cancel load of this item (if possible)
-(void) cancelLoad;


//has to handle both cache and local pointer
-(void) releaseImageData;

@end
