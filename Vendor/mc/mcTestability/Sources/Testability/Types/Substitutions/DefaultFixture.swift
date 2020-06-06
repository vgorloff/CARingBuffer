//
//  DefaultFixture.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

struct DefaultFixture: FixtureType {

   let bundle = Bundle.main

   func bundleName(for: FixtureKind) -> String {
      return "Data.bundle"
   }

   func bundlePath(for kind: FixtureKind) -> String {
      return (bundle.resourcePath! as NSString).appendingPathComponent(bundleName(for: kind))
   }

   func localPath(for kind: FixtureKind) -> String {
      return ((#file as NSString).deletingLastPathComponent as NSString).appendingPathComponent(bundleName(for: kind))
   }

   func data(of kind: FixtureKind, pathComponent: String) throws -> Data {
      return Data()
   }
}
