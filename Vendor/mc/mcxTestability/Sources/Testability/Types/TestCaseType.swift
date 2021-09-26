//
//  TestCaseType.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

public protocol TestCaseType: AnyObject {

   associatedtype Expectation: ExpectationType
   var testName: String { get }
   var allTestsNames: [String] { get }

   func expectation(description: String) -> Expectation
   func expectation(forNotification notificationName: NSNotification.Name, object objectToObserve: Any?,
                    handler: ((Notification) -> Bool)?) -> Expectation
   func wait(for: [Expectation], timeout: TimeInterval, enforceOrder: Bool)

   func defaultExpectation(function: StaticString, file: StaticString, line: UInt) -> Expectation
}
