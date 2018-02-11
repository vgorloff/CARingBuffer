//
//  WindowController.swift
//  WLUI
//
//  Created by Vlad Gorlov on 07.02.18.
//  Copyright © 2018 Demo. All rights reserved.
//

import AppKit

open class WindowController: NSWindowController {

   public let contentWindow: Window

   public init(window: Window, viewController: ViewController) {
      contentWindow = window
      super.init(window: window)
      let frameSize = contentWindow.contentRect(forFrameRect: contentWindow.frame).size
      viewController.view.setFrameSize(frameSize)
      contentWindow.contentViewController = viewController
      if let screenSize = window.screen?.visibleFrame.size {
         let origin = NSPoint(x: (screenSize.width - frameSize.width) / 2,
                              y: (screenSize.height - frameSize.height) / 2)

         contentWindow.setFrameOrigin(origin)
      }

      setupUI()
      setupHandlers()
   }

   public required init?(coder: NSCoder) {
      fatalError()
   }

   open func setupUI() {
   }

   open func setupHandlers() {
   }
}
