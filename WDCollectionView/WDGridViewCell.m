//
// Created by Fred on 08/04/15.
// Copyright (c) 2015 wd. All rights reserved.
//

#import "WDGridViewCell.h"
#import "WDCollectionViewMainView.h"

@interface WDGridViewCell ()
- (void)WD_reorderLayers;
@end

@implementation WDGridViewCell
@synthesize highlighted = _highlighted;
@synthesize selected=_selected;
@synthesize editing=_editing;
@synthesize foregroundLayer=_foregroundLayer;

- (id)init
{
    if((self = [super init]))
    {
        [self setNeedsDisplayOnBoundsChange:YES];
        [self setLayoutManager:[WDGridViewLayoutManager layoutManager]];
        [self setInteractive:YES];
    }

    return self;
}

- (void)addSublayer:(CALayer *)layer
{
    [super addSublayer:layer];
    [self WD_reorderLayers];
}

- (void)insertSublayer:(CALayer *)layer atIndex:(unsigned int)idx
{
    [super insertSublayer:layer atIndex:idx];
    [self WD_reorderLayers];
}

- (void)layoutSublayers
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [_foregroundLayer setFrame:[self bounds]];
    [CATransaction commit];
}

- (void)prepareForReuse
{
    [self setTracking:NO];
    [self setEditing:NO];
    [self setSelected:NO];
    [self setHidden:NO];
    [self setOpacity:1.0];
    [self setShadowOpacity:0.0];
}

//- (void)setRepresentedObject:(id)representedObject
//{
//    if (_representedObject != representedObject) {
//        [self unbind:@"artistName"];
//        [self willChangeValueForKey:@"representedObject"];
//        _representedObject = representedObject;
//        [self didChangeValueForKey:@"representedObject"];
//        _isDisplayingMix = [representedObject isKindOfClass:[SNRMix class]];
//        _genericLayer.albumTextLayer.font = (__bridge CFTypeRef)[NSFont fontWithName:_isDisplayingMix ? kFontMixes : kFontAlbums size:16.f];
//        
//        if (_representedObject) {
//            [self bind:@"albumName" toObject:self withKeyPath:@"representedObject.name" options:nil];
//            [self addObserver:self forKeyPath:@"representedObject.songs" options:0 context:NULL];
//            if ([_representedObject isKindOfClass:[SNRAlbum class]]) {
//                [self bind:@"artistName" toObject:self withKeyPath:@"representedObject.artist.name" options:nil];
//            }
//        } else {
//            [self unbind:@"albumName"];
//            [self removeObserver:self forKeyPath:@"representedObject.songs"];
//        }
//        [self _resetValueForKey:@"duration"];
//    }
//}

- (void)didBecomeFocused
{
}

- (void)willResignFocus
{
}
- (void)didBecomeDisplayedOnView{
}
- (void)didBecomeRemovedFromView{
}

#pragma mark -
#pragma mark Properties

- (id)draggingImage
{
    const CGSize       imageSize     = [self bounds].size;
    NSBitmapImageRep  *dragImageRep  = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:imageSize.width pixelsHigh:imageSize.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:(NSInteger)ceil(imageSize.width) * 4 bitsPerPixel:32];
    NSGraphicsContext *bitmapContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:dragImageRep];
    CGContextRef       ctx           = (CGContextRef)[bitmapContext graphicsPort];

    if([self superlayer] == nil) CGContextConcatCTM(ctx, CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, imageSize.height));

    CGContextClearRect(ctx, CGRectMake(0.0, 0.0, imageSize.width, imageSize.height));
    CGContextSetAllowsAntialiasing(ctx, YES);
    [self renderInContext:ctx];
    CGContextFlush(ctx);

    NSImage *dragImage = [[NSImage alloc] initWithSize:imageSize];
    [dragImage addRepresentation:dragImageRep];
    //[dragImage setFlipped:YES];

    return dragImage;
}

- (void)setSelected:(BOOL)selected
{
    [self setSelected:selected animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    _selected = selected;
}

- (void)setEditing:(BOOL)editing
{
    if(_editing != editing)
    {
        //TODO - edition not ported yet
     //   if(editing)  [[self gridView] WD_willBeginEditingCell:self];
     //   else         [[self gridView] WD_didEndEditingCell:self];
        _editing = editing;
    }
}

- (void)WD_reorderLayers
{
    [super insertSublayer:_foregroundLayer atIndex:(unsigned int)[[self sublayers] count]];
}

- (void)setForegroundLayer:(CALayer *)foregroundLayer
{
    if(_foregroundLayer != foregroundLayer)
    {
        [_foregroundLayer removeFromSuperlayer];
        _foregroundLayer = foregroundLayer;

        [self WD_reorderLayers];
    }
}

- (WDCollectionViewMainView *)gridView
{
    WDCollectionViewMainView *superlayerDelegate = [[self superlayer] delegate];
    return [superlayerDelegate isKindOfClass:[WDCollectionViewMainView class]] ? superlayerDelegate : nil;
}

- (NSRect)hitRect
{
    return [self bounds];
}

- (void)WD_setIndex:(NSUInteger)index
{
    _index = index;
}

- (NSUInteger)WD_index
{
    return _index;
}
@end