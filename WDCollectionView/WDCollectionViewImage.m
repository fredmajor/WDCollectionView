//
//  WDCollectionViewImage.m
//  FlickFlock
//
//  Created by Fred on 26/03/15.
//  Copyright (c) 2015 fred. All rights reserved.
//

#import "WDCollectionViewImage.h"
#import <AVFoundation/AVFoundation.h>
#import "WDCollectionViewItem.h"



@interface WDCollectionViewImage()

//does low-level load of image thumbnail
+(CGImageRef) getThumbnailForImageIO: (NSString*)imagePath heigth:(int)h;
+(CGImageRef) getThumbnailForVideo: (NSString*) videoPath heigth:(NSInteger) h;

- (void) startImageLoadOperation;
-(BOOL) amIStillInPreloadArea;  //a callback to make sure if the load is still needed


///////////////////////
//operation queue
- (NSBlockOperation *) getActiveLoadOperationForMe;
- (BOOL) isAlreadyAnActiveLoadOperationForMe;
+(NSOperationQueue*) imageLoadOperationQueue;   //singleton queue for loading files, one for all instances of this class
@property (atomic) BOOL loadOrdered;
-(BOOL) handleCancelIfNeeded:(NSBlockOperation*) blockOperation withComment:(NSString *)str;
-(BOOL) handleCancelIfNeeded:(NSBlockOperation*) blockOperation;

@end

#pragma mark -
#pragma mark IMPLEMENTATION
@implementation WDCollectionViewImage{
    CGImageRef _imageToDisplay;
    NSCache *_imCache;
    id<WDCollectionViewImageCallback> _callbackTarger;
}

@dynamic imageToDisplay;
@synthesize imagePath;
@synthesize isVideo;

static int _cancelCounter;

- (instancetype)initWithImagePath:(NSString*) imPath
                         andCache:(NSCache*) cache
                          isVideo:(BOOL)isV
               withCallbackTarger:(id<WDCollectionViewImageCallback>)callbackTarget{
    self = [super init];
    if(self){
        self.imagePath = imPath;
        _imCache = cache;
        self.isVideo = isV;
        _callbackTarger = callbackTarget;
    }
    return self;
}

//public
-(void) loadImage{
    
    //cache is already handled here
    if(self.imageToDisplay){
       // NSLog(@"Image already loaded.");
        return;
    }
    
    //there is already a queued load operation, which is not cancelled.
    if([self isAlreadyAnActiveLoadOperationForMe]){
     //   NSLog(@"There's already an active load operation for me. My path=%@", self.imagePath);
        return;
    }
    
    //the load process is already ordered, but has not created an active operation yet.
    //with single-threaded calls to this method this shouldn't happen
    if([self loadOrdered]){
        NSLog(@"Load already ordered, but not started yet");
        return;
    }
    
    [self startImageLoadOperation];
}

-(void) cancelLoad{
    NSBlockOperation * myOper = [self getActiveLoadOperationForMe];
    if(myOper != nil){
        [myOper cancel];
        NSLog(@"cancelled no %d", ++_cancelCounter);
    }
}

-(void) releaseImageData{
    if(_imCache){
        [_imCache removeObjectForKey:self.imagePath];
    }
    _imageToDisplay = nil;
}

-(CGImageRef) imageToDisplay{
    if(_imCache){
        //NO increase to the retain count
        CGImageRef cachedIm = (__bridge CGImageRef)([_imCache objectForKey:self.imagePath]);
        return cachedIm;
    }else{
        return _imageToDisplay;
    }
}


#pragma mark -
#pragma mark private handling of image load
- (void) startImageLoadOperation{
    self.loadOrdered = YES;
   // NSLog(@"Ordering a load operation for a path:%@", self.imagePath);
    
    NSBlockOperation    *loadImOperation = [[NSBlockOperation alloc]init];

    if(!self.imagePath){
        self.loadOrdered = NO;
        return;
    }
    loadImOperation.name = [NSString stringWithString: self.imagePath];
    
    __weak NSBlockOperation *weakOp = loadImOperation;
    [loadImOperation addExecutionBlock:^{
    //    NSLog(@"Starting a load operation for a path:%@", self.imagePath);
        NSBlockOperation* strongOp = weakOp;
        if(strongOp == nil){
            NSLog(@"########!!!!!!STRONG OPERATION IS NIL...");
            return ;
        }
        
        if(![self amIStillInPreloadArea]){
            NSLog(@"Not in preload anymore! Cancelling myself.. My name=%@", strongOp.name);
            [strongOp cancel];
        }
        
        
        if([self handleCancelIfNeeded:strongOp])return;
        
  //      NSDate *loadStart = [NSDate date];
        CGImageRef thumbN;
        if(!self.isVideo){
            thumbN = [WDCollectionViewImage getThumbnailForImageIO:self.imagePath heigth:wdCollectionThumbnailMaxSize];
            if(!thumbN)NSLog(@"PHOTO IS NIL!!!");
        }else{
            thumbN = [WDCollectionViewImage getThumbnailForVideo:self.imagePath heigth:wdCollectionThumbnailMaxSize];
            if(!thumbN)NSLog(@"VIDEO IS NIL!!!");
        }
        
  //      NSTimeInterval loadTime = [[NSDate date] timeIntervalSinceDate:loadStart];
  //      NSLog(@"file load time: %f. Putting into cache now.fname=%@", loadTime, [self.imagePath lastPathComponent]);
        
        //store EITHER in cache OR locally
        if(_imCache){
            [_imCache setObject:CFBridgingRelease(thumbN) forKey:self.imagePath];
        }else{
            _imageToDisplay = thumbN;
        }
        
        [_callbackTarger imageFinishedLoading];     //tell the item that we're done here
        if(wdCollectionLoadThrottleTimeSleep > 0)[NSThread sleepForTimeInterval:wdCollectionLoadThrottleTimeSleep];
        self.loadOrdered = NO;
    }];
    
    [[WDCollectionViewImage imageLoadOperationQueue]addOperation:loadImOperation];
}

