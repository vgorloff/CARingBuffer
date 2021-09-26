//
//  TestSettings.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

public class TestSettings {

   public static let shared = TestSettings()

   public var assert: AssertType = DefaultAssert()
   public var fixture: FixtureType = DefaultFixture()
   public var testEnvironment: TestEnvironment = DefaultTestEnvironment()
   public var stubbedEnvironment: TestStubbedEnvironment = DefaultStubbedEnvironment()
}
