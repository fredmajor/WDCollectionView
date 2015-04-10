//
// Created by Fred on 08/04/15.
// Copyright (c) 2015 wd. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "WDGridLayer.h"


@implementation WDGridLayer

@synthesize receivesHoverEvents = _receivesHoverEvents;
@synthesize tracking = _tracking, interactive = _interactive;

- (id)init{
    if((self = [super init]))
    {
        [self setLayoutManager:[WDGridViewLayoutManager layoutManager]];
        NSWindow *mainWindow = [NSApp mainWindow];
        NSWindow *layerWindow = [[self view] window];
        if (mainWindow || layerWindow) {
           // [self setContentsScale:[(layerWindow != nil) ? layerWindow : mainWindow backingScaleFactor]];
        }
    }
    return self;
}


#pragma mark -
#pragma mark Mouse Handling Operations

- (void)mouseDownAtPointInLayer:(NSPoint)point withEvent:(NSEvent *)theEvent
{
}

- (void)mouseUpAtPointInLayer:(NSPoint)point withEvent:(NSEvent *)theEvent
{
}

- (void)mouseMovedAtPointInLayer:(NSPoint)point withEvent:(NSEvent *)theEvent
{
}

- (void)mouseEnteredAtPointInLayer:(NSPoint)point withEvent:(NSEvent *)theEvent
{
}

- (void)mouseExitedAtPointInLayer:(NSPoint)point withEvent:(NSEvent *)theEvent
{
}

- (void)mouseDraggedAtPointInLayer:(NSPoint)point withEvent:(NSEvent *)theEvent
{
}

#pragma mark -
#pragma mark Layer Operations
- (void)layoutSublayers {
    if([[self delegate] respondsToSelector:@selector(layoutSublayers)]) [[self delegate] layoutSublayers];
}

- (id<CAAction>)actionForKey:(NSString *)event{
    return nil;
}

- (CALayer *)hitTest:(CGPoint)p{
    if(!_interactive && !_receivesHoverEvents) return nil;

    if(CGRectContainsPoint([self frame], p))
        return [super hitTest:p] ? : self;

    return nil;
}

- (void)willMoveToSuperlayer:(WDGridLayer *)superlayer{
}

- (void)didMoveToSuperlayer{
}

- (void)addSublayer:(CALayer *)layer{
    if([layer isKindOfClass:[WDGridLayer class]]){
        [(WDGridLayer *)layer willMoveToSuperlayer:self];
        [super addSublayer:layer];
        [(WDGridLayer *)layer didMoveToSuperlayer];
    }else{
        [super addSublayer:layer];
    }
}

- (void)insertSublayer:(CALayer *)layer atIndex:(unsigned int)idx{
    if([layer isKindOfClass:[WDGridLayer class]]){
        [(WDGridLayer *)layer willMoveToSuperlayer:self];
        [super insertSublayer:layer atIndex:idx];
        [(WDGridLayer *)layer didMoveToSuperlayer];
    }else{
        [super insertSublayer:layer atIndex:idx];
    }
}

- (void)removeFromSuperlayer{
    [self willMoveToSuperlayer:nil];
    [super removeFromSuperlayer];
    [self didMoveToSuperlayer];
}

#pragma mark -
#pragma mark Properties

- (NSWindow *)window
{
    return [[self view] window];
}

- (NSView *)view
{
    CALayer *superlayer = self;
    while(superlayer)
    {
        NSView *delegate = [superlayer delegate];

        if([delegate isKindOfClass:[NSView class]]) return delegate;

        superlayer = [superlayer superlayer];
    }

    return nil;
}
@end