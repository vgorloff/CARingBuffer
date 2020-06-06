//
//  AbstractUILogicTestCase.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation
import QuartzCore

open class AbstractBaseUILogicTestCase<Expectation, TestCase: TestCaseType>: AbstractLogicTestCase<Expectation, TestCase> where TestCase.Expectation == Expectation {

   lazy var playExpectation = testCase.defaultExpectation(function: #function, file: #file, line: #line)
   var testActions: [(String, () -> Void)] = []

   open var testEnvironment: TestEnvironment {
      return TestSettings.shared.testEnvironment
   }

   func waitForAnimationTransactionCompleted(workItem: () -> Void) {
      let exp = testCase.expectation(description: #function)
      CATransaction.begin()
      CATransaction.setCompletionBlock {
         exp.fulfill()
      }
      workItem()
      CATransaction.commit()
      testCase.wait(for: [exp], timeout: defaultExpectationTimeout, enforceOrder: false)
   }
}
