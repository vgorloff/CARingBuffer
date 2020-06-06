//
//  RingBufferTests.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 12.06.16.
//  Copyright © 2016 Vlad Gorlov. All rights reserved.
//

import AVFoundation
@testable import mcMedia
import mcTestability
import XCTest

class RingBufferTests: LogicTestCase {

   typealias SampleTime = RingBufferTimeBounds.SampleTime

   private(set) var ringBuffer: RingBuffer<Float>!
   private(set) var writeBuffer: AVAudioPCMBuffer!
   private(set) var secondaryWriteBuffer: AVAudioPCMBuffer!
   private(set) var readBuffer: AVAudioPCMBuffer!

   override func setUp() {
      super.setUp()
      let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
      writeBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: 16)
      secondaryWriteBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: 16)
      readBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: 16)
      ringBuffer = RingBuffer<Float>(numberOfBuffers: 2, numberOfElements: 8)

      addTeardownBlock { [weak self] in
         self?.ringBuffer = nil
         self?.writeBuffer = nil
         self?.secondaryWriteBuffer = nil
         self?.readBuffer = nil
      }
   }

   func test_IOInRange() {

      RingBufferTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: 4)
      RingBufferTestsUtility.printChannelData(title: "Write buffer:", buffer: writeBuffer)
      var status = RingBufferError.noError

      status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: 4, startWrite: 0)
      Assert.equals(status, .noError)

      verifyTimeBounds(start: 0, end: 4)

      readBuffer.frameLength = 2
      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 2, startRead: 0)
      Assert.true(status == .noError)
      RingBufferTestsUtility.printChannelData(title: "Read buffer (1 part):", buffer: readBuffer)
      Assert.true(RingBufferTestsUtility.compareBuffersContents(writeBuffer, writeBufferOffset: 0, readBuffer: readBuffer,
                                                                readBufferOffset: 0, numberOfFrames: 2))
      verifyTimeBounds(start: 0, end: 4)

      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 2, startRead: 2)
      Assert.true(status == .noError)
      RingBufferTestsUtility.printChannelData(title: "Read buffer (2 part):", buffer: readBuffer)
      Assert.true(RingBufferTestsUtility.compareBuffersContents(writeBuffer, writeBufferOffset: 2, readBuffer: readBuffer,
                                                                readBufferOffset: 0, numberOfFrames: 2))
      verifyTimeBounds(start: 0, end: 4)
   }

   func test_readBehind_and_ahead() {
      RingBufferTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: 4)
      RingBufferTestsUtility.printChannelData(title: "Write buffer:", buffer: writeBuffer)
      var status = RingBufferError.noError

      status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: 4, startWrite: 2)
      Assert.true(status == .noError)

      verifyTimeBounds(start: 0, end: 6)

      readBuffer.frameLength = 4
      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 4, startRead: 0)
      Assert.true(status == .noError)
      RingBufferTestsUtility.printChannelData(title: "Read buffer (1 part):", buffer: readBuffer)
      Assert.true(RingBufferTestsUtility.compareBuffersContents(writeBuffer, writeBufferOffset: 0, readBuffer: readBuffer,
                                                                readBufferOffset: 2, numberOfFrames: 2))
      Assert.true(RingBufferTestsUtility.checkBuffersContentsIsZero(readBuffer, bufferOffset: 0, numberOfFrames: 2))

      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 4, startRead: 4)
      Assert.true(status == .noError)
      RingBufferTestsUtility.printChannelData(title: "Read buffer (2 part):", buffer: readBuffer)
      Assert.true(RingBufferTestsUtility.compareBuffersContents(writeBuffer, writeBufferOffset: 2, readBuffer: readBuffer,
                                                                readBufferOffset: 0, numberOfFrames: 2))
      Assert.true(RingBufferTestsUtility.checkBuffersContentsIsZero(readBuffer, bufferOffset: 2, numberOfFrames: 2))
   }

   func test_writeBehind_and_ahead() {

      RingBufferTestsUtility.generateSampleChannelData(secondaryWriteBuffer, numberOfFrames: 8, biasValue: 2)
      RingBufferTestsUtility.printChannelData(title: "Secondary write buffer:", buffer: secondaryWriteBuffer)
      var status = RingBufferError.noError

      status = ringBuffer.store(secondaryWriteBuffer.audioBufferList, framesToWrite: 8, startWrite: 0)
      Assert.equals(status, .noError)

      verifyTimeBounds(start: 0, end: 8)

      RingBufferTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: 4)
      RingBufferTestsUtility.printChannelData(title: "Write buffer:", buffer: writeBuffer)
      status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: 4, startWrite: 2)
      Assert.equals(status, .noError)

      verifyTimeBounds(start: 2, end: 6)

      readBuffer.frameLength = 8
      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 8, startRead: 0)
      Assert.equals(status, .noError)
      RingBufferTestsUtility.printChannelData(title: "Read buffer:", buffer: readBuffer)
      Assert.true(RingBufferTestsUtility.compareBuffersContents(writeBuffer, writeBufferOffset: 0, readBuffer: readBuffer,
                                                                readBufferOffset: 2, numberOfFrames: 4))
      Assert.true(RingBufferTestsUtility.checkBuffersContentsIsZero(readBuffer, bufferOffset: 0, numberOfFrames: 2))
      Assert.true(RingBufferTestsUtility.checkBuffersContentsIsZero(readBuffer, bufferOffset: 6, numberOfFrames: 2))
   }

   func test_readFromEmptyBuffer() {
      var status = RingBufferError.noError

      verifyTimeBounds(start: 0, end: 0)

      readBuffer.frameLength = 4
      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 4, startRead: 0)
      Assert.true(status == .noError)
      RingBufferTestsUtility.printChannelData(title: "Read buffer:", buffer: readBuffer)
      Assert.true(RingBufferTestsUtility.checkBuffersContentsIsZero(readBuffer, bufferOffset: 0, numberOfFrames: 4))
   }

   func test_IO_withWrapping() {
      RingBufferTestsUtility.generateSampleChannelData(secondaryWriteBuffer, numberOfFrames: 4, biasValue: 2)
      RingBufferTestsUtility.printChannelData(title: "Secondary write buffer:", buffer: secondaryWriteBuffer)
      var status = RingBufferError.noError

      status = ringBuffer.store(secondaryWriteBuffer.audioBufferList, framesToWrite: 4, startWrite: 0)
      Assert.true(status == .noError)

      RingBufferTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: 6)
      RingBufferTestsUtility.printChannelData(title: "Write buffer:", buffer: writeBuffer)

      status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: 6, startWrite: 4)
      Assert.true(status == .noError)

      verifyTimeBounds(start: 2, end: 10)

      readBuffer.frameLength = 10
      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 10, startRead: 0)
      Assert.true(status == .noError)
      RingBufferTestsUtility.printChannelData(title: "Read buffer:", buffer: readBuffer)
      Assert.true(RingBufferTestsUtility.checkBuffersContentsIsZero(readBuffer, bufferOffset: 0, numberOfFrames: 2))
      Assert.true(RingBufferTestsUtility.compareBuffersContents(secondaryWriteBuffer, writeBufferOffset: 2,
                                                                readBuffer: readBuffer, readBufferOffset: 2, numberOfFrames: 2))
      Assert.true(RingBufferTestsUtility.compareBuffersContents(writeBuffer, writeBufferOffset: 0, readBuffer: readBuffer,
                                                                readBufferOffset: 4, numberOfFrames: 6))
   }

   func test_IO_edgeCases() {
      var status = RingBufferError.noError

      status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: 0, startWrite: 0)
      Assert.equals(status, .noError)

      status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: 512, startWrite: 0)
      Assert.equals(status, .tooMuch)

      status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: 0, startRead: 0)
      Assert.equals(status, .noError)
   }
}

extension RingBufferTests {

   func verifyTimeBounds(start: SampleTime, end: SampleTime, file: StaticString = #file, line: UInt = #line) {
      switch ringBuffer.offsets.timeBounds.get() {
      case .failure:
         Assert.fail("Unexpected result", file: file, line: line)
      case .success(let start, let end):
         Assert.equals(start, start, file: file, line: line)
         Assert.equals(end, end, file: file, line: line)
      }
   }
}
