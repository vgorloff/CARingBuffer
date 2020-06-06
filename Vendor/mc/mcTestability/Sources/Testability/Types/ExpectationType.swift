//
//  ExpectationType.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

public protocol ExpectationType: class {
   func fulfill()
}

extension ExpectationType {

   public func fulfill(if condition: @autoclosure () -> Bool) {
      let isReady = condition()
      if isReady {
         fulfill()
      }
   }
}
