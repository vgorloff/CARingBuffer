//
//  ViewController.swift
//  mcUI-iOS
//
//  Created by Vlad Gorlov on 03.02.18.
//  Copyright © 2018 Demo. All rights reserved.
//

import AppKit

// TODO: Use generics to define ViewType.
open class ViewController: NSViewController {

   public let contentView = View()
   private let layoutUntil = DispatchUntil()

   open override func loadView() {
      view = contentView
   }

   public init() {
      super.init(nibName: nil, bundle: nil)
   }

   public required init?(coder: NSCoder) {
      fatalError()
   }

   open override func viewDidLayout() {
      super.viewDidLayout()
      layoutUntil.performIfNeeded {
         setupLayoutDefaults()
      }
   }

   open override func viewDidAppear() {
      super.viewDidAppear()
      layoutUntil.fulfill()
   }

   open override func viewDidLoad() {
      super.viewDidLoad()
      setupUI()
      setupLayout()
      setupHandlers()
      setupDefaults()
   }

   open func setupUI() {

   }

   open func setupLayout() {

   }

   open func setupHandlers() {

   }

   open func setupDefaults() {

   }

   open func setupLayoutDefaults() {

   }

}