-(BOOL) handleCancelIfNeeded:(NSBlockOperation*) blockOperation{
    return [self handleCancelIfNeeded:blockOperation withComment:@""];
}

-(BOOL) handleCancelIfNeeded:(NSBlockOperation*) blockOperation withComment:(NSString *)str{
    if( blockOperation == nil || [blockOperation isCancelled]){
        self.loadOrdered = NO;
        NSLog(@"Queued image load operation cancelled. Name=%@", blockOperation.name);
    }
    return (blockOperation == nil || [blockOperation isCancelled]);
}

#pragma mark -
#pragma mark Load queue handling

- (BOOL) isAlreadyAnActiveLoadOperationForMe{
    if([self getActiveLoadOperationForMe])return  YES;
    return  NO;
}

- (NSBlockOperation *) getActiveLoadOperationForMe{
    for(NSBlockOperation* operation in [[WDCollectionViewImage imageLoadOperationQueue] operations]){
        if([operation.name isEqualToString:self.imagePath ] && (![operation isCancelled])){
            return  operation;
        }
    }
    return  nil;
}

+ (NSOperationQueue*) imageLoadOperationQueue{
    static NSOperationQueue* wdPhotoLoadSharedQueue;
    static dispatch_once_t onceQToken;
    
    dispatch_once(&onceQToken, ^{
        NSLog(@"Creating the image load queue.");
        wdPhotoLoadSharedQueue = [[NSOperationQueue alloc] init];
        [wdPhotoLoadSharedQueue setMaxConcurrentOperationCount:wdCollectionLoadingThreads];
    });
    
    return  wdPhotoLoadSharedQueue;
}

#pragma mark -
#pragma mark Image load
-(BOOL) amIStillInPreloadArea{
    return [_callbackTarger isImageStillInPreloadArea:self];
}

+(CGImageRef) getThumbnailForVideo: (NSString*) videoPath heigth:(NSInteger) h{
    AVAsset *vid =  [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
    CMTime vidduration =  vid.duration;
    CMTime thumbMoment = CMTimeMultiplyByFloat64(vidduration, 0.5f);
    AVAssetImageGenerator *imGen = [AVAssetImageGenerator assetImageGeneratorWithAsset:vid];
    CGImageRef thum = [imGen copyCGImageAtTime:thumbMoment actualTime:NULL error:NULL];
    return thum;
}

+(CGImageRef) getThumbnailForImageIO: (NSString*)imagePath heigth:(int)h{
    NSURL *url = [NSURL fileURLWithPath:imagePath];
    
    CGImageSourceRef  myImageSource;
    
    CFDictionaryRef   myOptions = NULL;
    CFStringRef       myKeys[2];
    CFTypeRef         myValues[2];
    
    CFDictionaryRef   myOptionsT = NULL;
    CFStringRef       myKeysT[5];
    CFTypeRef         myValuesT[5];
    CFNumberRef       thumbnailSize;
    
    
    myKeys[0] = kCGImageSourceShouldCache;
    myValues[0] = (CFTypeRef)kCFBooleanTrue;
    myKeys[1] = kCGImageSourceShouldAllowFloat;
    myValues[1] = (CFTypeRef)kCFBooleanTrue;
    
    myOptions = CFDictionaryCreate(NULL, (const void **) myKeys,
                                   (const void **) myValues, 2,
                                   &kCFTypeDictionaryKeyCallBacks,
                                   & kCFTypeDictionaryValueCallBacks);
    // Create an image source from the URL.
    myImageSource = CGImageSourceCreateWithURL((CFURLRef)url, myOptions);
    
    if (myImageSource == NULL){
        fprintf(stderr, "Image source is NULL.");
        return  NULL;
    }
    
    thumbnailSize = CFNumberCreate(NULL, kCFNumberIntType, &h);
    // Set up the thumbnail options.
    myKeysT[0] = kCGImageSourceCreateThumbnailWithTransform;
    myValuesT[0] = (CFTypeRef)kCFBooleanFalse;
    myKeysT[1] = kCGImageSourceCreateThumbnailFromImageIfAbsent;
    myValuesT[1] = (CFTypeRef)kCFBooleanTrue;
    myKeysT[2] = kCGImageSourceThumbnailMaxPixelSize;
    myValuesT[2] = (CFTypeRef)thumbnailSize;
    myKeysT[3] = kCGImageSourceCreateThumbnailFromImageAlways;
    myValuesT[3] = (CFTypeRef)kCFBooleanTrue;
    myKeysT[4] = kCGImageSourceShouldCache;
    myValuesT[4] = (CFTypeRef)kCFBooleanTrue;
    
    myOptionsT = CFDictionaryCreate(NULL, (const void **) myKeysT,
                                    (const void **) myValuesT, 5,
                                    &kCFTypeDictionaryKeyCallBacks,
                                    & kCFTypeDictionaryValueCallBacks);
    
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(myImageSource, 0, myOptionsT);
    return thumbnail;
}

@end
