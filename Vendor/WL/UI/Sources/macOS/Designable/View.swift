//
//  View.swift
//  mcDecodeAppKit
//
//  Created by Vlad Gorlov on 16.10.17.
//  Copyright © 2017 Demo. All rights reserved.
//

import AppKit

open class View: NSView {

   public var backgroundColor: NSColor?
   private var mIsFlipped: Bool?

   open override var isFlipped: Bool {
      return mIsFlipped ?? super.isFlipped
   }

   public init() {
      super.init(frame: NSRect())
      initializeView()
   }

   public required init?(coder decoder: NSCoder) {
      fatalError()
   }

   open override func draw(_ dirtyRect: NSRect) {
      if let backgroundColor = backgroundColor {
         backgroundColor.setFill()
         dirtyRect.fill()
      } else {
         super.draw(dirtyRect)
      }
   }

   open func initializeView() {
      // Do something
   }
}

extension View {

   public func setIsFlipped(_ value: Bool?) {
      mIsFlipped = value
   }
}
