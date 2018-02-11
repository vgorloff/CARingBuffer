//
//  MainViewController.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 27.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import Cocoa

class MainViewController: ViewController {

   lazy var toggleEngineButton = Button(title: "").autolayoutView()

   override func loadView() {
      super.loadView()
      contentView.addSubview(toggleEngineButton)
   }

   override func setupLayout() {
      let constraints = [
         toggleEngineButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
         toggleEngineButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
      ]
      NSLayoutConstraint.activate(constraints)
   }

}
