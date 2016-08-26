//
//  AudioObjectUtility.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 24.03.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import CoreAudio

public struct AudioObjectUtility {

	public enum Errors: Error {
		case OSStatusError(OSStatus)
		case UnexpectedDataSize(expected: UInt32, observed: UInt32)
	}

	public static func getPropertyDataSize(objectID: AudioObjectID, address: AudioObjectPropertyAddress,
	                                        qualifierDataSize: UInt32 = 0,
	                                        qualifierData: UnsafeRawPointer? = nil) throws -> UInt32 {
		var propertyDataSize = UInt32(0)
		var addressValue = address
		let status = AudioObjectGetPropertyDataSize(objectID, &addressValue, qualifierDataSize, qualifierData, &propertyDataSize)
		if status != kAudioHardwareNoError {
			throw Errors.OSStatusError(status)
		}
		return propertyDataSize
	}

	public static func getPropertyData<T>(objectID: AudioObjectID, address: AudioObjectPropertyAddress,
	                                   qualifierDataSize: UInt32 = 0,
	                                   qualifierData: UnsafeRawPointer? = nil) throws -> T {
		let propertyDataSize = try getPropertyDataSize(objectID: objectID, address: address, qualifierDataSize: qualifierDataSize,
		                                           qualifierData: qualifierData)
		let expectedDataSize = MemoryLayout<T>.size.uint32Value
		if propertyDataSize != expectedDataSize {
			throw Errors.UnexpectedDataSize(expected: expectedDataSize, observed: propertyDataSize)
		}
		var resultValue: T
		do {
			defer {
            data.deallocate(capacity: 1)
			}
			var dataSize = expectedDataSize
			var addressValue = address
         let data = UnsafeMutablePointer<T>.allocate(capacity: 1)
			let status = AudioObjectGetPropertyData(objectID, &addressValue, qualifierDataSize, qualifierData, &dataSize, data)
			if status != kAudioHardwareNoError {
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
