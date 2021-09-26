//
//  UICollectionView+Testability.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 06.06.2020.
//  Copyright © 2020 Vlad Gorlov. All rights reserved.
//

#if !os(macOS)
import Foundation
import UIKit

extension UICollectionView {

   func tap(item: Int, section: Int = 0, file: StaticString = #file, line: UInt = #line) {
      TestSettings.shared.assert.notNil(delegate, nil, file: file, line: line)
      delegate?.collectionView?(self, didSelectItemAt: IndexPath(item: item, section: section))
   }
}
#endif
