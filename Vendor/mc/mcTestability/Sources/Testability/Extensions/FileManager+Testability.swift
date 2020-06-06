//
//  FileManager+Testability.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

extension FileManager {

   func regularFileExists(atPath path: String) -> Bool {
      var isDir = ObjCBool(false)
      let isExists = fileExists(atPath: path, isDirectory: &isDir)
      return isExists && !isDir.boolValue
   }

   func directoryExists(atPath path: String) -> Bool {
      var isDir = ObjCBool(false)
      let isExists = fileExists(atPath: path, isDirectory: &isDir)
      return isExists && isDir.boolValue
   }
}
