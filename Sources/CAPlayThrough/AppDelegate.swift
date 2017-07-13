//
//  AppDelegate.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 27.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

   private var renderUtility: PlayThroughRenderUtility?

   func applicationDidFinishLaunching(_: Notification) {
      do {
         let inputDeviceID = try AudioDevice.defaultDeviceForScope(scope: .input)
         let outputDeviceID = try AudioDevice.defaultDeviceForScope(scope: .output)
         renderUtility = try PlayThroughRenderUtility(inputDevice: inputDeviceID, outputDevice: outputDeviceID)
         try renderUtility?.start()
      } catch {
         print(error)
      }
   }

   func applicationWillTerminate(_: Notification) {
      renderUtility = nil
   }

   func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
      renderUtility = nil
      return true
   }
}
