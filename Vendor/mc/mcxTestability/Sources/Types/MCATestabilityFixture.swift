//
//  MCATestabilityFixture.swift
//  MCA-OSS-CARB
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

public class MCATestabilityFixture {

   public enum Kind: String {
      case api = "Api", screenshots = "Screenshots"
   }

   public enum Location: Int {
      case local, bundled
   }

   public enum Error: Swift.Error {
      case unableToReadFile(String)
      case unexpectedState
   }

   private lazy var bundlePaths = setupBundlePaths()

   public func bundleName(for kind: Kind) -> String {
      return kind.rawValue + ".bundle"
   }

   public func register(bundlePath: String, forLocation: Location, kind: Kind) {
      bundlePaths[forLocation]?[kind] = bundlePath
   }

   public func rootDirPath(kind: Kind, location: Location) throws -> String {
      guard let path = bundlePaths[location]?[kind] else {
         throw Error.unexpectedState
      }
      return path.appendingPathComponent(bundleName(for: kind))
   }

   func data(atPathComponent pathComponent: String, kind: Kind, location: Location) throws -> Data {
      let filePath = try rootDirPath(kind: kind, location: location).appendingPathComponent(pathComponent)
      guard let data = FileManager.default.contents(atPath: filePath) else {
         throw Error.unableToReadFile(filePath)
      }
      return data
   }

   private func setupBundlePaths() -> [Location: [Kind: String]] {
      var bundlePaths: [Location: [Kind: String]] = [:]
      bundlePaths[.bundled] = [:]
      bundlePaths[.local] = [:]
      bundlePaths[.bundled]?[.api] = Bundle.main.resourcePath
      bundlePaths[.bundled]?[.screenshots] = Bundle.main.resourcePath
      bundlePaths[.local]?[.api] = TestSettings.shared.testEnvironment.testabilityRootPath
      bundlePaths[.local]?[.screenshots] = TestSettings.shared.testEnvironment.testabilityRootPath
      return bundlePaths
   }
}
