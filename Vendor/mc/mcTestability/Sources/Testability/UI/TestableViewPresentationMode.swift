//
//  TestableViewPresentationMode.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 20.02.19.
//  Copyright © 2018 Vlad Gorlov. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

public enum TestableViewPresentationMode {
   #if !os(macOS)
   public typealias EdgeInsets = UIEdgeInsets
   #else
   public typealias EdgeInsets = NSEdgeInsets
   #endif

   case margins(EdgeInsets)
   case asIs

   case fullScreen, fullWidth, fullHeight
   #if !os(macOS)
   case fullHeightInsideSafeAreas, fullWidthInsideSafeAreas, fullScreenInsideSafeAreas
   #endif

   case fullWidthWithHeight(CGFloat)
   case fullHeightWithWidth(CGFloat)

   case atCenter
   case atCenterWithHeight(CGFloat)
   case atCenterWithWidth(CGFloat)
   case atCenterWithSize(CGSize)
}
