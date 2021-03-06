//
//  AbstractLogicTestCase.Components.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

extension AbstractLogicTestCase {

   enum Error: Swift.Error {
      case unexpectedDataType(Any.Type, expected: Any.Type)
   }

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
