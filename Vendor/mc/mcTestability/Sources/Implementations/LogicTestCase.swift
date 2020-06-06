//
//  LogicTestCase.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation
#if canImport(XCTest)
import XCTest

open class LogicTestCase: XCTestCase {

   public private(set) var test: AbstractLogicTestCase<XCTestExpectation, XCTestCase>!

   override open func setUp() {
      let env = DefaultTestEnvironment(isUnderPlaygroundTesting: TestabilityRuntime.isPlaygroundTesting,
                                       isReferenceTest: TestabilityRuntime.isReferenceTest)
      TestSettings.shared.testEnvironment = env
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
