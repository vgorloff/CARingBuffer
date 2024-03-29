//
//  CARBPerformanceTests.swift
//  WL
//
//  Created by Vlad Gorlov on 12.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import AVFoundation
import XCTest
import mcxMedia

class CARBSwiftPerformanceTests: XCTestCase {

   func performMeasure(_ numberOfIterations: UInt32) {
      let numberOfChannels = RingBufferTestParameters.numberOfChannels.rawValue
      let IOCapacity = RingBufferTestParameters.ioCapacity.rawValue
      let audioFormat = AVAudioFormat(standardFormatWithSampleRate: Double(RingBufferTestParameters.sampleRate.rawValue),
                                      channels: numberOfChannels)!
      let writeBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: IOCapacity)!
      let readBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: IOCapacity)!
      let ringBuffer = RingBuffer<Float>(numberOfBuffers: Int(numberOfChannels),
                                         numberOfElements: Int(RingBufferTestParameters.bufferCapacityFrames.rawValue))
      RingBufferTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: IOCapacity)
      measure {
         var status: RingBufferError
         for iteration in 0 ..< numberOfIterations {
            status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: Int64(IOCapacity),
                                      startWrite: Int64(IOCapacity) * Int64(iteration))
            if status != .noError {
               fatalError()
            }

            status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: Int64(IOCapacity),
                                      startRead: Int64(IOCapacity) * Int64(iteration))
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
