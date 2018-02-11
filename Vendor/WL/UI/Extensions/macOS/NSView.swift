//
//  NSView.swift
//  WLUI
//
//  Created by Vlad Gorlov on 12.08.17.
//  Copyright © 2017 Demo. All rights reserved.
//

import AppKit

extension NSView {

   public func addSubviews(_ views: NSView...) {
      for view in views {
         addSubview(view)
      }
   }

   public func addSubviews(_ views: [NSView]) {
      for view in views {
         addSubview(view)
      }
   }

   public func removeSubviews() {
      subviews.forEach { $0.removeFromSuperview() }
   }

   public func withFocus(drawingCalls: (() -> Void)) {
      lockFocus()
      drawingCalls()
      unlockFocus()
   }
}

extension NSView {

   public func autolayoutView() -> Self {
      translatesAutoresizingMaskIntoConstraints = false
      return self
   }

   /// Prints results of internal Apple API method `_subtreeDescription` to console.
   public func dump() {
      let value = perform(Selector(("_subtreeDescription")))
      Swift.print(String(describing: value))
   }
}
