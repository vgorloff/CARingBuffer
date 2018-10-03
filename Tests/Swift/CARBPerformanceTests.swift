//
//  CARBPerformanceTests.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 12.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import AVFoundation
import XCTest

class CARBSwiftPerformanceTests: XCTestCase {

   func performMeasure(_ numberOfIterations: UInt32) {
      let numberOfChannels = RingBufferTestParameters.numberOfChannels.rawValue
      let IOCapacity = RingBufferTestParameters.ioCapacity.rawValue
      let audioFormat = AVAudioFormat(standardFormatWithSampleRate: Double(RingBufferTestParameters.sampleRate.rawValue),
                                      channels: numberOfChannels)!
      let writeBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: IOCapacity)!
      let readBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: IOCapacity)!
      let ringBuffer = RingBuffer<Float>(numberOfChannels: Int(numberOfChannels),
                                         capacityFrames: Int(RingBufferTestParameters.bufferCapacityFrames.rawValue))
      RingBufferTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: IOCapacity)
      measure {
         var status: RingBufferError
         for iteration in 0 ..< numberOfIterations {
            status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: Int64(IOCapacity),
                                      startWrite: Int64(IOCapacity * iteration))
            if status != .noError {
               fatalError()
            }

            status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: Int64(IOCapacity),
                                      startRead: Int64(IOCapacity * iteration))
            if status != .noError {
               fatalError()
            }
         }
      }
   }

   func testPerformanceShort() {
      performMeasure(RingBufferTestParameters.numberOfIterationsShort.rawValue)
   }

   func testPerformanceMedium() {
      performMeasure(RingBufferTestParameters.numberOfIterationsMedium.rawValue)
   }

   func testPerformanceLong() {
      performMeasure(RingBufferTestParameters.numberOfIterationsLong.rawValue)
   }
}
