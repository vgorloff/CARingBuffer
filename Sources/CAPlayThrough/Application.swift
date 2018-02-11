//
//  Application.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 11.02.18.
//  Copyright © 2018 WaveLabs. All rights reserved.
//

import AppKit

class Application: NSApplication {

   private var renderUtility: PlayThroughEngine?
   private lazy var windowController = MainWindowController()
   private lazy var mainAppMenu = MainMenu()

   override init() {
      super.init()
      mainMenu = mainAppMenu
      delegate = self
      do {
         let inputDeviceID = try AudioDevice.defaultDeviceForScope(scope: .input)
         let outputDeviceID = try AudioDevice.defaultDeviceForScope(scope: .output)
         renderUtility = try PlayThroughEngine(inputDevice: inputDeviceID, outputDevice: outputDeviceID)
      } catch {
         print(error)
      }
   }

   required init?(coder: NSCoder) {
      fatalError()
   }
}

extension Application: NSApplicationDelegate {

   func applicationDidFinishLaunching(_: Notification) {
      windowController.viewController.toggleEngineButton.setHandler { [weak self] in
         self?.toggleEngine()
      }
      windowController.showWindow(nil)
      try? updateUI()
   }

   func applicationWillTerminate(_: Notification) {
      renderUtility = nil
   }

   func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
      renderUtility = nil
      return true
   }
}

extension Application {

   private func toggleEngine() {
      do {
         if try renderUtility?.isRunning() == true {
            try renderUtility?.stop()
         } else {
            try renderUtility?.start()
         }
         try updateUI()
      } catch {
         print(error)
      }
   }

   private func updateUI() throws {
      let button = windowController.viewController.toggleEngineButton
      if try renderUtility?.isRunning() == true {
         button.title = "Stop"
      } else {
         button.title = "Start"
      }
   }
}
