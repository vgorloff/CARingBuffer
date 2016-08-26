//
//  AudioUnitUtility.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 24.03.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import AudioUnit

public struct AudioUnitUtility {

	public enum Errors: Error {
		case OSStatusError(OSStatus)
		case UnexpectedDataSize(expected: UInt32, observed: UInt32)
	}

	public static func setProperty<T>(unit: AudioUnit, propertyID: AudioUnitPropertyID, scope: AudioUnitScope,
	                               element: AudioUnitElement, data: UnsafePointer<T>) throws {
		let dataSize = MemoryLayout<T>.size.uint32Value
		let status = AudioUnitSetProperty(unit, propertyID, scope, element, data, dataSize)
		if status != noErr {
			throw Errors.OSStatusError(status)
		}
	}

	public static func getPropertyInfo(unit: AudioUnit, propertyID: AudioUnitPropertyID, scope: AudioUnitScope,
	                                   element: AudioUnitElement) throws -> (dataSize: UInt32, isWritable: Bool) {
		var dataSize: UInt32 = 0
		var isWritable = DarwinBoolean(false)
		let status = AudioUnitGetPropertyInfo(unit, propertyID, scope, element, &dataSize, &isWritable)
		if status != noErr {
			throw Errors.OSStatusError(status)
		}
		return (dataSize, isWritable.boolValue)
	}

	public static func getProperty<T>(unit: AudioUnit, propertyID: AudioUnitPropertyID, scope: AudioUnitScope,
	                               element: AudioUnitElement) throws -> T {
		let propertyInfo = try getPropertyInfo(unit: unit, propertyID: propertyID, scope: scope, element: element)
		let expectedDataSize = MemoryLayout<T>.size.uint32Value
		if expectedDataSize != propertyInfo.dataSize {
			throw Errors.UnexpectedDataSize(expected: expectedDataSize, observed: propertyInfo.dataSize)
		}
		var resultValue: T
		do {
			defer {
            data.deallocate(capacity: 1)
			}
         let data = UnsafeMutablePointer<T>.allocate(capacity: 1)
			var dataSize = expectedDataSize
			let status = AudioUnitGetProperty(unit, propertyID, scope, element, data, &dataSize)
			if status != noErr {
				throw Errors.OSStatusError(status)
			}
			if dataSize != expectedDataSize {
				throw Errors.UnexpectedDataSize(expected: expectedDataSize, observed: dataSize)
			}
			resultValue = data.pointee
		}

		return resultValue
	}
}
