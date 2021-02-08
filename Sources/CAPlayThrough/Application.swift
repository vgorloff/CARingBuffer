//
//  Application.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 11.02.18.
//  Copyright © 2018 WaveLabs. All rights reserved.
//

import AppKit
import mcUIReusable
import mcAppKitAudio
import mcRuntime

private let log = Logger.getLogger(Application.self)

class Application: NSApplication {

   private var renderUtility: PlayThroughEngine?
   private lazy var viewController = MainViewController()
   private lazy var windowController = MainWindowController(viewController: viewController)
   private lazy var mainAppMenu = MainMenu()

   override init() {
      super.init()
      mainMenu = mainAppMenu
      delegate = self
      do {
         let inputDevices = try AudioDevice.audioDevicesForScope(scope: .input)
         for inputDevice in inputDevices {
            let name = try AudioDevice.deviceName(deviceID: inputDevice, scope: .input)
            log.verbose("Input device: id=\(inputDevice); name=\(name)")
         }
         let outputDevices = try AudioDevice.audioDevicesForScope(scope: .output)
         for outputDevice in outputDevices {
            let name = try AudioDevice.deviceName(deviceID: outputDevice, scope: .output)
            log.verbose("Output device: id=\(outputDevice); name=\(name)")
         }
         let inputDeviceID = try AudioDevice.defaultDeviceForScope(scope: .input)
         log.verbose("Will use input device: id=\(inputDeviceID); name=\(try AudioDevice.deviceName(deviceID: inputDeviceID, scope: .input))")
         let outputDeviceID = try AudioDevice.defaultDeviceForScope(scope: .output)
         log.verbose("Will use output device: id=\(outputDeviceID); name=\(try AudioDevice.deviceName(deviceID: outputDeviceID, scope: .output))")
         renderUtility = try PlayThroughEngine(inputDevice: inputDeviceID, outputDevice: outputDeviceID)
      } catch {
         log.error(error)
      }
   }

   required init?(coder: NSCoder) {
      fatalError()
   }
}

extension Application: NSApplicationDelegate {

   func applicationDidFinishLaunching(_: Notification) {
      viewController.toggleEngineButton.setHandler { [weak self] in
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
         log.error(error)
      }
   }

   private func updateUI() throws {
      let button = viewController.toggleEngineButton
      if try renderUtility?.isRunning() == true {
         button.title = "Stop"
      } else {
         button.title = "Start"
      }
   }
}
