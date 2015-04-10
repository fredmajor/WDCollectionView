#import "WDGridViewCell.h"
#import "WDCollectionViewMainView.h"

@interface  WDGridViewCell (WDCollectionViewMainView)
@property(nonatomic, assign, setter = WD_setIndex:) NSUInteger WD_index;
@end