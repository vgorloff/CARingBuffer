//
//  XCUIElementAttributes.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation
#if canImport(XCTest)
import XCTest

extension XCUIElementAttributes {

   var intValue: Int? {
      if let value = stringValue {
         return Int(value)
      } else {
         return nil
      }
   }

   var stringValue: String? {
      if let value = value {
         return value as? String
      } else {
         return nil
      }
   }
}
#endif
