//
//  TestEnvironment.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

public protocol TestEnvironment {

   var isUnderPlaygroundTesting: Bool { get }
   var isReferenceTest: Bool { get }
}
