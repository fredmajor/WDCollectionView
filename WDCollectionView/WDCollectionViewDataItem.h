//
//  WDCollectionViewDataItem.h
//  FlickFlock
//
//  Created by Fred on 29/03/15.
//  Copyright (c) 2015 fred. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WDCollectionViewDataItem : NSObject

@property (strong, nonatomic) NSString *imagePath;
@property (strong, nonatomic) NSObject *representedObject;
@property (nonatomic) BOOL isVideo;


@end
