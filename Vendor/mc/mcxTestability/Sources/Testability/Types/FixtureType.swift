//
//  FixtureType.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

public protocol FixtureType {

   var bundle: Bundle { get }

   func bundleName(for: FixtureKind) -> String
   func bundlePath(for: FixtureKind) -> String
   func localPath(for: FixtureKind) -> String

   func data(of: FixtureKind, pathComponent: String) throws -> Data
}
