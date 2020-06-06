//
//  XCTestCase.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation
#if canImport(XCTest)
import XCTest

extension XCTestCase: TestCaseType {

   public var testName: String {
      if let invocation = invocation {
         return String(describing: invocation.selector)
      }
      assertionFailure()
      return ""
   }

   public var allTestsNames: [String] {
      let result = type(of: self).testInvocations.map { String(describing: $0.selector) }
      return result
   }

   public func defaultExpectation(function: StaticString, file: StaticString, line: UInt) -> XCTestExpectation {
      return TestExpectation(function: function, file: file, line: line)
   }
}
#endif
