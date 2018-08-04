//
//  View.swift
//  WLUI
//
//  Created by Vlad Gorlov on 16.10.17.
//  Copyright © 2017 Demo. All rights reserved.
//

import AppKit

open class View: NSView {

   public var backgroundColor: NSColor? {
      didSet {
         setNeedsDisplay(bounds)
      }
   }
   private var mIsFlipped: Bool?

   open override var isFlipped: Bool {
      return mIsFlipped ?? super.isFlipped
   }

   public convenience init(backgroundColor: NSColor) {
      self.init()
      self.backgroundColor = backgroundColor
   }

   public init() {
      super.init(frame: NSRect())
      setupUI()
      setupLayout()
      setupDataSource()
      setupHandlers()
      setupDefaults()
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

   open func setupUI() {
   }

   open func setupLayout() {
   }

   open func setupHandlers() {
   }

   open func setupDefaults() {
   }

   open func setupDataSource() {
   }
}

extension View {

   public func setIsFlipped(_ value: Bool?) {
      mIsFlipped = value
   }
}
