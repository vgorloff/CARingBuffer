//
//  AbstractLogicTestCase.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

open class AbstractLogicTestCase<Expectation, TestCase: TestCaseType> where TestCase.Expectation == Expectation {

   public var stub = StubObject()

   public var stubbedEnvironment: TestStubbedEnvironment {
      return TestSettings.shared.stubbedEnvironment
   }

   public lazy var settings: TestCaseSettings = BundledTestCaseSettings(testCase: self)

   let testCase: TestCase

   var assert: AssertType {
      return TestSettings.shared.assert
   }

   public init(testCase: TestCase) {
      self.testCase = testCase
   }

   public var defaultExpectationTimeout: TimeInterval {
      var value: TimeInterval = stubbedEnvironment.numberOfStubs > 0 ? 30 : 60
      if TestSettings.shared.testEnvironment.isUnderPlaygroundTesting {
         value = 900
      }
      return value
   }

   public lazy var operationQueue: OperationQueue = {
      let queue = OperationQueue()
      queue.qualityOfService = .userInitiated
      queue.name = "com.testability.TestQueue"
      return queue
   }()

   open func setUp() {
      stubbedEnvironment.removeAllSubs()
      cleanupEnvironment()
   }

   open func tearDown() {
      stubbedEnvironment.removeAllSubs()
      cleanupEnvironment()
   }

   func cleanupEnvironment() {
      // Base class does nothing.
   }

   var resource: TestResource {
      return TestResource(rootDirPath: settings.rootDirPath)
   }
}

extension AbstractLogicTestCase {

   var isPlaygroundTest: Bool {
      let result = testCase.testName.lowercased().contains("playground")
      return result
   }

   func wait(expectation: Expectation) {
      testCase.wait(for: [expectation], timeout: defaultExpectationTimeout, enforceOrder: false)
   }

   func wait(expectations: [Expectation]) {
      testCase.wait(for: expectations, timeout: defaultExpectationTimeout, enforceOrder: false)
   }
}

extension AbstractLogicTestCase {

   public func testTask(function: StaticString = #function,
                        file: StaticString = #file, line: UInt = #line, closure: (Expectation?) throws -> Void) {
      let exp = testCase.defaultExpectation(function: function, file: file, line: line)
      weak var weakExp = exp
      do {
         try closure(weakExp)
         wait(expectation: exp)
         weakExp = nil
      } catch {
         assert.fail(error.localizedDescription, file: file, line: line)
      }
   }

   public func testDisposable(function: StaticString = #function,
                              file: StaticString = #file, line: UInt = #line, closure: (Expectation?) throws -> TestDisposable) {
      let exp = testCase.defaultExpectation(function: function, file: file, line: line)
      weak var weakExp = exp
      do {
         let token = try closure(weakExp)
         wait(expectation: exp)
         weakExp = nil
         token.dispose()
      } catch {
         assert.fail(error.localizedDescription, file: file, line: line)
      }
   }

   public func testTask(notification: NSNotification.Name, file: StaticString = #file, line: UInt = #line,
                        closure: @escaping () throws -> Void) {
      let exp = testCase.expectation(forNotification: notification, object: nil, handler: nil)
      do {
         try closure()
         wait(expectation: exp)
      } catch {
         assert.fail(error.localizedDescription, file: file, line: line)
      }
   }

   public func testRequest(file: StaticString = #file, line: UInt = #line, closure: (Expectation?) throws -> TestWorkItem) {
      let exp = testCase.expectation(description: #function)
      weak var weakExp = exp
      do {
         let task = try closure(weakExp)
         task.resume()
         wait(expectation: exp)
         weakExp = nil
      } catch {
         assert.fail(error.localizedDescription, file: file, line: line)
         exp.fulfill()
      }
   }

   public func testOperation(file: StaticString = #file, line: UInt = #line, closure: () throws -> Operation) {
      let exp = testCase.expectation(description: #function)
      weak var weakExp = exp
      do {
         let operation = try closure()
         operation.completionBlock = {
            weakExp?.fulfill()
         }
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { // Small timeout to support cancellation.
            self.operationQueue.addOperation(operation)
         }
         wait(expectation: exp)
         weakExp = nil
      } catch {
         assert.fail(error.localizedDescription, file: file, line: line)
         exp.fulfill()
      }
   }

   public func testOperation(file: StaticString = #file, line: UInt = #line, closure: (Expectation?) throws -> Operation) {
      let exp = testCase.expectation(description: #function)
      weak var weakExp = exp
      do {
         let operation = try closure(weakExp)
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { // Small timeout to support cancellation.
            self.operationQueue.addOperation(operation)
         }
         wait(expectation: exp)
         weakExp = nil
      } catch {
         assert.fail(error.localizedDescription, file: file, line: line)
         exp.fulfill()
      }
   }
}

extension AbstractLogicTestCase {

   func createTemporaryTestDirectory() {
      let fm = FileManager.default
      do {
         try fm.createDirectory(atPath: settings.tmpDirPath, withIntermediateDirectories: true, attributes: nil)
      } catch {
         fatalError()
      }
   }

   func removeTemporaryTestDirectory() {
      let fm = FileManager.default
      var isDir = ObjCBool(false)
      let isExists = fm.fileExists(atPath: settings.tmpDirPath, isDirectory: &isDir)
      if isExists, isDir.boolValue {
         _ = try? fm.removeItem(atPath: settings.tmpDirPath)
      }
   }

   public func dataContents(pathComponent: String, file: StaticString = #file, line: UInt = #line) -> Data {
      do {
         return try TestSettings.shared.fixture.data(of: .api, pathComponent: pathComponent)
      } catch {
         assert.fail(String(describing: error), file: file, line: line)
         return Data()
      }
   }

   func dictionaryContentsOfTestFile(pathComponent: String, file: StaticString = #file,
                                     line: UInt = #line) -> [AnyHashable: Any] {
      do {
         let data = try resource.data(pathComponent: pathComponent)
         guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any] else {
            fatalError()
         }
         return json
      } catch {
         assert.fail(String(describing: error), file: file, line: line)
         return [:]
      }
   }

   public func jsonValue(pathComponent: String, file: StaticString = #file, line: UInt = #line) -> [String: Any] {
      do {
         let data = try resource.data(pathComponent: pathComponent)
         guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            fatalError()
         }
         return json
      } catch {
         assert.fail(String(describing: error), file: file, line: line)
         return [:]
      }
   }

   func jsonArrayOfTestFile(pathComponent: String, file: StaticString = #file,
                            line: UInt = #line) -> [[AnyHashable: Any]] {
      do {
         let data = try resource.data(pathComponent: pathComponent)
         guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[AnyHashable: Any]] else {
            fatalError()
         }
         return json
      } catch {
         assert.fail(String(describing: error), file: file, line: line)
         return []
      }
   }
}

