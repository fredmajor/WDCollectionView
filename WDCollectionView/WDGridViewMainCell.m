//
//  WDGridViewMainCell.m
//  WDCollectionView
//
//  Created by Fred on 10/04/15.
//  Copyright (c) 2015 wd. All rights reserved.
//

#import "WDGridViewMainCell.h"
#import "WDTextLayer.h"

#define kImageLayerShadowColor CGColorGetConstantColor(kCGColorBlack)
#define kImageLayerShadowOpacity 0.8f
#define kImageLayerShadowBlurRadius 2.f
#define kImageLayerShadowOffset CGSizeMake(0.f, 3.f)

@interface WDGridViewMainCell()
@property(nonatomic) CGImageRef image;
- (void) orderImageLoad;
@end

@implementation WDGridViewMainCell{
    WDCollectionViewImage   *_internalImage;
    WDGridLayer             *_imageLayer;
    WDTextLayer             *_filenameLayer;
    BOOL _isInUseNow;
    BOOL _imageLoadOrdered;
}

@synthesize imageUrl = _imageUrl;
@dynamic image;
@synthesize representedObject = _representedObject;
@synthesize itemCallback;
@synthesize cacheProvider;
@dynamic filenameToDisplay;

- (instancetype)init{
    if((self = [super init])){
        _isInUseNow = NO;
        _imageLoadOrdered = NO;
        _imageLayer = [WDGridLayer layer];
        _imageLayer.contentsGravity = kCAGravityResizeAspect;
        _filenameLayer = [WDTextLayer layer];
        
        [self addSublayer:_imageLayer];
        [self addSublayer:_filenameLayer];
    }
    return self;
}

- (void)mouseUpAtPointInLayer:(NSPoint)point withEvent:(NSEvent *)theEvent{
    NSLog(@"mouse up!");
}

- (void) prepareForReuse{
    [super prepareForReuse];
    self.representedObject = nil;
    [self setImageUrl:nil];
    [self setFilenameToDisplay:nil];
}

/*called from an image when it starts to load*/
- (BOOL)isImageStillInPreloadArea:(WDCollectionViewImage*)image{
    return [self.itemCallback isItemInPreloadArea:self];
}

/*called from an image when it's loaded. This should display the image */
- (void)imageFinishedLoading{
    dispatch_async(dispatch_get_main_queue(), ^{
        if([self.itemCallback respondsToSelector:@selector(itemFinishedLoadingImage:)])[self.itemCallback itemFinishedLoadingImage:self];
        [self setImage:[_internalImage imageToDisplay]];
        [self setNeedsDisplay];
    });
}

- (void)layoutSublayers{
    [super layoutSublayers];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    CGRect me = self.bounds;
    CGFloat textY = floorf( 4.f/5.f * me.size.height);
    CGRect imageRect = CGRectMake(0, 0, floorf(me.size.width), textY-4);
    [_imageLayer setFrame:imageRect];
//    CGPathRef shadowPath = CGPathCreateWithRect([_imageLayer bounds], NULL);
//    if (_imageLayer.shadowOpacity) {
//        [_imageLayer setShadowPath:shadowPath];
//    }
//    CGPathRelease(shadowPath);

    CGRect textFrame = CGRectMake(0, textY, floorf(me.size.width), floorf(me.size.height-textY));
    [_filenameLayer setFrame:textFrame];
    [CATransaction commit];
}

- (void)setImageUrl:(NSURL *)imageUrl {
    if([imageUrl isKindOfClass:[NSString class]]){
        _imageUrl = [NSURL URLWithString:(NSString*)imageUrl];
    }else{
        _imageUrl = imageUrl;
    }
    
    if(imageUrl){
        _internalImage = [[WDCollectionViewImage alloc] initWithImageUrl:_imageUrl andCache:[self.cacheProvider cacheForLoadedImages] withCallbackTarger:self];
        [self orderImageLoad];
        self.filenameToDisplay = [_imageUrl lastPathComponent];
    }else{
        _internalImage = nil;
        [self setImage:nil];
    }
}

- (void) didBecomeDisplayedOnView{
    _isInUseNow = YES;
    if(_imageUrl && _internalImage && _imageLoadOrdered){
        [_internalImage loadImage];
        _imageLoadOrdered = NO;
    }
}

- (void) didBecomeRemovedFromView{
    _isInUseNow = NO;
}

- (void) orderImageLoad{
    if(_isInUseNow){
        [_internalImage loadImage];
    }else{
        _imageLoadOrdered = YES;
    }
}

- (NSURL*)imageUrl {
    return _imageUrl;
}

- (void)setImage:(CGImageRef)image {
    if (image) {
        _imageLayer.hidden=NO;
        _imageLayer.contents = (__bridge id) image;
        _imageLayer.shadowColor =   kImageLayerShadowColor;
        _imageLayer.shadowOpacity = kImageLayerShadowOpacity;
        _imageLayer.shadowRadius =  kImageLayerShadowBlurRadius;
        _imageLayer.shadowOffset =  kImageLayerShadowOffset;
        _imageLayer.opaque = YES;
    } else {
        _imageLayer.hidden=YES;
        [_imageLayer setContents:nil];
        _imageLayer.shadowColor = nil;
        _imageLayer.shadowOpacity = 0.f;
        _imageLayer.shadowRadius = 0.f;
        _imageLayer.shadowOffset = CGSizeZero;
        _imageLayer.opaque = NO;
    }
}

- (CGImageRef)image{    //dunno if this works..
    return (__bridge CGImageRef)_imageLayer.contents;
}

-(NSString*)filenameToDisplay {
    return _filenameLayer.filenameTextLayer.string;
}

-(void)setFilenameToDisplay:(NSString *)filenameToDisplay {
    if(filenameToDisplay){
        _filenameLayer.filenameTextLayer.string=filenameToDisplay;
        _filenameLayer.hidden=NO;
    }else{
        _filenameLayer.filenameTextLayer.string=@"";
        _filenameLayer.hidden=YES;
    }
}

- (void)setRepresentedObject:(id)representedObject
{
    if (_representedObject != representedObject) {
        [self unbind:@"imageUrl"];
        [self willChangeValueForKey:@"representedObject"];
        _representedObject = representedObject;
        [self didChangeValueForKey:@"representedObject"];
      //  _isDisplayingMix = [representedObject isKindOfClass:[SNRMix class]];
      //  _genericLayer.albumTextLayer.font = (__bridge CFTypeRef)[NSFont fontWithName:_isDisplayingMix ? kFontMixes : kFontAlbums size:16.f];
        
        if (_representedObject) {
            [self bind:@"imageUrl" toObject:self withKeyPath:@"representedObject.imagePath" options:nil];
            self.backgroundColor = [NSColor blueColor].CGColor;
           // self.filenameToDisplay = [cell.imageUrl lastPathComponent];
          //  self bind
           // [self addObserver:self forKeyPath:@"representedObject.songs" options:0 context:NULL];
          //  if ([_representedObject isKindOfClass:[SNRAlbum class]]) {
          //      [self bind:@"artistName" toObject:self withKeyPath:@"representedObject.artist.name" options:nil];
          //  }
        } else {
        //    [self unbind:@"albumName"];
         //   [self removeObserver:self forKeyPath:@"representedObject.songs"];
        }
    }
}

- (void)dealloc{
    [self unbind:@"imageUrl"];
}

@end
