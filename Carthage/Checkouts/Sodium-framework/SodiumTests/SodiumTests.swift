//
//  SodiumTests.swift
//  SodiumTests
//
//  Created by Zhuhao Wang on 7/3/16.
//  Copyright © 2016 Zhuhao Wang. All rights reserved.
//

import XCTest
import Sodium

class SodiumTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInitalization() {
        assert(sodium_init() == 0, "Failed to initailize libsodium")
    }
}
