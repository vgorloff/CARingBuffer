//
//  CARBTestsUtility.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 14.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import AVFoundation

@objc public enum CARBPerformanceTestParameters: UInt32 {
	case NumberOfIterations = 2_000_000
	case SampleRate = 44100
	case NumberOfChannels = 2
	case BufferCapacityFrames = 4096
	case IOCapacity = 512
}

@objc public final class CARBTestsUtility: NSObject {

	public static func generateSampleChannelData(buffer: AVAudioPCMBuffer, numberOfFrames: UInt32, biasValue: UInt32 = 1) {
		let ablPointer = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
		for bufferIndex in 0 ..< ablPointer.count {
			for frameIndex in 0 ..< numberOfFrames {
				let floatValue: Float = Float(biasValue) + 0.1 * Float(bufferIndex) + 0.01 * Float(frameIndex)
				ablPointer[bufferIndex].mFloatData[Int(frameIndex)] = floatValue
			}
		}
		buffer.frameLength = UInt32(numberOfFrames)
	}

	public static func printChannelData(title title: String, buffer: AVAudioPCMBuffer) {
		print(title)
		let ablPointer = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
		for frameIndex in 0 ..< buffer.frameLength {
			for bufferIndex in 0 ..< ablPointer.count {
				let sampleValue = ablPointer[bufferIndex].mFloatData[Int(frameIndex)]
				print(String(format: "%6.3f ", sampleValue), terminator: "")
			}
			print()
		}
	}

	public static func compareBuffersContents(writeBuffer: AVAudioPCMBuffer, writeBufferOffset: UInt32,
	                            readBuffer: AVAudioPCMBuffer, readBufferOffset: UInt32, numberOfFrames: UInt32) -> Bool {
		assert(writeBuffer.frameLength >= writeBufferOffset + numberOfFrames)
		assert(readBuffer.frameLength >= readBufferOffset + numberOfFrames)
		let writeABLPointer = UnsafeMutableAudioBufferListPointer(writeBuffer.audioBufferList)
		let readABLPointer = UnsafeMutableAudioBufferListPointer(readBuffer.audioBufferList)
		assert(writeABLPointer.count == readABLPointer.count)

		for numberOfBuffer in 0..<writeABLPointer.count {
			for numberOfFrame in 0..<numberOfFrames {
				let sampleValueWrite = writeABLPointer[numberOfBuffer].mFloatData[Int(numberOfFrame + writeBufferOffset)]
				let sampleValueRead = readABLPointer[numberOfBuffer].mFloatData[Int(numberOfFrame + readBufferOffset)]
				if sampleValueWrite != sampleValueRead {
					return false
				}
			}
		}
		return true
	}

	public static func checkBuffersContentsIsZero(buffer: AVAudioPCMBuffer, bufferOffset: UInt32, numberOfFrames: UInt32) -> Bool {
		assert(buffer.frameLength >= bufferOffset + numberOfFrames)
		let ablPointer = UnsafeMutableAudioBufferListPointer(buffer.audioBufferList)
		for numberOfBuffer in 0..<ablPointer.count {
			for numberOfFrame in 0..<numberOfFrames {
				let sampleValue = ablPointer[numberOfBuffer].mFloatData[Int(numberOfFrame + bufferOffset)]
				if sampleValue != 0 {
					return false
				}
			}
		}
		return true
	}
}
