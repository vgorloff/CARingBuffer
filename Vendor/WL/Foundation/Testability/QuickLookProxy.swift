//
//  QuickLookProxy.swift
//  mcBase-macOS
//
//  Created by Vlad Gorlov on 20.08.18.
//  Copyright © 2018 WaveLabs. All rights reserved.
//

import Foundation

public typealias QLP = QuickLookProxy

public class QuickLookProxy: NSObject {

   public let object: AnyObject?

   public init(data: [Float]) {
      object = QuickLookFactory.object(from: data)
      super.init()
   }

   public init(data: [[Float]]) {
      object = QuickLookFactory.object(from: data)
      super.init()
   }

   public init(object: AnyObject?) {
      self.object = object
      super.init()
   }

   @objc public func debugQuickLookObject() -> AnyObject? {
      return object
   }

   public override var description: String {
      return object?.description ?? "nil"
   }
}

