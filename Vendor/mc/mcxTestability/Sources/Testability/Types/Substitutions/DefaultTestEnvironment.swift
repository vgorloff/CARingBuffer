//
//  DefaultTestEnvironment.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 04.09.18.
//  Copyright © 2018 Vlad Gorlov. All rights reserved.
//

import Foundation

public struct DefaultTestEnvironment: TestEnvironment {

   public var isUnderPlaygroundTesting: Bool
   public var isReferenceTest: Bool

   public init(isUnderPlaygroundTesting: Bool = false, isReferenceTest: Bool = false) {
      self.isUnderPlaygroundTesting = isUnderPlaygroundTesting
      self.isReferenceTest = isReferenceTest
   }
}
