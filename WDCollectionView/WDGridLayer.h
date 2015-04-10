//
// Created by Fred on 08/04/15.
// Copyright (c) 2015 wd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "WDGridViewLayoutManager.h"

@class NSEvent;

@interface WDGridLayer : CALayer<WDGridViewLayoutManagerProtocol>

#pragma mark -
#pragma mark Mouse Handling Operations
- (void)mouseDownAtPointInLayer:(NSPoint)point withEvent:(NSEvent *)theEvent;
- (void)mouseUpAtPointInLayer:(NSPoint)point withEvent:(NSEvent *)theEvent;
- (void)mouseDraggedAtPointInLayer:(NSPoint)point withEvent:(NSEvent *)theEvent;
- (void)mouseMovedAtPointInLayer:(NSPoint)point withEvent:(NSEvent *)theEvent;
- (void)mouseEnteredAtPointInLayer:(NSPoint)point withEvent:(NSEvent *)theEvent;
- (void)mouseExitedAtPointInLayer:(NSPoint)point withEvent:(NSEvent *)theEvent;

#pragma mark -
#pragma mark Layer Operations
- (void)willMoveToSuperlayer:(WDGridLayer *)superlayer;
- (void)didMoveToSuperlayer;

#pragma mark -
#pragma mark Properties
@property(nonatomic, getter=isTracking)    BOOL tracking;
@property(nonatomic, getter=isInteractive) BOOL interactive;
@property(nonatomic, assign) BOOL receivesHoverEvents;
@property(nonatomic, readonly) NSWindow *window;
@property(nonatomic, readonly) NSView   *view;

@end