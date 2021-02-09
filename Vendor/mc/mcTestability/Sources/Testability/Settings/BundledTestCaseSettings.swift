//
//  BundledTestCaseSettings.swift
//  Decode
//
//  Created by Vlad Gorlov on 04.02.21.
//

import Foundation

public class BundledTestCaseSettings: TestCaseSettings {

   private var mRootDirPath: String!

   public override var rootDirPath: String {
      return mRootDirPath
   }

   init(testCase: AnyObject, bundleName: String = "Data.bundle") {
      super.init(testCase: testCase)
      mRootDirPath = bundle.resourcePath! + "/" + bundleName
   }
}

