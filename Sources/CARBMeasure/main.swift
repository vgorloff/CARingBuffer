//
//  main.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 14.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import AVFoundation
import mcMedia

print("Note: This app intended to use with Instruments.app to measure execution time.")
print("Starting iterations...")

typealias SampleTime = RingBufferTimeBounds.SampleTime
let numberOfChannels: Int = 2
let IOCapacity: UInt32 = 512
let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: AVAudioChannelCount(numberOfChannels))!
let writeBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: IOCapacity)!
let readBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: IOCapacity)!
let ringBuffer = RingBuffer<Float>(numberOfBuffers: numberOfChannels, numberOfElements: 4096)

RingBufferTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: IOCapacity)
var status: RingBufferError
for iteration in 0 ..< UInt32(10_000_000) {
   status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: SampleTime(IOCapacity),
                             startWrite: SampleTime(IOCapacity) * SampleTime(iteration))
   assert(status == .noError)

   status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: SampleTime(IOCapacity),
                             startRead: SampleTime(IOCapacity) * SampleTime(iteration))
   assert(status == .noError)
}

print("Done!")
