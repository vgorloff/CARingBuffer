//
//  UIViewController+Testability.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

#if os(iOS)
import UIKit

extension UIViewController {

   static func makePresenterController(supportedInterfaceOrientations: UIInterfaceOrientationMask? = nil) -> UIViewController {
      let vc = TestabilityViewController(supportedInterfaceOrientations: supportedInterfaceOrientations)
      vc.view.backgroundColor = .yellow
      return vc
   }

   func tapLeftNavigationButton(file: StaticString = #file, line: UInt = #line) {
      let button = navigationItem.leftBarButtonItem
      TestSettings.shared.assert.notNil(button, nil, file: file, line: line)
      if let button = button {
         Automator.tap(barButtonItem: button)
      }
   }

   func tapRightNavigationButton(file: StaticString = #file, line: UInt = #line) {
      let button = navigationItem.rightBarButtonItem
      TestSettings.shared.assert.notNil(button, nil, file: file, line: line)
      if let button = button {
         Automator.tap(barButtonItem: button)
      }
   }
}
#endif
