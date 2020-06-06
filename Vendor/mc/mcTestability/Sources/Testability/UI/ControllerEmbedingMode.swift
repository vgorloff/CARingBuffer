//
//  ControllerEmbedingMode.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 17.04.20.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

import CoreGraphics
import Foundation

public enum ControllerEmbedingMode {
   case autoresize
   case fullWidthWithHeight(CGFloat)
   case fullScreen, fullScreenInsideSafeAreas
}
