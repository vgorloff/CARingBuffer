//
//  LocalTestCaseSettings.swift
//  Decode
//
//  Created by Vlad Gorlov on 04.02.21.
//

import Foundation

public class LocalTestCaseSettings: TestCaseSettings {

   private let mRootDirPath: String

   override public var rootDirPath: String {
      return mRootDirPath
   }

   public init(testCase: AnyObject, rootDirPath: String) {
      mRootDirPath = rootDirPath
      super.init(testCase: testCase)
   }
}
