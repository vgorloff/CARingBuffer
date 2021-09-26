//
//  DefaultAssert.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

struct DefaultAssert: AssertType {

   func equals<T>(_ lhs: T, _ rhs: T, file: StaticString, line: UInt) where T: Equatable {}

   func fail(_ message: String, file: StaticString, line: UInt) {}

   func shouldNeverHappen(_ error: Error, file: StaticString, line: UInt) {}

   func notNil<T>(_ value: T?, _ message: Any?, file: StaticString, line: UInt) {}

   func notEmpty(_ value: String?, file: StaticString, line: UInt) {}

   func notEmpty<T>(_ value: [T], _ message: Any?, file: StaticString, line: UInt) {}
}
