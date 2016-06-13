//
//  CASwiftRingBufferTests.swift
//  CARingBufferTests
//
//  Created by Vlad Gorlov on 12.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import XCTest
import AVFoundation

class CASwiftRingBufferTests: XCTestCase {
	var ringBuffer: CARingBuffer<Float>!
	var writeBuffer: AVAudioPCMBuffer!
	var secondaryWriteBuffer: AVAudioPCMBuffer!
	var readBuffer: AVAudioPCMBuffer!

	override func setUp() {
		super.setUp()
		let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
		writeBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: 16)
		secondaryWriteBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: 16)
		readBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: 16)
		ringBuffer = CARingBuffer<Float>(numberOfChannels: 2, capacityFrames: 5)
	}

	override func tearDown() {
		ringBuffer = nil
		writeBuffer = nil
		readBuffer = nil
		super.tearDown()
	}

	func testIOInRange() {
		generateSampleChannelData(writeBuffer, numberOfFrames: 4)
		printChannelData(title: "Write buffer:", buffer: writeBuffer)
		var status = CARingBufferError.NoError

		status = ringBuffer.Store(writeBuffer.audioBufferList, framesToWrite: 4, startWrite: 0)
		XCTAssertTrue(status == .NoError)

		var startTime: SampleTime = 0
		var endTime: SampleTime = 0
		status = ringBuffer.GetTimeBounds(startTime: &startTime, endTime: &endTime)
		XCTAssertTrue(status == .NoError)
		XCTAssertTrue(startTime == 0 && endTime == 4)

		readBuffer.frameLength = 2
		status = ringBuffer.Fetch(readBuffer.mutableAudioBufferList, nFrames: 2, startRead: 0)
		XCTAssertTrue(status == .NoError)
		printChannelData(title: "Read buffer (1 part):", buffer: readBuffer)
		XCTAssertTrue(compareBuffersContents(writeBuffer, writeBufferOffset: 0, readBuffer: readBuffer,
			readBufferOffset: 0, numberOfFrames: 2))
		status = ringBuffer.GetTimeBounds(startTime: &startTime, endTime: &endTime)
		XCTAssertTrue(status == .NoError)
		XCTAssertTrue(startTime == 0 && endTime == 4)

		status = ringBuffer.Fetch(readBuffer.mutableAudioBufferList, nFrames: 2, startRead: 2)
		XCTAssertTrue(status == .NoError)
		printChannelData(title: "Read buffer (2 part):", buffer: readBuffer)
		XCTAssertTrue(compareBuffersContents(writeBuffer, writeBufferOffset: 2, readBuffer: readBuffer,
			readBufferOffset: 0, numberOfFrames: 2))
		status = ringBuffer.GetTimeBounds(startTime: &startTime, endTime: &endTime)
		XCTAssertTrue(status == .NoError)
		XCTAssertTrue(startTime == 0 && endTime == 4)
	}

	func testReadBehindAndAhead() {
		generateSampleChannelData(writeBuffer, numberOfFrames: 4)
		printChannelData(title: "Write buffer:", buffer: writeBuffer)
		var status = CARingBufferError.NoError

		status = ringBuffer.Store(writeBuffer.audioBufferList, framesToWrite: 4, startWrite: 2)
		XCTAssertTrue(status == .NoError)

		var startTime: SampleTime = 0
		var endTime: SampleTime = 0
		status = ringBuffer.GetTimeBounds(startTime: &startTime, endTime: &endTime)
		XCTAssertTrue(status == .NoError)
		XCTAssertTrue(startTime == 0 && endTime == 6)

		readBuffer.frameLength = 4
		status = ringBuffer.Fetch(readBuffer.mutableAudioBufferList, nFrames: 4, startRead: 0)
		XCTAssertTrue(status == .NoError)
		printChannelData(title: "Read buffer (1 part):", buffer: readBuffer)
		XCTAssertTrue(compareBuffersContents(writeBuffer, writeBufferOffset: 0, readBuffer: readBuffer,
			readBufferOffset: 2, numberOfFrames: 2))
		XCTAssertTrue(checkBuffersContentsIsZero(readBuffer, bufferOffset: 0, numberOfFrames: 2))

		status = ringBuffer.Fetch(readBuffer.mutableAudioBufferList, nFrames: 4, startRead: 4)
		XCTAssertTrue(status == .NoError)
		printChannelData(title: "Read buffer (2 part):", buffer: readBuffer)
		XCTAssertTrue(compareBuffersContents(writeBuffer, writeBufferOffset: 2, readBuffer: readBuffer,
			readBufferOffset: 0, numberOfFrames: 2))
		XCTAssertTrue(checkBuffersContentsIsZero(readBuffer, bufferOffset: 2, numberOfFrames: 2))
	}

	func testWriteBehindAndAhead() {
		generateSampleChannelData(secondaryWriteBuffer, numberOfFrames: 8, biasValue: 2)
		printChannelData(title: "Secondary write buffer:", buffer: secondaryWriteBuffer)
		var status = CARingBufferError.NoError

		status = ringBuffer.Store(secondaryWriteBuffer.audioBufferList, framesToWrite: 8, startWrite: 0)
		XCTAssertTrue(status == .NoError)

		var startTime: SampleTime = 0
		var endTime: SampleTime = 0
		status = ringBuffer.GetTimeBounds(startTime: &startTime, endTime: &endTime)
		XCTAssertTrue(status == .NoError)
		XCTAssertTrue(startTime == 0 && endTime == 8)

		generateSampleChannelData(writeBuffer, numberOfFrames: 4)
		printChannelData(title: "Write buffer:", buffer: writeBuffer)
		status = ringBuffer.Store(writeBuffer.audioBufferList, framesToWrite: 4, startWrite: 2)
		XCTAssertTrue(status == .NoError)
		status = ringBuffer.GetTimeBounds(startTime: &startTime, endTime: &endTime)
		XCTAssertTrue(status == .NoError)
		XCTAssertTrue(startTime == 2 && endTime == 6)

		readBuffer.frameLength = 8
		status = ringBuffer.Fetch(readBuffer.mutableAudioBufferList, nFrames: 8, startRead: 0)
		XCTAssertTrue(status == .NoError)
		printChannelData(title: "Read buffer:", buffer: readBuffer)
		XCTAssertTrue(compareBuffersContents(writeBuffer, writeBufferOffset: 0, readBuffer: readBuffer,
			readBufferOffset: 2, numberOfFrames: 4))
		XCTAssertTrue(checkBuffersContentsIsZero(readBuffer, bufferOffset: 0, numberOfFrames: 2))
		XCTAssertTrue(checkBuffersContentsIsZero(readBuffer, bufferOffset: 6, numberOfFrames: 2))
	}

	func testReadFromEmptyBuffer() {
		var status = CARingBufferError.NoError

		var startTime: SampleTime = 0
		var endTime: SampleTime = 0
		status = ringBuffer.GetTimeBounds(startTime: &startTime, endTime: &endTime)
		XCTAssertTrue(status == .NoError)
		XCTAssertTrue(startTime == 0 && endTime == 0)

		readBuffer.frameLength = 4
		status = ringBuffer.Fetch(readBuffer.mutableAudioBufferList, nFrames: 4, startRead: 0)
		XCTAssertTrue(status == .NoError)
		printChannelData(title: "Read buffer:", buffer: readBuffer)
		XCTAssertTrue(checkBuffersContentsIsZero(readBuffer, bufferOffset: 0, numberOfFrames: 4))
	}

	func testIOWithWrapping() {
		generateSampleChannelData(secondaryWriteBuffer, numberOfFrames: 4, biasValue: 2)
		printChannelData(title: "Secondary write buffer:", buffer: secondaryWriteBuffer)
		var status = CARingBufferError.NoError

		status = ringBuffer.Store(secondaryWriteBuffer.audioBufferList, framesToWrite: 4, startWrite: 0)
		XCTAssertTrue(status == .NoError)

		generateSampleChannelData(writeBuffer, numberOfFrames: 6)
		printChannelData(title: "Write buffer:", buffer: writeBuffer)

		status = ringBuffer.Store(writeBuffer.audioBufferList, framesToWrite: 6, startWrite: 4)
		XCTAssertTrue(status == .NoError)

		var startTime: SampleTime = 0
		var endTime: SampleTime = 0
		status = ringBuffer.GetTimeBounds(startTime: &startTime, endTime: &endTime)
		XCTAssertTrue(status == .NoError)
		XCTAssertTrue(startTime == 2 && endTime == 10)

		readBuffer.frameLength = 10
		status = ringBuffer.Fetch(readBuffer.mutableAudioBufferList, nFrames: 10, startRead: 0)
		XCTAssertTrue(status == .NoError)
		printChannelData(title: "Read buffer:", buffer: readBuffer)
		XCTAssertTrue(checkBuffersContentsIsZero(readBuffer, bufferOffset: 0, numberOfFrames: 2))
		XCTAssertTrue(compareBuffersContents(secondaryWriteBuffer, writeBufferOffset: 2, readBuffer: readBuffer,
			readBufferOffset: 2, numberOfFrames: 2))
		XCTAssertTrue(compareBuffersContents(writeBuffer, writeBufferOffset: 0, readBuffer: readBuffer,
			readBufferOffset: 4, numberOfFrames: 6))
	}

	func testIOEdgeCases() {
		var status = CARingBufferError.NoError

		status = ringBuffer.Store(writeBuffer.audioBufferList, framesToWrite: 0, startWrite: 0)
		XCTAssertTrue(status == .NoError)

		status = ringBuffer.Store(writeBuffer.audioBufferList, framesToWrite: 512, startWrite: 0)
		XCTAssertTrue(status == .TooMuch)

		status = ringBuffer.Fetch(readBuffer.mutableAudioBufferList, nFrames: 0, startRead: 0)
		XCTAssertTrue(status == .NoError)
	}

}

class CASwiftRingBufferPerformanceTests: XCTestCase {

	func testPerformanceExample() {
		let numberOfChannels: UInt32 = 2
		let IOCapacity: UInt32 = 512
		let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: numberOfChannels)
		let writeBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: IOCapacity)
		let readBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: IOCapacity)
		let ringBuffer = CARingBuffer<Float>(numberOfChannels: numberOfChannels, capacityFrames: 4096)
		generateSampleChannelData(writeBuffer, numberOfFrames: IOCapacity)
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
