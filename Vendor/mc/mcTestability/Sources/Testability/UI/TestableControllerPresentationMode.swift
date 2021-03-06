//
//  TestableControllerPresentationMode.swift
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

public enum TestableControllerPresentationMode {

   #if os(iOS) || os(tvOS) || os(watchOS)
   public typealias EdgeInsets = UIEdgeInsets
   #elseif os(OSX)
   public typealias EdgeInsets = NSEdgeInsets
   #endif

   case fullScreen, width(CGFloat), margins(EdgeInsets), size(CGSize)
}
