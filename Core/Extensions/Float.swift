//
//  Float.swift
//  CARingBuffer
//
//  Created by Vlad Gorlov on 27.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import CoreGraphics

extension Float: CGFloatRepresentable {
	public var CGFloatValue: CGFloat { // swiftlint:disable:this variable_name
		return CGFloat(self)
	}
}
