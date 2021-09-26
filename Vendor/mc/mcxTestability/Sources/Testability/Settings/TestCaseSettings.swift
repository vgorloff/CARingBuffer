//
//  TestCaseSettings.swift
//  Decode
//
//  Created by Vlad Gorlov on 04.02.21.
//

import Foundation

public class TestCaseSettings {

   let className: String
   let bundleID: String
   let bundle: Bundle

   public var rootDirPath: String {
      fatalError() // Base class does nothing
   }

   public let tmpDirPath: String

   init(testCase: AnyObject) {
      className = NSStringFromClass(type(of: testCase)).components(separatedBy: ".").last!
      bundle = Bundle(for: type(of: testCase))
      bundleID = bundle.bundleIdentifier ?? "mc.test.default"
      tmpDirPath = NSTemporaryDirectory() + "/" + bundleID + "/" + className
   }
}
