//
//  Assert.swift
//  MCA-OSS-CARB
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation
import mcxTestability

#if canImport(XCTest)
import XCTest

public struct Assert: AssertType {

   public func fail(_ message: String, file: StaticString, line: UInt) {
      type(of: self).fail(message, file: file, line: line)
   }

   public func shouldNeverHappen(_ error: Error, file: StaticString, line: UInt) {
      type(of: self).shouldNeverHappen(error, file: file, line: line)
   }

   public func notNil<T>(_ value: T?, _ message: Any?, file: StaticString, line: UInt) {
      type(of: self).notNil(value, message, file: file, line: line)
   }

   public func notEmpty(_ value: String?, file: StaticString, line: UInt) {
      type(of: self).notEmpty(value, file: file, line: line)
   }

   public func notEmpty<T>(_ value: [T], _ message: Any?, file: StaticString, line: UInt) {
      type(of: self).notEmpty(value, file: file, line: line)
   }

   public func equals<T>(_ lhs: T, _ rhs: T, file: StaticString, line: UInt) where T: Equatable {
      type(of: self).equals(lhs, rhs, file: file, line: line)
   }

   public static func perform(file: StaticString = #file, line: UInt = #line, closure: () throws -> Void) {
      do {
         try closure()
      } catch {
         XCTAssert(false, String(describing: error), file: file, line: line)
      }
   }