extension AbstractLogicTestCase {

   public func benchmark(_ closure: () -> Void) -> CFTimeInterval {
      let startTime = CFAbsoluteTimeGetCurrent()
      closure()
      return CFAbsoluteTimeGetCurrent() - startTime
   }

   public func noop() {
   }
}

// Just exposing methods for less typing.
extension AbstractLogicTestCase {

   func addStub(statusCode: Int, json: [AnyHashable: Any]) throws {
      let data = try JSONSerialization.data(withJSONObject: json, options: [])
      stubbedEnvironment.addStub(statusCode: statusCode, data: data)
   }

   func addStub(statusCode: Int, fileAtPath: String) throws {
      let url = URL(fileURLWithPath: fileAtPath)
      let data = try Data(contentsOf: url)
      stubbedEnvironment.addStub(statusCode: statusCode, data: data)
   }

   func addStub(failure: Error) {
      stubbedEnvironment.addStub(isURL: { _ in true }, failure: failure)
   }

   func addStub(isURL: @escaping (URL) -> Bool, failure: Error) {
      stubbedEnvironment.addStub(isURL: isURL, failure: failure)
   }

   func addStub(isURL: @escaping (URL) -> Bool, statusCode: Int, fileAtPath: String) throws {
      let url = URL(fileURLWithPath: fileAtPath)
      let data = try Data(contentsOf: url)
      stubbedEnvironment.addStub(isURL: isURL, statusCode: statusCode, response: { _ in data })
   }

   func addStub(isQuery: @escaping (String) -> Bool, statusCode: Int, fileAtPath: String) throws {
      stubbedEnvironment.addStub(isQuery: isQuery, statusCode: statusCode, fileAtPath: fileAtPath)
   }

   func addInfiniteResponseStub(isQuery: @escaping (String) -> Bool, cancelHandler: (() -> Void)?) {
      stubbedEnvironment.addInfiniteResponseStub(isQuery: isQuery, cancelHandler: cancelHandler)
   }

   func addInfiniteResponseStub(isURL: @escaping (URL) -> Bool, cancelHandler: (() -> Void)?) {
      stubbedEnvironment.addInfiniteResponseStub(isURL: isURL, cancelHandler: cancelHandler)
   }
}

extension AbstractLogicTestCase {

   func addStub(isURL: @escaping (URL) -> Bool = { _ in true }, statusCode: Int = 200, json: Any,
                file: StaticString = #file, line: UInt = #line) {
      do {
         let data = try JSONSerialization.data(withJSONObject: json, options: [])
         stubbedEnvironment.addStub(isURL: isURL, statusCode: statusCode, response: { _ in data })
      } catch {
         assert.fail(String(describing: error), file: file, line: line)
      }
   }

   func addStub(isURL: @escaping (URL) -> Bool = { _ in true },
                statusCode: Int = 200, data: Data, file: StaticString = #file, line: UInt = #line) {
      stubbedEnvironment.addStub(isURL: isURL, statusCode: statusCode, response: { _ in data })
   }

   func addStub(file: StaticString = #file, line: UInt = #line,
                isURL: @escaping (URL) -> Bool = { _ in true },
                statusCode: Int = 200, response: @escaping ((URLRequest) throws -> Data)) {
      stubbedEnvironment.addStub(isURL: isURL, statusCode: statusCode, response: response)
   }

   func addStub(statusCode: Int = 200, pathComponent: String, file: StaticString = #file, line: UInt = #line) {
      do {
         try addStub(statusCode: statusCode, fileAtPath: settings.rootDirPath + "/" + pathComponent)
      } catch {
         assert.fail(String(describing: error), file: file, line: line)
      }
   }

   func addStub(isURL: @escaping (URL) -> Bool, statusCode: Int = 200, pathComponent: String, file: StaticString = #file,
                line: UInt = #line) {
      do {
         try addStub(isURL: isURL, statusCode: statusCode, fileAtPath: settings.rootDirPath + "/" + pathComponent)
      } catch {
         assert.fail(String(describing: error), file: file, line: line)
      }
   }

   func removeAllSubs() {
      stubbedEnvironment.removeAllSubs()
   }
}
