//
//  CARBTests.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 12.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import AVFoundation
import XCTest

class CARBSwiftTests: XCTestCase {
   var ringBuffer: CARingBuffer<Float>!
   var writeBuffer: AVAudioPCMBuffer!
   var secondaryWriteBuffer: AVAudioPCMBuffer!
   var readBuffer: AVAudioPCMBuffer!

   override func setUp() {
      super.setUp()
      let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
      writeBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: 16)
      secondaryWriteBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: 16)
      readBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: 16)
      ringBuffer = CARingBuffer<Float>(numberOfChannels: 2, capacityFrames: 5)
   }

   override func tearDown() {
      ringBuffer = nil
      writeBuffer = nil
      readBuffer = nil
      super.tearDown()
   }

   func testIOInRange() {
      CARBTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: 4)
      CARBTestsUtility.printChannelData(title: "Write buffer:", buffer: writeBuffer)
      var status = CARingBufferError.noError

      status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: 4, startWrite: 0)
      XCTAssertTrue(status == .noError)

      var startTime: SampleTime = 0
      var endTime: SampleTime = 0
      status = ringBuffer.getTimeBounds(startTime: &startTime, endTime: &endTime)
      XCTAssertTrue(status == .noError)
      XCTAssertTrue(startTime == 0 && endTime == 4)

      readBuffer.frameLength = 2
      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 2, startRead: 0)
      XCTAssertTrue(status == .noError)
      CARBTestsUtility.printChannelData(title: "Read buffer (1 part):", buffer: readBuffer)
      XCTAssertTrue(CARBTestsUtility.compareBuffersContents(writeBuffer, writeBufferOffset: 0, readBuffer: readBuffer,
                                                            readBufferOffset: 0, numberOfFrames: 2))
      status = ringBuffer.getTimeBounds(startTime: &startTime, endTime: &endTime)
      XCTAssertTrue(status == .noError)
      XCTAssertTrue(startTime == 0 && endTime == 4)

      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 2, startRead: 2)
      XCTAssertTrue(status == .noError)
      CARBTestsUtility.printChannelData(title: "Read buffer (2 part):", buffer: readBuffer)
      XCTAssertTrue(CARBTestsUtility.compareBuffersContents(writeBuffer, writeBufferOffset: 2, readBuffer: readBuffer,
                                                            readBufferOffset: 0, numberOfFrames: 2))
      status = ringBuffer.getTimeBounds(startTime: &startTime, endTime: &endTime)
      XCTAssertTrue(status == .noError)
      XCTAssertTrue(startTime == 0 && endTime == 4)
   }

   func testReadBehindAndAhead() {
      CARBTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: 4)
      CARBTestsUtility.printChannelData(title: "Write buffer:", buffer: writeBuffer)
      var status = CARingBufferError.noError

      status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: 4, startWrite: 2)
      XCTAssertTrue(status == .noError)

      var startTime: SampleTime = 0
      var endTime: SampleTime = 0
      status = ringBuffer.getTimeBounds(startTime: &startTime, endTime: &endTime)
      XCTAssertTrue(status == .noError)
      XCTAssertTrue(startTime == 0 && endTime == 6)

      readBuffer.frameLength = 4
      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 4, startRead: 0)
      XCTAssertTrue(status == .noError)
      CARBTestsUtility.printChannelData(title: "Read buffer (1 part):", buffer: readBuffer)
      XCTAssertTrue(CARBTestsUtility.compareBuffersContents(writeBuffer, writeBufferOffset: 0, readBuffer: readBuffer,
                                                            readBufferOffset: 2, numberOfFrames: 2))
      XCTAssertTrue(CARBTestsUtility.checkBuffersContentsIsZero(readBuffer, bufferOffset: 0, numberOfFrames: 2))

      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 4, startRead: 4)
      XCTAssertTrue(status == .noError)
      CARBTestsUtility.printChannelData(title: "Read buffer (2 part):", buffer: readBuffer)
      XCTAssertTrue(CARBTestsUtility.compareBuffersContents(writeBuffer, writeBufferOffset: 2, readBuffer: readBuffer,
                                                            readBufferOffset: 0, numberOfFrames: 2))
      XCTAssertTrue(CARBTestsUtility.checkBuffersContentsIsZero(readBuffer, bufferOffset: 2, numberOfFrames: 2))
   }

   func testWriteBehindAndAhead() {
      CARBTestsUtility.generateSampleChannelData(secondaryWriteBuffer, numberOfFrames: 8, biasValue: 2)
      CARBTestsUtility.printChannelData(title: "Secondary write buffer:", buffer: secondaryWriteBuffer)
      var status = CARingBufferError.noError

      status = ringBuffer.store(secondaryWriteBuffer.audioBufferList, framesToWrite: 8, startWrite: 0)
      XCTAssertTrue(status == .noError)

      var startTime: SampleTime = 0
      var endTime: SampleTime = 0
      status = ringBuffer.getTimeBounds(startTime: &startTime, endTime: &endTime)
      XCTAssertTrue(status == .noError)
      XCTAssertTrue(startTime == 0 && endTime == 8)

      CARBTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: 4)
      CARBTestsUtility.printChannelData(title: "Write buffer:", buffer: writeBuffer)
      status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: 4, startWrite: 2)
      XCTAssertTrue(status == .noError)
      status = ringBuffer.getTimeBounds(startTime: &startTime, endTime: &endTime)
      XCTAssertTrue(status == .noError)
      XCTAssertTrue(startTime == 2 && endTime == 6)

      readBuffer.frameLength = 8
      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 8, startRead: 0)
      XCTAssertTrue(status == .noError)
      CARBTestsUtility.printChannelData(title: "Read buffer:", buffer: readBuffer)
      XCTAssertTrue(CARBTestsUtility.compareBuffersContents(writeBuffer, writeBufferOffset: 0, readBuffer: readBuffer,
                                                            readBufferOffset: 2, numberOfFrames: 4))
      XCTAssertTrue(CARBTestsUtility.checkBuffersContentsIsZero(readBuffer, bufferOffset: 0, numberOfFrames: 2))
      XCTAssertTrue(CARBTestsUtility.checkBuffersContentsIsZero(readBuffer, bufferOffset: 6, numberOfFrames: 2))
   }

   func testReadFromEmptyBuffer() {
      var status = CARingBufferError.noError

      var startTime: SampleTime = 0
      var endTime: SampleTime = 0
      status = ringBuffer.getTimeBounds(startTime: &startTime, endTime: &endTime)
      XCTAssertTrue(status == .noError)
      XCTAssertTrue(startTime == 0 && endTime == 0)

      readBuffer.frameLength = 4
      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 4, startRead: 0)
      XCTAssertTrue(status == .noError)
      CARBTestsUtility.printChannelData(title: "Read buffer:", buffer: readBuffer)
      XCTAssertTrue(CARBTestsUtility.checkBuffersContentsIsZero(readBuffer, bufferOffset: 0, numberOfFrames: 4))
   }

   func testIOWithWrapping() {
      CARBTestsUtility.generateSampleChannelData(secondaryWriteBuffer, numberOfFrames: 4, biasValue: 2)
      CARBTestsUtility.printChannelData(title: "Secondary write buffer:", buffer: secondaryWriteBuffer)
      var status = CARingBufferError.noError

      status = ringBuffer.store(secondaryWriteBuffer.audioBufferList, framesToWrite: 4, startWrite: 0)
      XCTAssertTrue(status == .noError)

      CARBTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: 6)
      CARBTestsUtility.printChannelData(title: "Write buffer:", buffer: writeBuffer)

      status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: 6, startWrite: 4)
      XCTAssertTrue(status == .noError)

      var startTime: SampleTime = 0
      var endTime: SampleTime = 0
      status = ringBuffer.getTimeBounds(startTime: &startTime, endTime: &endTime)
      XCTAssertTrue(status == .noError)
      XCTAssertTrue(startTime == 2 && endTime == 10)

      readBuffer.frameLength = 10
      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 10, startRead: 0)
      XCTAssertTrue(status == .noError)
      CARBTestsUtility.printChannelData(title: "Read buffer:", buffer: readBuffer)
      XCTAssertTrue(CARBTestsUtility.checkBuffersContentsIsZero(readBuffer, bufferOffset: 0, numberOfFrames: 2))
      XCTAssertTrue(CARBTestsUtility.compareBuffersContents(secondaryWriteBuffer, writeBufferOffset: 2,
                                                            readBuffer: readBuffer, readBufferOffset: 2, numberOfFrames: 2))
      XCTAssertTrue(CARBTestsUtility.compareBuffersContents(writeBuffer, writeBufferOffset: 0, readBuffer: readBuffer,
                                                            readBufferOffset: 4, numberOfFrames: 6))
   }

   func testIOEdgeCases() {
      var status = CARingBufferError.noError

      status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: 0, startWrite: 0)
      XCTAssertTrue(status == .noError)

      status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: 512, startWrite: 0)
      XCTAssertTrue(status == .tooMuch)

      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 0, startRead: 0)
      XCTAssertTrue(status == .noError)
   }
}
