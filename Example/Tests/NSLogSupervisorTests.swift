//
//  NSLogSupervisorTests.swift
//  Supervisor_Tests
//
//  Created by 梁宪松 on 2020/3/26.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import XCTest
import Supervisor

class NSLogSupervisorTests: XCTestCase, NSLogSupervisorDelegate {

    func testLogger() {
        // This is an example of a functional test case.
        
        NSLogSupervisor.shared.start()
        NSLogSupervisor.add(delegate: self)
        
        print("print test")
        print("print 测试")
        NSLog("NSLog Test")
        NSLog("NSLog 测试")
        NSLog("NSLog %d %d %d %d", 6, 5, 4, 3)
        NSLog("NSLog %@", "测试")
        FPrint.fprint()
    }
    
    func nslogSupervisorDid(with str: String) {
        
        
    }
}

