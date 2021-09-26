//
//  TestResource.swift
//  Decode
//
//  Created by Vlad Gorlov on 04.02.21.
//

import Foundation

public class TestResource {

   let rootDirPath: String

   init(rootDirPath: String) {
      self.rootDirPath = rootDirPath
   }

   private var assert: AssertType {
      return TestSettings.shared.assert
   }

   public func data(pathComponent: String) throws -> Data {
      let url = URL(fileURLWithPath: rootDirPath + "/" + pathComponent)
      return try Data(contentsOf: url)
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
                         file: StaticString = #file, line: UInt = #line) throws -> T where T: Decodable {
      do {
         let contents = try data(pathComponent: pathComponent)
         let result = try decoder.decode(T.self, from: contents)
         return result
      } catch {
         assert.shouldNeverHappen(error, file: file, line: line)
         throw error
      }
   }
}
