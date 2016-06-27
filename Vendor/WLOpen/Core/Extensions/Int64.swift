//
//  Int64.swift
//  CARingBuffer
//
//  Created by Vlad Gorlov on 27.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

extension Int64: DoubleRepresentable {
	public var doubleValue: Double {
		return Double(self)
	}
}
