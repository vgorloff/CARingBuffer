//
//  UInt64.swift
//  CARingBuffer
//
//  Created by Vlad Gorlov on 27.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

extension UInt64: DoubleRepresentable {
	public var doubleValue: Double {
		return Double(self)
	}
}

extension UInt64: Int64Representable {
	public var int64Value: Int64 {
		return Int64(self)
	}
}