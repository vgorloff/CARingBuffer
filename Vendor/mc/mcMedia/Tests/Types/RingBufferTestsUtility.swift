//
//  RingBufferTestsUtility.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 14.06.16.
//  Copyright © 2016 Vlad Gorlov. All rights reserved.
//

import AVFoundation
import CoreAudio
import mcMediaExtensions

@objc public enum RingBufferTestParameters: UInt32 {
   case numberOfIterationsShort = 2_000_000
   case numberOfIterationsMedium = 10_000_000
   case numberOfIterationsLong = 50_000_000
   case sampleRate = 44100
   case numberOfChannels = 2
   case bufferCapacityFrames = 4096
   case ioCapacity = 512
}

@objc public final class RingBufferTestsUtility: NSObject {

   @objc public static func generateSampleChannelData(_ buffer: AVAudioPCMBuffer, numberOfFrames: UInt32, biasValue: UInt32 = 1) {
      let ablPointer = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
      for bufferIndex in 0 ..< ablPointer.count {
         for frameIndex in 0 ..< numberOfFrames {
            let floatValue: Float = Float(biasValue) + 0.1 * Float(bufferIndex) + 0.01 * Float(frameIndex)
            ablPointer[bufferIndex].mFloatData?[Int(frameIndex)] = floatValue
         }
      }
      buffer.frameLength = UInt32(numberOfFrames)
   }

   @objc public static func printChannelData(title: String, buffer: AVAudioPCMBuffer) {
      print(title)
      let ablPointer = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
      for frameIndex in 0 ..< buffer.frameLength {
         for bufferIndex in 0 ..< ablPointer.count {
            let sampleValue = ablPointer[bufferIndex].mFloatData?[Int(frameIndex)]
            print(String(format: "%6.3f ", sampleValue!), terminator: "")
         }
         print()
      }
   }

   @objc public static func compareBuffersContents(_ writeBuffer: AVAudioPCMBuffer, writeBufferOffset: UInt32,
                                                   readBuffer: AVAudioPCMBuffer, readBufferOffset: UInt32,
                                                   numberOfFrames: UInt32) -> Bool {
      assert(writeBuffer.frameLength >= writeBufferOffset + numberOfFrames)
      assert(readBuffer.frameLength >= readBufferOffset + numberOfFrames)
      let writeABLPointer = UnsafeMutableAudioBufferListPointer(unsafePointer: writeBuffer.audioBufferList)
      let readABLPointer = UnsafeMutableAudioBufferListPointer(unsafePointer: readBuffer.audioBufferList)
      assert(writeABLPointer.count == readABLPointer.count)

      for numberOfBuffer in 0 ..< writeABLPointer.count {
         for numberOfFrame in 0 ..< numberOfFrames {
            let sampleValueWrite = writeABLPointer[numberOfBuffer].mFloatData?[Int(numberOfFrame + writeBufferOffset)]
            let sampleValueRead = readABLPointer[numberOfBuffer].mFloatData?[Int(numberOfFrame + readBufferOffset)]
            if sampleValueWrite != sampleValueRead {
               return false
            }
         }
      }
      return true
   }

   @objc public static func checkBuffersContentsIsZero(_ buffer: AVAudioPCMBuffer, bufferOffset: UInt32,
                                                       numberOfFrames: UInt32) -> Bool {
      assert(buffer.frameLength >= bufferOffset + numberOfFrames)
      let ablPointer = UnsafeMutableAudioBufferListPointer(unsafePointer: buffer.audioBufferList)
      for numberOfBuffer in 0 ..< ablPointer.count {
         for numberOfFrame in 0 ..< numberOfFrames {
            let sampleValue = ablPointer[numberOfBuffer].mFloatData?[Int(numberOfFrame + bufferOffset)]
            if sampleValue != 0 {
               return false
            }
         }
      }
      return true
   }
}
