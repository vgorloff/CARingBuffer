//
//  MenuViewController.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 17.04.20.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

class MenuViewController: UITableViewController {

   init() {
      super.init(style: .plain)
      #if os(iOS)
      modalPresentationStyle = .popover
      popoverPresentationController?.delegate = self
      #endif
   }

   required init?(coder: NSCoder) {
      fatalError()
   }

   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      preferredContentSize = tableView.contentSize
   }

   override func viewDidLoad() {
      super.viewDidLoad()
      view.backgroundColor = UIColor.white
      tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
   }
}

#if os(iOS)
extension MenuViewController: UIPopoverPresentationControllerDelegate {

   func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
      return .none
   }
}
#endif

#endif
