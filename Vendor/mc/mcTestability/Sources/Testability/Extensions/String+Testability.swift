//
//  String+Testability.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

extension String {

   var deletingLastPathComponent: String {
      return (self as NSString).deletingLastPathComponent
   }

   var deletingPathExtension: String {
      return (self as NSString).deletingPathExtension
   }

   func appendingPathExtension(_ str: String) -> String? {
      return (self as NSString).appendingPathExtension(str)
   }

   func appendingPathComponent(_ str: String) -> String {
      return (self as NSString).appendingPathComponent(str)
   }

   var pathExtension: String {
      return (self as NSString).pathExtension
   }
}
