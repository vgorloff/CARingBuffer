//
//  UIAutomationTestCase.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 14.07.17.
//  Copyright © 2017 Vlad Gorlov. All rights reserved.
//

import Foundation
#if canImport(XCTest)
import XCTest

class UIAutomationTestCase: XCTestCase {

   /*
    var app: XCUIApplication!

    override func setUp() {
       super.setUp()

       continueAfterFailure = false

       // Reset app between tests: https://m.pardel.net/resetting-ios-simulator-for-ui-tests-cd7fff57788e
       var launchEnvironment = [Constants.Environment.uiTestingMode: "YES"]
       app = XCUIApplication()
       app.launchEnvironment = launchEnvironment
       app.launch()

       XCUIDevice.shared.orientation = .faceUp
    }
    */
}

extension UIAutomationTestCase {

   func deleteString(from string: String) -> String {
      return Array(repeating: XCUIKeyboardKey.delete.rawValue, count: string.count).joined(separator: "")
   }
}

extension UIAutomationTestCase {

   func waitForExists(_ element: XCUIElement, timeout: TimeInterval = 30, file: String = #file, line: Int = #line) {
      let existsPredicate = NSPredicate(format: "exists == true")
      expectation(for: existsPredicate, evaluatedWith: element, handler: nil)
      waitForExpectations(timeout: timeout) { [weak self] error in
         guard error != nil else {
            return
         }
         let message = "Failed to find \(element) after \(timeout) seconds."
         self?.recordFailure(withDescription: message, inFile: file, atLine: line, expected: true)
      }
   }

   func waitForNotExists(_ element: XCUIElement, timeout: TimeInterval = 30, file: String = #file, line: Int = #line) {
      let existsPredicate = NSPredicate(format: "exists == false")
      expectation(for: existsPredicate, evaluatedWith: element, handler: nil)
      waitForExpectations(timeout: timeout) { [weak self] error in
         guard error != nil else {
            return
         }
         let message = "Element \(element) still exists after \(timeout) seconds."
         self?.recordFailure(withDescription: message, inFile: file, atLine: line, expected: true)
      }
   }
}
#endif
