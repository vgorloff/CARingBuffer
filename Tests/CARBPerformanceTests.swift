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
		let numberOfChannels: UInt32 = 2
		let IOCapacity: UInt32 = 512
		let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: numberOfChannels)
		let writeBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: IOCapacity)
		let readBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: IOCapacity)
		let ringBuffer = CARingBuffer<Float>(numberOfChannels: numberOfChannels, capacityFrames: 4096)
		CARBTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: IOCapacity)
		self.measureBlock {
			var status: CARingBufferError
			for iteration in 0 ..< UInt32(2_000_000) {
				status = ringBuffer.Store(writeBuffer.audioBufferList, framesToWrite: IOCapacity,
					startWrite:  SampleTime(IOCapacity * iteration))
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
