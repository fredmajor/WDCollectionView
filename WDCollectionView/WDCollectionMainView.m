//
//  WDCollectionMainView.m
//  FlickFlock
//
//  Created by Fred on 02/04/15.
//  Copyright (c) 2015 fred. All rights reserved.
//

#import "WDCollectionMainView.h"
#import "WDLocalPhotoCollectionView.h"

#define LOG_LEVEL_DEF ddLogLevel
#import <CocoaLumberjack/CocoaLumberjack.h>
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

#pragma mark -
#pragma mark A private part
@interface WDCollectionMainView()
-(void) commonInit;
@end

@implementation WDCollectionMainView{
    WDLocalPhotoCollectionView *_collectionView;
}
@dynamic collectionView;

- (instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
        NSLog(@"WDCollectionMainView - initWithCoder done");
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
    _collectionView = [[WDLocalPhotoCollectionView alloc]initWithFrame:self.bounds
                                                         andScrollView:self];
    [self setDocumentView:_collectionView];
}

-(WDLocalPhotoCollectionView*) collectionView{
    return _collectionView;
}



- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Drawing code here.
}

@end
