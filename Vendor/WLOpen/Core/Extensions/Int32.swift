//
//  Int32.swift
//  WLCore
//
//  Created by Vlad Gorlov on 23.03.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

extension Int32: UInt32Representable {
	public var uint32Value: UInt32 {
		return UInt32(self)
	}
}
