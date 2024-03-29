//
//  TestabilityRuntime.swift
//  MCA-OSS-CARB
//
//  Created by Vlad Gorlov on 26.02.20.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

public enum TestabilityRuntime {

   public class UI {

      enum Key: String {
         case isScreenshotTestsEnabled = "app.tests.ui.isScreenshotTestsEnabled"
      }

      public var isScreenshotTestsEnabled: Bool {
         return TestabilityRuntime.isEnabled(variableName: Key.isScreenshotTestsEnabled.rawValue)
      }
   }

   public static var ui: UI {
      return UI()
   }

   public enum Constants {
      public static let isReferenceTest = "app.runtime.isReferenceTest"
      public static let isStubsDisabled = "app.runtime.isStubsDisabled"
      public static let isPlaygroundTesting = "app.runtime.isPlaygroundTesting"
      public static let isUITesting = "app.runtime.isUITestingMode"
   }

   public static let isUITesting: Bool = {
      isEnabled(variableName: Constants.isUITesting)
   }()

   public static let isStubsDisabled: Bool = {
      isEnabled(variableName: Constants.isStubsDisabled)
   }()

   public static let isPlaygroundTesting: Bool = {
      isEnabled(variableName: Constants.isPlaygroundTesting)
   }()

   public static let isReferenceTest: Bool = {
      isEnabled(variableName: Constants.isReferenceTest)
   }()
}

extension TestabilityRuntime {

   private static func isEnabled(variableName: String, defaultValue: Bool = false) -> Bool {
      let variable = ProcessInfo.processInfo.environment[variableName]
      if let value = variable?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
         return value == "yes" || value == "true"
      } else {
         return defaultValue
      }
   }
}
