//
//  MCATestabilityEnvironment.swift
//  MCA-OSS-CARB
//
//  Created by Vlad Gorlov on 04.09.18.
//  Copyright © 2018 Vlad Gorlov. All rights reserved.
//

import Foundation

public class MCATestabilityEnvironment {

   public var isUnderPlaygroundTesting = TestabilityRuntime.isPlaygroundTesting
   public var isReferenceTest = TestabilityRuntime.isReferenceTest
   public var testabilityRootPath = "/tmp/mca-testability-root" // Set it from test.
}