   public static func verify(_ expression: @autoclosure () throws -> Bool, _ message: String? = nil,
                             file: StaticString = #file, line: UInt = #line)
   {
      if let message = message {
         XCTAssertTrue(try expression(), message, file: file, line: line)
      } else {
         XCTAssertTrue(try expression(), file: file, line: line)
      }
   }

   public static func notEmpty<T1, T2>(_ value: [T1: T2], _ message: Any? = nil, file: StaticString = #file, line: UInt = #line) {
      var msg = "Expected non-empty dictionary. Got empty"
      if let value = message {
         msg += ". → \"" + String(describing: value) + "\""
      }
      msg += "."
      XCTAssert(!value.isEmpty, msg, file: file, line: line)
   }

   public static func notEmpty<T>(_ value: [T], _ message: Any? = nil, file: StaticString = #file, line: UInt = #line) {
      var msg = "Expected non-empty array. Got empty"
      if let value = message {
         msg += ". → \"" + String(describing: value) + "\""
      }
      msg += "."
      XCTAssert(!value.isEmpty, msg, file: file, line: line)
   }

   public static func notEmpty(_ value: String?, file: StaticString = #file, line: UInt = #line) {
      if let value = value {
         XCTAssert(!value.isEmpty, "Expected non-empty string. Got empty.", file: file, line: line)
      }
      Assert.notNil(value, file: file, line: line)
   }

   public static func isEmpty<T>(_ value: [T], file: StaticString = #file, line: UInt = #line) {
      XCTAssert(value.isEmpty, "Expected empty array. Got \(value.count) values.", file: file, line: line)
   }

   public static func isEmpty<T1, T2>(_ value: [T1: T2], file: StaticString = #file, line: UInt = #line) {
      XCTAssert(value.isEmpty, "Expected empty dictionary. Got \(value.count) values.", file: file, line: line)
   }

   public static func notNil<T>(_ value: T?, _ message: Any? = nil, file: StaticString = #file, line: UInt = #line) {
      var msg = "Expected value, but got nil"
      if let value = message {
         msg += ". → \"" + String(describing: value) + "\""
      }
      msg += "."
      XCTAssertNotNil(value, msg, file: file, line: line)
   }

   public static func `true`(_ value: Bool, file: StaticString = #file, line: UInt = #line) {
      XCTAssertTrue(value, "Expected true. Got \(value).", file: file, line: line)
   }

   public static func `true`(_ value: Bool?, file: StaticString = #file, line: UInt = #line) {
      if let value = value {
         XCTAssertTrue(value, "Expected true. Got \(value).", file: file, line: line)
      } else {
         XCTAssertNotNil(value, "Expected value but got `nil`.", file: file, line: line)
      }
   }

   public static func `false`(_ value: Bool, file: StaticString = #file, line: UInt = #line) {
      XCTAssertFalse(value, "Expected false. Got \(value).", file: file, line: line)
   }

   public static func `false`(_ value: Bool?, file: StaticString = #file, line: UInt = #line) {
      if let value = value {
         XCTAssertFalse(value, "Expected false. Got \(value).", file: file, line: line)
      } else {
         XCTAssertNotNil(value, "Expected value but got `nil`.", file: file, line: line)
      }
   }

   public static func notNil<T>(_ value: T?, file: StaticString = #file, line: UInt = #line) {
      XCTAssertNotNil(value, "Expected value but got `nil`.", file: file, line: line)
   }

   public static func fail(_ message: String, file: StaticString = #file, line: UInt = #line) {
      XCTFail(message, file: file, line: line)
   }

   public static func failNil(file: StaticString = #file, line: UInt = #line) {
      XCTFail("Expected value, but got `nil`.", file: file, line: line)
   }

   public static func notZero(_ value: Int?, file: StaticString = #file, line: UInt = #line) {
      if let value = value {
         XCTAssert(value != 0, "Expected non-zero integer. Got zero.", file: file, line: line)
      }
      Assert.notNil(value, file: file, line: line)
   }

   public static func isNil<T>(_ value: T?, file: StaticString = #file, line: UInt = #line) {
      if let value = value {
         XCTFail("Expected `nil` but got: \(value).", file: file, line: line)
      }
   }

   public static func equals<T: Equatable>(_ lhs: T, _ rhs: T, file: StaticString = #file, line: UInt = #line) {
      XCTAssertEqual(lhs, rhs, file: file, line: line)
   }

   public static func notEqual<T: Equatable>(_ lhs: T, _ rhs: T, file: StaticString = #file, line: UInt = #line) {
      XCTAssertNotEqual(lhs, rhs, file: file, line: line)
   }

   public static func equals<T: Equatable>(_ lhs: [T], _ rhs: [T], file: StaticString = #file, line: UInt = #line) {
      XCTAssertEqual(lhs, rhs, file: file, line: line)
   }

   public static func equals<T: FloatingPoint>(_ lhs: T, _ rhs: T, accuracy: T,
                                               file: StaticString = #file, line: UInt = #line)
   {
      XCTAssertEqual(lhs, rhs, accuracy: accuracy, file: file, line: line)
   }

   public static func equals<T: Equatable>(_ lhs: T?, _ rhs: T, file: StaticString = #file, line: UInt = #line) {
      XCTAssertEqual(lhs, rhs, file: file, line: line)
   }

   public static func equals<T: FloatingPoint>(_ lhs: T?, _ rhs: T, accuracy: T,
                                               file: StaticString = #file, line: UInt = #line)
   {
      if let value = lhs {
         XCTAssertEqual(value, rhs, accuracy: accuracy, file: file, line: line)
      } else {
         XCTAssertNotNil(lhs, "Expected value but got `nil`.", file: file, line: line)
      }
   }

   public static func `throws`<T>(_ expression: @autoclosure () throws -> T, file: StaticString = #file, line: UInt = #line) {
      XCTAssertThrowsError(try expression(), file: file, line: line)
   }

   @discardableResult
   public static func noThrow<T>(_ expression: @autoclosure () throws -> T, file: StaticString = #file, line: UInt = #line) -> T? {
      do {
         return try expression()
      } catch {
         XCTFail(String(describing: error), file: file, line: line)
         return nil
      }
   }

   public static func unexpectedType(_ unexpected: Any, expected: Any.Type,
                                     file: StaticString = #file, line: UInt = #line)
   {
      let valueType = type(of: unexpected)
      XCTAssert(valueType == expected, "Unexpected type: \(valueType), expected: \(expected)", file: file, line: line)
   }

   public static func unexpectedType(_ unexpected: Any?, expected: Any.Type,
                                     file: StaticString = #file, line: UInt = #line)
   {
      let valueType = type(of: unexpected)
      XCTAssert(valueType == expected, "Unexpected type: \(valueType), expected: \(expected)", file: file, line: line)
   }

   public static func unexpectedError(_ error: Swift.Error, file: StaticString = #file, line: UInt = #line) {
      XCTFail("Should never happen. Instead got error: \(error).", file: file, line: line)
   }

   public static func shouldNeverHappen(_ error: Swift.Error, file: StaticString = #file, line: UInt = #line) {
      XCTFail("Should never happen. Instead got failure: \(error).", file: file, line: line)
   }

   public static func shouldNeverHappen(file: StaticString = #file, line: UInt = #line) {
      XCTFail("Should never happen.", file: file, line: line)
   }
}
#endif
