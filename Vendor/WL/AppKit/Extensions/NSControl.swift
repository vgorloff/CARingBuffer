//
//  NSControl.swift
//  WLUI
//
//  Created by Vlad Gorlov on 12.08.17.
//  Copyright © 2017 Demo. All rights reserved.
//

import AppKit

extension NSControl {

   public typealias Handler = (() -> Void)

   public func setHandler(_ handler: Handler?) {
      target = self
      action = #selector(wavelabsActionHandler(_:))
      if let handler = handler {
         ObjCAssociation.setCopyNonAtomic(value: handler, to: self, forKey: &OBJCAssociationKeys.actionHandler)
      }
   }
}

extension NSControl {

   private struct OBJCAssociationKeys {
      static var actionHandler = "com.wavelabs.actionHandler"
   }

   @objc private func wavelabsActionHandler(_ sender: NSControl) {
      guard sender == self else {
         return
      }
      if let handler: Handler = ObjCAssociation.value(from: self, forKey: &OBJCAssociationKeys.actionHandler) {
         handler()
      }
   }
}
