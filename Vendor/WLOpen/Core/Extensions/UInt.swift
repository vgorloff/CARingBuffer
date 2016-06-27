//
//  UInt.swift
//  WLCore
//
//  Created by Vlad Gorlov on 19.03.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

extension UInt: IntRepresentable {
	public var intValue: Int {
		return Int(self)
	}
}

extension UInt: UInt32Representable {
	public var uint32Value: UInt32 {
		return UInt32(self)
	}
}
