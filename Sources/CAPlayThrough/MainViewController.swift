//
//  MainViewController.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 27.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import Cocoa
import mcUIReusable

class MainViewController: ViewController {

   lazy var toggleEngineButton = Button(title: "").autolayoutView()

   override func loadView() {
      super.loadView()
      content.view.addSubview(toggleEngineButton)
   }

   override func setupLayout() {
      let constraints = [
         toggleEngineButton.centerXAnchor.constraint(equalTo: content.view.centerXAnchor),
         toggleEngineButton.centerYAnchor.constraint(equalTo: content.view.centerYAnchor)
      ]
      NSLayoutConstraint.activate(constraints)
   }
}
