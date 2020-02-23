//
//  MainWindowController.swift
//  WL
//
//  Created by Vlad Gorlov on 11.02.18.
//  Copyright © 2018 WaveLabs. All rights reserved.
//

import AppKit
import mcUIReusable

class MainWindowController: WindowController {

   init(viewController: NSViewController) {
      let window = Window(contentRect: CGRect(origin: CGPoint(), size: CGSize(width: 300, height: 172)), style: .default)
      window.styleMask.remove(.resizable)
      super.init(window: window, viewController: viewController)
   }

   public required init?(coder: NSCoder) {
      fatalError()
   }
}
