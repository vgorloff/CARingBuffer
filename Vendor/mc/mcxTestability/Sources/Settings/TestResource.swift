//
//  TestResource.swift
//  MCA-OSS-CARB
//
//  Created by Vlad Gorlov on 04.02.21.
//

import Foundation

public class TestResource {

   public var rootPath: String {
      let path = TestSettings.shared.testEnvironment.testabilityRootPath
      return path
   }

   public func url(pathComponent: String) -> URL {
      let url = URL(fileURLWithPath: rootPath + "/" + pathComponent)
      return url
   }

   public func data(pathComponent: String) throws -> Data {
      return try Data(contentsOf: url(pathComponent: pathComponent))
   }

   public func string(pathComponent: String, encoding: String.Encoding = .utf8) throws -> String {
      let contents = try data(pathComponent: pathComponent)
      if let string = String(data: contents, encoding: encoding) {
         return string
      } else {
         fatalError() // FIXME: Throw
      }
   }

   public func object<T>(pathComponent: String, decoder: JSONDecoder = JSONDecoder(),
                         file: StaticString = #file, line: UInt = #line) throws -> T where T: Decodable
   {
      do {
         let contents = try data(pathComponent: pathComponent)
         let result = try decoder.decode(T.self, from: contents)
         return result
      } catch {
         TestSettings.shared.assert.shouldNeverHappen(error, file: file, line: line)
         throw error
      }
   }
}
