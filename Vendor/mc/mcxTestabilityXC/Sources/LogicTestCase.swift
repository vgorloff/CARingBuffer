//
//  LogicTestCase.swift
//  MCA-OSS-CARB
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation
import mcxTestability
#if canImport(XCTest)
import XCTest

open class LogicTestCase: XCTestCase {

   public private(set) var test: AbstractLogicTestCase<XCTestExpectation, XCTestCase>!

   override open func setUp() {
      test = AbstractLogicTestCase(testCase: self)
      super.setUp()
      test.setUp()
   }

   override open func tearDown() {
      test.tearDown()
      super.tearDown()
   }

   open var resource: TestResource {
      return test.resource
   }
}
#endif
