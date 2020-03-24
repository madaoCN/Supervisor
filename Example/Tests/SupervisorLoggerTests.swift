//
//  SupervisorLoggerTests.swift
//  Supervisor_Tests
//
//  Created by 梁宪松 on 2020/3/24.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import XCTest
import Supervisor

class SupervisorLoggerTests: XCTestCase {

    func testLogger() {
        // This is an example of a functional test case.
        
        SupervisorLogger.debug(message: "this is a debug info")
        SupervisorLogger.info(message: "this is an info info")
        SupervisorLogger.warn(message: "this is a warn info")
        SupervisorLogger.error(message: "this is an error info")
    }
}
