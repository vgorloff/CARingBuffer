//
//  TestExpectation.swift
//  MCA-OSS-CARB
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation
#if canImport(XCTest)
import XCTest

class TestExpectation: XCTestExpectation {

   private var fulfillmentCount = 0

   private let file: StaticString
   private let line: UInt
   private let function: StaticString

   init(function: StaticString, file: StaticString, line: UInt) {
      self.file = file
      self.line = line
      self.function = function
      super.init(description: "\(function) @ \(file):\(line)")
   }

   override func fulfill() {
      fulfillmentCount += 1
      if fulfillmentCount > expectedFulfillmentCount {
         XCTFail("Expectation fulfilled \(fulfillmentCount) times while \(expectedFulfillmentCount) is expected.",
                 file: file, line: line)
      }
      super.fulfill()
   }
}
#endif
