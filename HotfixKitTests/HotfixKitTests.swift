//
//  HotfixKitTests.swift
//  HotfixKitTests
//
//  Created by Johan Kool on 12/12/14.
//  Copyright (c) 2014 Koolistov Pte. Ltd. All rights reserved.
//

import UIKit
import XCTest
import HotfixKit


class Foo: NSObject {

    func bar() -> String? {
        return "bar"
    }

}

class HotfixKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testHotfixActivation() {
        let foo = Foo()
//        println("Foo is called \(NSStringFromClass(Foo.self))")
        XCTAssertEqual(foo.bar()!, "bar", "Expected unswizzled return value")

        let dict = NSDictionary(objects: ["test"], forKeys: ["key"])
//        println("NSDictionary is called \(NSStringFromClass(NSDictionary.self))")
        XCTAssertEqual(dict.description, "{\n    key = test;\n}", "Expected unswizzled return value")

        HotfixManager.activateHotfixes([
            [
                Key.AppVersion.rawValue: "1.0",
                Key.OSVersion.rawValue: "8.1",
                Key.Class.rawValue: "HotfixKitTests.Foo",
                Key.MethodType.rawValue: "instance",
                Key.Selector.rawValue: "bar",
                Key.ReplacementSelector.rawValue: "return-object",
                Key.ReplacementReturnValue.rawValue: "hotfix0"
            ],
            [
                Key.AppVersion.rawValue: "1.0",
                Key.OSVersion.rawValue: "8.1",
                Key.Class.rawValue: "NSDictionary",
                Key.MethodType.rawValue: "instance",
                Key.Selector.rawValue: "description",
                Key.ReplacementSelector.rawValue: "return-object",
                Key.ReplacementReturnValue.rawValue: "hotfix1"
            ]
            ])
        XCTAssertEqual(foo.bar()!, "hotfix0", "Expected swizzled return value")
        XCTAssertEqual(dict.description, "hotfix1", "Expected swizzled return value")
    }

}
