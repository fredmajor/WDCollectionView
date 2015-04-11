//
//  WDTextLayer.m
//  WDCollectionView
//
//  Created by Fred on 11/04/15.
//  Copyright (c) 2015 wd. All rights reserved.
//

#import "WDTextLayer.h"
#define kTextShadowBlurRadius 1.f
#define kTextShadowOpacity 0.75f
#define kTextShadowColor CGColorGetConstantColor(kCGColorBlack)
#define kTextShadowOffset CGSizeMake(0.f, -1.f)
#define kLayoutTextYInset 4.f
#define kLayoutTextXInset 6.f

@implementation WDTextLayer{
    CATextLayer *_filenameTextLayer;
}

- (id)init {
    if ((self = [super init])) {
        self.backgroundColor = CGColorGetConstantColor(kCGColorClear);
        self.opaque = NO;
        self.needsDisplayOnBoundsChange = YES;
        self.masksToBounds = YES;

        _filenameTextLayer = [CATextLayer layer];
        _filenameTextLayer.font = (__bridge CFTypeRef)[NSFont boldSystemFontOfSize:12.f];
        _filenameTextLayer.fontSize = 12.f;
        _filenameTextLayer.shadowColor = CGColorGetConstantColor(kCGColorBlack);
        _filenameTextLayer.shadowRadius = kTextShadowBlurRadius;
        _filenameTextLayer.shadowOpacity = kTextShadowOpacity;
        _filenameTextLayer.shadowOffset = kTextShadowOffset;
        _filenameTextLayer.truncationMode = kCATruncationEnd;
       // _filenameTextLayer.contentsScale = SONORA_SCALE_FACTOR;
        _filenameTextLayer.delegate = self;
        [self addSublayer:_filenameTextLayer];
    }
    return self;
}

- (void)layoutSublayers {
    [super layoutSublayers];
    [_filenameTextLayer setFrame:self.bounds];
}

@end
