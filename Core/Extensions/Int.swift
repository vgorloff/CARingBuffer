//
//  Int.swift
//  WLCore
//
//  Created by Vlad Gorlov on 06.02.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import CoreGraphics

extension Int: UInt32Representable {
	public var uint32Value: UInt32 {
		return UInt32(self)
	}
}

extension Int: CGFloatRepresentable {
	public var CGFloatValue: CGFloat { // swiftlint:disable:this variable_name
		return CGFloat(self)
	}
}
