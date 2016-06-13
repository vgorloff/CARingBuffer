//
//  CASwiftRingBufferTests.swift
//  CARingBufferTests
//
//  Created by Vlad Gorlov on 12.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import XCTest
import AVFoundation

private func generateSampleChannelData(buffer: AVAudioPCMBuffer, numberOfFrames: Int, biasValue: UInt32 = 1) {
	let ablPointer = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
	for bufferIndex in 0 ..< ablPointer.count {
		for frameIndex in 0 ..< numberOfFrames {
			let floatValue: Float = Float(biasValue) + 0.1 * Float(bufferIndex) + 0.01 * Float(frameIndex)
			ablPointer[bufferIndex].mFloatData[frameIndex] = floatValue
		}
	}
	buffer.frameLength = UInt32(numberOfFrames)
}

private func printChannelData(title title: String, buffer: AVAudioPCMBuffer) {
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

private func compareBuffersContents(writeBuffer: AVAudioPCMBuffer, writeBufferOffset: UInt32,
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

private func checkBuffersContentsIsZero(buffer: AVAudioPCMBuffer, bufferOffset: UInt32, numberOfFrames: UInt32) -> Bool {
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

class CASwiftRingBufferTests: XCTestCase {
	var ringBuffer: CARingBuffer<Float>!
	var writeBuffer: AVAudioPCMBuffer!
	var secondaryWriteBuffer: AVAudioPCMBuffer!
	var readBuffer: AVAudioPCMBuffer!

	override func setUp() {
		super.setUp()
		let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 441, channels: 2)
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

	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measureBlock {
			// Put the code you want to measure the time of here.
		}
	}

}
