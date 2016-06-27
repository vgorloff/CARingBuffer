//
//  AppDelegate.swift
//  CAPlayThrough
//
//  Created by Vlad Gorlov on 27.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	private var renderUtility: PlayThroughRenderUtility?

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		do {
			let inputDeviceID = try AudioDevice.defaultDeviceForScope(.Input)
			let outputDeviceID = try AudioDevice.defaultDeviceForScope(.Output)
			renderUtility = try PlayThroughRenderUtility(inputDevice: inputDeviceID, outputDevice: outputDeviceID)
			try renderUtility?.start()
		} catch {
			print(error)
		}
	}

	func applicationWillTerminate(aNotification: NSNotification) {
		renderUtility = nil
	}

	func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
		renderUtility = nil
		return true
	}


}

