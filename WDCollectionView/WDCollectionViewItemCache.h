//
//  WDCollectionViewItemCache.h
//  FlickFlock
//
//  Created by Fred on 04/04/15.
//  Copyright (c) 2015 fred. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WDCollectionViewItem.h"

@interface WDCollectionViewItemCache : NSObject

-(void) clearItemCache;
-(void) clearIndexMapping;
-(WDCollectionViewItem*) getCachedItemByIndex:(NSInteger) itemIndex;
-(WDCollectionViewItem*) getCachedItemByKey:(NSString*) itemKey;
-(void) cacheItemIfNeeded:(WDCollectionViewItem*) item forIndex: (NSInteger) index;


@end
