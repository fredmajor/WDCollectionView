//
//  WDCollectionViewLayoutHelpersTests.m
//  WDCollectionView
//
//  Created by Fred on 07/04/15.
//  Copyright (c) 2015 wd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "WDCollectionLayoutHelpers.h"

@interface WDCollectionViewLayoutHelpersTests : XCTestCase

@end

@implementation WDCollectionViewLayoutHelpersTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRowsVisibleInPartOfView {
    CGRect partOfView = CGRectMake(0, -30, 500, 600);
    CGFloat itemH = 60.3f;
    CGFloat vertSpacing = 20.2f;

    NSRange res =  WDRowsVisibleInPartOfView(partOfView,itemH, vertSpacing);
    XCTAssertEqual(res.location, 0);
    XCTAssertEqual(res.length, 6);
}

//WDCellRangeWithOverflowCheck
- (void)testCellRangeWithOverflowCheck {
    NSRange rowRange = NSMakeRange(0, 3);

    NSRange cellRange = WDCellRangeWithOverflowCheck(rowRange, 3, 6);
    XCTAssertEqual(cellRange.location, 0);
    XCTAssertEqual(cellRange.length, 6);


    cellRange = WDCellRangeWithOverflowCheck(rowRange, 3, 9);
    XCTAssertEqual(cellRange.location, 0);
    XCTAssertEqual(cellRange.length, 9);

    cellRange = WDCellRangeWithOverflowCheck(rowRange, 3, 12);
    XCTAssertEqual(cellRange.location, 0);
    XCTAssertEqual(cellRange.length, 9);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        [self testCellRangeWithOverflowCheck];
    }];
}

@end
