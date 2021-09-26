//
//  Alias.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 26.05.20.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

public enum Alias {
   #if os(macOS)
   public typealias View = NSView
   public typealias Color = NSColor
   #else
   public typealias View = UIView
   public typealias Color = UIColor
   #endif
}
