//
//  TestabilityMenuViewController.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 22.11.18.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

class TestabilityMenuViewController: MenuViewController {

   enum Event {
      case close
      case resize(TestabilityScreenSize)
   }

   var eventHandler: ((Event) -> Void)?
   var activeSizes: [TestabilityScreenSize] = []

   override func numberOfSections(in tableView: UITableView) -> Int {
      return 2
   }

   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return section == 0 ? 1 : activeSizes.count
   }

   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell: UITableViewCell
      let reuseIdentifier = "cid:standard.default"
      if let value = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) {
         cell = value
      } else {
         cell = UITableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
      }
      cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
      cell.textLabel?.textColor = UIColor.black
      cell.backgroundColor = .clear
      if indexPath.section == 0 {
         cell.textLabel?.text = "Close"
      } else {
         let menuID = activeSizes[indexPath.row]
         cell.textLabel?.text = menuID.rawValue
      }
      return cell
   }

   override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      tableView.deselectRow(at: indexPath, animated: true)
      if indexPath.section == 0 {
         eventHandler?(.close)
      } else {
         let menuID = activeSizes[indexPath.row]
         eventHandler?(.resize(menuID))
      }
   }
}

#endif
