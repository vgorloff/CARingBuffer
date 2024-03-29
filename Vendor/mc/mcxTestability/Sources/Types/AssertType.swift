//
//  AssertType.swift
//  MCA-OSS-CARB
//
//  Created by Vlad Gorlov on 25.06.19.
//  Copyright © 2018 Vlad Gorlov. All rights reserved.
//

import Foundation

public protocol AssertType {
   func fail(_ message: String, file: StaticString, line: UInt)
   func shouldNeverHappen(_ error: Swift.Error, file: StaticString, line: UInt)
   func notNil<T>(_ value: T?, _ message: Any?, file: StaticString, line: UInt)
   func notEmpty(_ value: String?, file: StaticString, line: UInt)
   func notEmpty<T>(_ value: [T], _ message: Any?, file: StaticString, line: UInt)
   func equals<T: Equatable>(_ lhs: T, _ rhs: T, file: StaticString, line: UInt)
}
