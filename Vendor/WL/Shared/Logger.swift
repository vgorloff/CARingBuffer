//
//  Logger.swift
//  mcDB
//
//  Created by Vlad Gorlov on 30.04.18.
//  Copyright © 2018 Demo. All rights reserved.
//

import Foundation

public enum AppLogCategory: String, LogCategory {
   case service, helper, db, net, view, core, media, processing, io, test, app, controller, animation, events
}

public let log = Log<AppLogCategory>(subsystem: "wl")
