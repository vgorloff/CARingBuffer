//
//  XCTAttachment.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 22.10.17.
//  Copyright © 2017 Vlad Gorlov. All rights reserved.
//

import Foundation
#if canImport(XCTest)
import XCTest

// See also: https://medium.com/xcblog/hands-on-xcuitest-features-with-xcode-9-eb4d00be2781
extension XCTAttachment {

   static func screenshot() -> XCTAttachment {
      let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot(), quality: .medium)
      attachment.lifetime = .keepAlways
      return attachment
   }
}
#endif
