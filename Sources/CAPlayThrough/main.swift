//
//  main.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 11.02.18.
//  Copyright © 2018 WaveLabs. All rights reserved.
//

import Foundation

autoreleasepool {
   // Even if we loading application manually we need to setup `Info.plist` key:
   // <key>NSPrincipalClass</key>
   // <string>NSApplication</string>
   // Otherwise Application will be loaded in `low resolution` mode.
   let app = Application.shared
   app.setActivationPolicy(.regular)
   app.run()
}
