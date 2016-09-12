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

   func applicationDidFinishLaunching(_ aNotification: Notification) {
      do {
         let inputDeviceID = try AudioDevice.defaultDeviceForScope(scope: .Input)
         let outputDeviceID = try AudioDevice.defaultDeviceForScope(scope: .Output)
         renderUtility = try PlayThroughRenderUtility(inputDevice: inputDeviceID, outputDevice: outputDeviceID)
         try renderUtility?.start()
      } catch {
         print(error)
      }
   }

   func applicationWillTerminate(_ aNotification: Notification) {
      renderUtility = nil
   }

   func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
      renderUtility = nil
      return true
   }


}