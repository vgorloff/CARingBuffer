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

   func performMeasure(_ numberOfIterations: UInt32) {
      let numberOfChannels = CARBTestParameters.numberOfChannels.rawValue
      let IOCapacity = CARBTestParameters.ioCapacity.rawValue
      let audioFormat = AVAudioFormat(standardFormatWithSampleRate: Double(CARBTestParameters.sampleRate.rawValue),
                                      channels: numberOfChannels)!
      let writeBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: IOCapacity)!
      let readBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: IOCapacity)!
      let ringBuffer = CARingBuffer<Float>(numberOfChannels: numberOfChannels,
                                           capacityFrames: CARBTestParameters.bufferCapacityFrames.rawValue)
      CARBTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: IOCapacity)
      self.measure {
         var status: CARingBufferError
         for iteration in 0 ..< numberOfIterations {
            status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: IOCapacity,
               startWrite: SampleTime(IOCapacity * iteration))
            if status != .noError {
               fatalError()
            }

            status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: IOCapacity,
               startRead: SampleTime(IOCapacity * iteration))
            if status != .noError {
               fatalError()
            }
         }
      }
   }

   func testPerformanceShort() {
      performMeasure(CARBTestParameters.numberOfIterationsShort.rawValue)
   }

   func testPerformanceMedium() {
      performMeasure(CARBTestParameters.numberOfIterationsMedium.rawValue)
   }

   func testPerformanceLong() {
      performMeasure(CARBTestParameters.numberOfIterationsLong.rawValue)
   }
}
