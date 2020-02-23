//
//  MainMenu.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 11.02.18.
//  Copyright © 2018 WaveLabs. All rights reserved.
//

import AppKit
import mcUIReusable

class MainMenu: NSMenu {

   init() {
      super.init(title: "")
      let appMenuItem = NSMenuItem()
      addItems(appMenuItem)
      appMenuItem.submenu = makeAppMenu()
   }

   required init(coder decoder: NSCoder) {
      super.init(coder: decoder)
   }
}

extension MainMenu {

   private func makeAppMenu() -> NSMenu {
      let menu = NSMenu(title: "")
      menu.addItem(Menu.App.about)
      menu.addItem(Menu.separator)
      menu.addItems(Menu.App.hide, Menu.App.hideOthers, Menu.App.showAll)
      menu.addItem(Menu.separator)
      menu.addItem(Menu.App.quit)
      return menu
   }
}
