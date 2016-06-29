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

   func performMeasure(numberOfIterations: UInt32) {
      let numberOfChannels = CARBTestParameters.NumberOfChannels.rawValue
      let IOCapacity = CARBTestParameters.IOCapacity.rawValue
      let audioFormat = AVAudioFormat(standardFormatWithSampleRate: Double(CARBTestParameters.SampleRate.rawValue),
                                      channels: numberOfChannels)
      let writeBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: IOCapacity)
      let readBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: IOCapacity)
      let ringBuffer = CARingBuffer<Float>(numberOfChannels: numberOfChannels,
                                           capacityFrames: CARBTestParameters.BufferCapacityFrames.rawValue)
      CARBTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: IOCapacity)
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

	func testPerformanceShort() {
		performMeasure(CARBTestParameters.NumberOfIterationsShort.rawValue)
	}

   func testPerformanceMedium() {
      performMeasure(CARBTestParameters.NumberOfIterationsMedium.rawValue)
   }

   func testPerformanceLong() {
      performMeasure(CARBTestParameters.NumberOfIterationsLong.rawValue)
   }
}
