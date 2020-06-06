//
//  ActionsViewController.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 17.04.20.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

class ActionsViewController: MenuViewController {

   var actions: [(String, () -> Void)] = []

   override func numberOfSections(in tableView: UITableView) -> Int {
      return 2
   }

   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return section == 0 ? 1 : actions.count
   }

   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let id = "cid:standard.default"
      let cell = tableView.dequeueReusableCell(withIdentifier: id) ?? UITableViewCell(style: .default, reuseIdentifier: id)
      cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
      cell.backgroundColor = .clear
      cell.textLabel?.textColor = UIColor.black
      if indexPath.section == 0 {
         cell.textLabel?.text = "Close"
      } else {
         let action = actions[indexPath.row]
         cell.textLabel?.text = action.0
      }
      return cell
   }

   override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      tableView.deselectRow(at: indexPath, animated: true)
      if indexPath.section == 0 {
         dismiss(animated: false, completion: nil)
      } else {
         let action = actions[indexPath.row]
         dismiss(animated: false, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
               print("→ Performing test action: \(action.0)")
               action.1()
            }
         })
      }
   }
}

#endif
