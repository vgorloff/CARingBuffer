//
//  Logger.swift
//  CAPlayThrough-macOS
//
//  Created by Vlad Gorlov on 09.02.19.
//  Copyright © 2019 WaveLabs. All rights reserved.
//

import Foundation
import mcFoundationLogging

enum ModuleLogCategory: String, LogCategory {
   case media, core, controller
}

let log = Log<ModuleLogCategory>(subsystem: "ringBuffer")
