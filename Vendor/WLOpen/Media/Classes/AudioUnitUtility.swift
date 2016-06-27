//
//  AudioUnitUtility.swift
//  WLMedia
//
//  Created by Vlad Gorlov on 24.03.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import AudioUnit

public struct AudioUnitUtility {

	public enum Error: ErrorType {
		case OSStatusError(OSStatus)
		case UnexpectedDataSize(expected: UInt32, observed: UInt32)
	}

	public static func setProperty<T>(unit: AudioUnit, propertyID: AudioUnitPropertyID, scope: AudioUnitScope,
	                               element: AudioUnitElement, data: UnsafePointer<T>) throws {
		let dataSize = sizeof(T.self).uint32Value
		let status = AudioUnitSetProperty(unit, propertyID, scope, element, data, dataSize)
		if status != noErr {
			throw Error.OSStatusError(status)
		}
	}

	public static func getPropertyInfo(unit: AudioUnit, propertyID: AudioUnitPropertyID, scope: AudioUnitScope,
	                                   element: AudioUnitElement) throws -> (dataSize: UInt32, isWritable: Bool) {
		var dataSize: UInt32 = 0
		var isWritable = DarwinBoolean(false)
		let status = AudioUnitGetPropertyInfo(unit, propertyID, scope, element, &dataSize, &isWritable)
		if status != noErr {
			throw Error.OSStatusError(status)
		}
		return (dataSize, isWritable.boolValue)
	}

	public static func getProperty<T>(unit: AudioUnit, propertyID: AudioUnitPropertyID, scope: AudioUnitScope,
	                               element: AudioUnitElement) throws -> T {
		let propertyInfo = try getPropertyInfo(unit, propertyID: propertyID, scope: scope, element: element)
		let expectedDataSize = sizeof(T.self).uint32Value
		if expectedDataSize != propertyInfo.dataSize {
			throw Error.UnexpectedDataSize(expected: expectedDataSize, observed: propertyInfo.dataSize)
		}
		var resultValue: T
		do {
			defer {
				data.dealloc(1)
			}
			let data = UnsafeMutablePointer<T>.alloc(1)
			var dataSize = expectedDataSize
			let status = AudioUnitGetProperty(unit, propertyID, scope, element, data, &dataSize)
			if status != noErr {
				throw Error.OSStatusError(status)
			}
			if dataSize != expectedDataSize {
				throw Error.UnexpectedDataSize(expected: expectedDataSize, observed: dataSize)
			}
			resultValue = data.memory
		}

		return resultValue
	}
}
