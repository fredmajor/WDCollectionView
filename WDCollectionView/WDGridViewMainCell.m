//
//  WDGridViewMainCell.m
//  WDCollectionView
//
//  Created by Fred on 10/04/15.
//  Copyright (c) 2015 wd. All rights reserved.
//

#import "WDGridViewMainCell.h"

@implementation WDGridViewMainCell{
    WDCollectionViewImage *_image;
}

@synthesize representedObject;
@synthesize imageUrl;
@synthesize itemCallback;
@synthesize cacheProvider;

- (instancetype)init{
    if((self = [super init])){
    }
    return self;
}

- (void) prepareForReuse{
    [super prepareForReuse];
    self.representedObject = nil;
    self.imageUrl = nil;
    _image = nil;
}

- (void)loadImageIfNeeded{
    NSLog(@"loadImageIfNeeded: imageUrl=%@",self.imageUrl);
    if(!_image && self.imageUrl){
        //TODO - auto recognition of videos!
        _image = [[WDCollectionViewImage alloc] initWithImagePath:self.imageUrl andCache:[self.cacheProvider cacheForLoadedImages] isVideo:NO withCallbackTarger:self];
    }
    [_image loadImage];
}

//called from image
- (BOOL)isImageStillInPreloadArea:(WDCollectionViewImage*)image{
    NSLog(@"Image asked if it's in preload area!!");
    return [self.itemCallback isItemInPreloadArea:self];
}

//called from image
- (void)imageFinishedLoading{
    NSLog(@"image finished loading!");
    if([self.itemCallback respondsToSelector:@selector(itemFinishedLoadingImage:)])[self.itemCallback itemFinishedLoadingImage:self];
}


@end
