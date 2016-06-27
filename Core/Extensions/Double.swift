//
//  Double.swift
//  WLCore
//
//  Created by Vlad Gorlov on 06.02.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import CoreGraphics

extension Double: CGFloatRepresentable {
	public var CGFloatValue: CGFloat { // swiftlint:disable:this variable_name
		return CGFloat(self)
	}
}

extension Double: FloatRepresentable {
	public var floatValue: Float {
		return Float(self)
	}
}

extension Double: Int64Representable {
	public var int64Value: Int64 {
		return Int64(self)
	}
}