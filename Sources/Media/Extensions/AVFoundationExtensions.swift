//
//  AVFoundationExtensions.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 29.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import AVFoundation

extension AudioBuffer {
	var mFloatData: UnsafeMutablePointer<Float> {
		return UnsafeMutablePointer<Float>(mData)
	}
	var mFloatBuffer: UnsafeMutableBufferPointer<Float> {
		return UnsafeMutableBufferPointer<Float>(start: mFloatData, count: Int(mDataByteSize) / sizeof(Float))
	}
	var mFloatArray: [Float] {
		return Array<Float>(mFloatBuffer)
	}
	func fillWithZeros() {
		memset(mData, 0, Int(mDataByteSize))
	}
}

public extension AudioComponentDescription {
	public init(type: OSType, subType: OSType, manufacturer: OSType = kAudioUnitManufacturer_Apple,
	            flags: UInt32 = 0, flagsMask: UInt32 = 0) {
		self.init(componentType: type, componentSubType: subType, componentManufacturer: manufacturer,
		          componentFlags: flags, componentFlagsMask: flagsMask)
	}
}

extension UnsafeMutableAudioBufferListPointer {
	var audioBuffers: [AudioBuffer] {
		var result = [AudioBuffer]()
		for audioBufferIndex in 0..<count {
			result.append(self[audioBufferIndex])
		}
		return result
	}
	init(unsafePointer pointer: UnsafePointer<AudioBufferList>) {
		self.init(UnsafeMutablePointer<AudioBufferList>(pointer))
	}
}