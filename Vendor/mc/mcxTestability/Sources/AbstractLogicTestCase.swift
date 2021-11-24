//
//  AbstractLogicTestCase.swift
//  MCA-OSS-CARB
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation
import mcxTestabilityFixtures

open class AbstractLogicTestCase<Expectation, TestCase: TestCaseType> where TestCase.Expectation == Expectation {

   enum Error: Swift.Error {
      case unexpectedDataType(Any.Type, expected: Any.Type)
   }

   public var stub = StubObject()

   public var stubbedEnvironment: TestStubbedEnvironment {
      return TestSettings.shared.stubbedEnvironment
   }

   public var tmpDirPath: String {
      return NSTemporaryDirectory().appendingPathComponent(testCase.testName.replacingOccurrences(of: ":", with: ""))
   }

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

   public var resource: TestResource {
      return TestResource()
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
                        file: StaticString = #file, line: UInt = #line, closure: (Expectation?) throws -> Void)
   {
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
                              file: StaticString = #file, line: UInt = #line, closure: (Expectation?) throws -> TestDisposable)
   {
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
                        closure: @escaping () throws -> Void)
   {
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
         try fm.createDirectory(atPath: tmpDirPath, withIntermediateDirectories: true, attributes: nil)
      } catch {
         fatalError()
      }
   }

   func removeTemporaryTestDirectory() {
      let fm = FileManager.default
      var isDir = ObjCBool(false)
      let isExists = fm.fileExists(atPath: tmpDirPath, isDirectory: &isDir)
      if isExists, isDir.boolValue {
         _ = try? fm.removeItem(atPath: tmpDirPath)
      }
   }

   public func dataContents(pathComponent: String, file: StaticString = #file, line: UInt = #line) -> Data {
      do {
         return try TestSettings.shared.fixture.data(atPathComponent: pathComponent, kind: .api, location: .bundled)
      } catch {
         assert.fail(String(describing: error), file: file, line: line)
         return Data()
      }
   }

   func dictionaryContentsOfTestFile(pathComponent: String, file: StaticString = #file,
                                     line: UInt = #line) -> [AnyHashable: Any]
   {
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
                            line: UInt = #line) -> [[AnyHashable: Any]]
   {
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
                file: StaticString = #file, line: UInt = #line)
   {
      do {
         let data = try JSONSerialization.data(withJSONObject: json, options: [])
         stubbedEnvironment.addStub(isURL: isURL, statusCode: statusCode, response: { _ in data })
      } catch {
         assert.fail(String(describing: error), file: file, line: line)
      }
   }

   func addStub(isURL: @escaping (URL) -> Bool = { _ in true },
                statusCode: Int = 200, data: Data, file: StaticString = #file, line: UInt = #line)
   {
      stubbedEnvironment.addStub(isURL: isURL, statusCode: statusCode, response: { _ in data })
   }

   func addStub(file: StaticString = #file, line: UInt = #line,
                isURL: @escaping (URL) -> Bool = { _ in true },
                statusCode: Int = 200, response: @escaping ((URLRequest) throws -> Data))
   {
      stubbedEnvironment.addStub(isURL: isURL, statusCode: statusCode, response: response)
   }

   func addStub(statusCode: Int = 200, pathComponent: String, file: StaticString = #file, line: UInt = #line) {
      do {
         let path = TestSettings.shared.testEnvironment.testabilityRootPath
         try addStub(statusCode: statusCode, fileAtPath: path + "/" + pathComponent)
      } catch {
         assert.fail(String(describing: error), file: file, line: line)
      }
   }

   func addStub(isURL: @escaping (URL) -> Bool, statusCode: Int = 200, pathComponent: String, file: StaticString = #file,
                line: UInt = #line)
   {
      do {
         let path = TestSettings.shared.testEnvironment.testabilityRootPath
         try addStub(isURL: isURL, statusCode: statusCode, fileAtPath: path + "/" + pathComponent)
      } catch {
         assert.fail(String(describing: error), file: file, line: line)
      }
   }

   func removeAllSubs() {
      stubbedEnvironment.removeAllSubs()
   }
}

extension AbstractLogicTestCase {

   enum Component: Int {
      case generic
      case thirdPartyJira
      case thirdPartyZenDesk

      var name: String {
         switch self {
         case .generic: return "Generic"
         case .thirdPartyJira: return "3P/Jira"
         case .thirdPartyZenDesk: return "3P/ZenDesk"
         }
      }
   }

   enum Response {

      case file(String)
      case response(String, Int)
      case success(String, Int)
      case failure(String, Int)

      var fileName: String {
         switch self {
         case .success(let name, let status): return "success.\(name).\(status).json"
         case .failure(let name, let status): return "failure.\(name).\(status).json"
         case .response(let filePath, _): return filePath
         case .file(let filePath): return filePath
         }
      }

      var statusCode: Int {
         switch self {
         case .success(_, let status): return status
         case .failure(_, let status): return status
         case .response(_, let status): return status
         case .file: return 200 // Not used.
         }
      }
   }
}

extension AbstractLogicTestCase {

   static func response(component: Component = .generic, response: Response) throws -> Data {
      let resourcePath = Bundle(for: self).resourcePath!.appending("/APIResponses.bundle")
      let filePath = resourcePath.appending("/" + component.name).appending("/" + response.fileName)
      let url = URL(fileURLWithPath: filePath)
      let data = try Data(contentsOf: url)
      return data
   }

   func response(component: Component = .generic, response: Response) throws -> Data {
      return try type(of: self).response(component: component, response: response)
   }

   static func jsonResponse(component: Component = .generic, response: Response) throws -> [AnyHashable: Any] {
      let data = try self.response(component: component, response: response)
      let json = try JSONSerialization.jsonObject(with: data)
      guard let result = json as? [AnyHashable: Any] else {
         throw Error.unexpectedDataType(type(of: json), expected: [AnyHashable: Any].self)
      }
      return result
   }

   func jsonResponse(component: Component = .generic, response: Response) throws -> [AnyHashable: Any] {
      return try type(of: self).jsonResponse(component: component, response: response)
   }

   func request(component: Component, fileName: String) throws -> Data {
      let resourcePath = Bundle(for: type(of: self)).resourcePath!.appending("/APIRequests.bundle")
      let filePath = resourcePath.appending("/" + component.name).appending("/" + fileName)
      let url = URL(fileURLWithPath: filePath)
      let data = try Data(contentsOf: url)
      return data
   }
}

extension AbstractLogicTestCase {

   private static func responseFilePath(endpoint: TestAPIEndpoint, response: Response) -> String {
      let resourcePath = Bundle(for: self).resourcePath!.appending("/APIResponses.bundle")
      var pathComponent = endpoint.urlPathComponent.replacingOccurrences(of: ".json", with: "")
      pathComponent = pathComponent.replacingOccurrences(of: "/", with: "-")
      let filePath = resourcePath.appending("/Endpoint/" + pathComponent).appending("/" + response.fileName)
      return filePath
   }

   static func response(endpoint: TestAPIEndpoint, response: Response) throws -> Data {
      let filePath = responseFilePath(endpoint: endpoint, response: response)
      let url = URL(fileURLWithPath: filePath)
      let data = try Data(contentsOf: url)
      return data
   }

   static func jsonResponse(endpoint: TestAPIEndpoint, response: Response) throws -> [AnyHashable: Any] {
      let data = try self.response(endpoint: endpoint, response: response)
      let json = try JSONSerialization.jsonObject(with: data)
      guard let result = json as? [AnyHashable: Any] else {
         throw Error.unexpectedDataType(type(of: json), expected: [AnyHashable: Any].self)
      }
      return result
   }

   func response(endpoint: TestAPIEndpoint, response: Response) throws -> Data {
      return try type(of: self).response(endpoint: endpoint, response: response)
   }

   func jsonResponse(endpoint: TestAPIEndpoint, response: Response) throws -> [AnyHashable: Any] {
      return try type(of: self).jsonResponse(endpoint: endpoint, response: response)
   }

   func addStub(_ endpoint: TestAPIEndpoint, _ response: Response) throws {
      let filePath = type(of: self).responseFilePath(endpoint: endpoint, response: response)
      let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
      stubbedEnvironment.addStub(statusCode: response.statusCode, data: data)
   }

   func addImageUploaderStub(_ endpoint: TestAPIEndpoint, _ response: Response) throws {
      let filePath = type(of: self).responseFilePath(endpoint: endpoint, response: response)
      let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
      stubbedEnvironment.addStub(statusCode: response.statusCode, data: data)
   }

   func addImageUploaderStub(_ component: Component, _ response: Response) throws {
      let resourcePath = Bundle(for: type(of: self)).resourcePath!.appending("/APIResponses.bundle")
      let filePath = resourcePath.appending("/" + component.name).appending("/" + response.fileName)
      let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
      stubbedEnvironment.addStub(statusCode: response.statusCode, data: data)
   }

   func addInfiniteResponseStub(isQuery: @escaping (String) -> Bool) {
      stubbedEnvironment.addInfiniteResponseStub(isQuery: isQuery, cancelHandler: nil)
   }

   func addStub(_: TestAPIEndpoint, _ statusCode: Int, _ json: [AnyHashable: Any]) {
      do {
         let data = try JSONSerialization.data(withJSONObject: json, options: [])
         stubbedEnvironment.addStub(statusCode: statusCode, data: data)
      } catch {
         fatalError("Unable to encode JSON object: \(json)")
      }
   }

   func addStub(isURL: @escaping (URL) -> Bool, _ endpoint: TestAPIEndpoint, _ response: Response) throws {
      let filePath = type(of: self).responseFilePath(endpoint: endpoint, response: response)
      let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
      stubbedEnvironment.addStub(isURL: isURL, statusCode: response.statusCode, response: { _ in data })
   }

   func addStub(isQuery: @escaping (String) -> Bool, _ endpoint: TestAPIEndpoint, _ response: Response) {
      let filePath = type(of: self).responseFilePath(endpoint: endpoint, response: response)
      stubbedEnvironment.addStub(isQuery: isQuery, statusCode: response.statusCode, fileAtPath: filePath)
   }

   func addStub(isURL: @escaping (URL) -> Bool = { _ in true }, _ component: Component, _ response: Response) throws {
      let resourcePath = Bundle(for: type(of: self)).resourcePath!.appending("/APIResponses.bundle")
      let filePath = resourcePath.appending("/" + component.name).appending("/" + response.fileName)
      let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
      stubbedEnvironment.addStub(isURL: isURL, statusCode: response.statusCode, response: { _ in data })
   }

   func addStub(error: Swift.Error) {
      stubbedEnvironment.addStub(isURL: { _ in true }, failure: error)
   }
}
