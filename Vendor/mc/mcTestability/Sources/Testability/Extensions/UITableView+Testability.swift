//
//  UITableView+Testability.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 09.10.18.
//  Copyright © 2018 Vlad Gorlov. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit

extension UITableView {

   func tap(row: Int, section: Int = 0, file: StaticString = #file, line: UInt = #line) {
      TestSettings.shared.assert.notNil(delegate, nil, file: file, line: line)
      delegate?.tableView?(self, didSelectRowAt: IndexPath(row: row, section: section))
   }
}
#endif
