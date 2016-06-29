//
//  AudioObjectUtility.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 24.03.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import CoreAudio

public struct AudioObjectUtility {

	public enum Error: ErrorType {
		case OSStatusError(OSStatus)
		case UnexpectedDataSize(expected: UInt32, observed: UInt32)
	}

	public static func getPropertyDataSize(objectID: AudioObjectID, address: AudioObjectPropertyAddress,
	                                        qualifierDataSize: UInt32 = 0,
	                                        qualifierData: UnsafePointer<Void> = nil) throws -> UInt32 {
		var propertyDataSize = UInt32(0)
		var addressValue = address
		let status = AudioObjectGetPropertyDataSize(objectID, &addressValue, qualifierDataSize, qualifierData, &propertyDataSize)
		if status != kAudioHardwareNoError {
			throw Error.OSStatusError(status)
		}
		return propertyDataSize
	}

	public static func getPropertyData<T>(objectID: AudioObjectID, address: AudioObjectPropertyAddress,
	                                   qualifierDataSize: UInt32 = 0,
	                                   qualifierData: UnsafePointer<Void> = nil) throws -> T {
		let propertyDataSize = try getPropertyDataSize(objectID, address: address, qualifierDataSize: qualifierDataSize,
		                                           qualifierData: qualifierData)
		let expectedDataSize = sizeof(T.self).uint32Value
		if propertyDataSize != expectedDataSize {
			throw Error.UnexpectedDataSize(expected: expectedDataSize, observed: propertyDataSize)
		}
		var resultValue: T
		do {
			defer {
				data.dealloc(1)
			}
			var dataSize = expectedDataSize
			var addressValue = address
			let data = UnsafeMutablePointer<T>.alloc(1)
			let status = AudioObjectGetPropertyData(objectID, &addressValue, qualifierDataSize, qualifierData, &dataSize, data)
			if status != kAudioHardwareNoError {
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
