//
//  ViewController.swift
//  WLUI
//
//  Created by Vlad Gorlov on 03.02.18.
//  Copyright © 2018 Demo. All rights reserved.
//

import AppKit

open class ViewController: NSViewController {

   public let contentView: View
   private let layoutUntil = DispatchUntil()

   open override func loadView() {
      view = contentView
   }

   public init() {
      contentView = View()
      super.init(nibName: nil, bundle: nil)
   }

   public init(view: View) {
      contentView = view
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
      view.assertOnAmbiguityInSubviewsLayout()
      onViewDidAppear()
   }

   open override func viewDidLoad() {
      super.viewDidLoad()
      setupUI()
      setupLayout()
      setupDataSource()
      setupHandlers()
      setupDefaults()
   }

   open override func viewWillAppear() {
      super.viewWillAppear()
      onViewWillAppear()
   }

   @objc dynamic open func setupUI() {
   }

   @objc dynamic open func setupLayout() {
   }

   @objc dynamic open func setupHandlers() {
   }

   @objc dynamic open func setupDefaults() {
   }

   @objc dynamic open func setupDataSource() {
   }

   @objc dynamic open func setupLayoutDefaults() {
   }

   @objc dynamic open func onViewWillAppear() {
   }

   @objc dynamic open func onViewDidAppear() {
   }
}
