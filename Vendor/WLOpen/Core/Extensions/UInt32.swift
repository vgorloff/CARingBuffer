//
//  UInt32.swift
//  WLCore
//
//  Created by Vlad Gorlov on 17.03.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

extension UInt32: IntRepresentable {
	public var intValue: Int {
		return Int(self)
	}
}

extension UInt32: Int32Representable {
	public var int32Value: Int32 {
		return Int32(self)
	}
}

extension UInt32: UIntRepresentable {
	public var uintValue: UInt {
		return UInt(self)
	}
}

extension UInt32: DoubleRepresentable {
	public var doubleValue: Double {
		return Double(self)
	}
}
