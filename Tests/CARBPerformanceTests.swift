//
//  CARBPerformanceTests.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 12.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import XCTest
import AVFoundation

class CARBSwiftPerformanceTests: XCTestCase {

	func testPerformanceExample() {
		let numberOfChannels = CARBPerformanceTestParameters.NumberOfChannels.rawValue
		let IOCapacity = CARBPerformanceTestParameters.IOCapacity.rawValue
		let audioFormat = AVAudioFormat(standardFormatWithSampleRate: Double(CARBPerformanceTestParameters.SampleRate.rawValue),
		                                channels: numberOfChannels)
		let writeBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: IOCapacity)
		let readBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: IOCapacity)
		let ringBuffer = CARingBuffer<Float>(numberOfChannels: numberOfChannels,
		                                     capacityFrames: CARBPerformanceTestParameters.BufferCapacityFrames.rawValue)
		CARBTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: IOCapacity)
		let numberOfIterations = CARBPerformanceTestParameters.NumberOfIterations.rawValue
		self.measureBlock {
			var status: CARingBufferError
			for iteration in 0 ..< numberOfIterations {
				status = ringBuffer.Store(writeBuffer.audioBufferList, framesToWrite: IOCapacity,
					startWrite: SampleTime(IOCapacity * iteration))
				if status != .NoError {
					fatalError()
				}

				status = ringBuffer.Fetch(readBuffer.mutableAudioBufferList, nFrames: IOCapacity,
					startRead: SampleTime(IOCapacity * iteration))
				if status != .NoError {
					fatalError()
				}
			}
		}
	}
}
