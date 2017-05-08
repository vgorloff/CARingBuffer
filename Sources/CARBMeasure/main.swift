//
//  main.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 14.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import AVFoundation

print("Note: This app intended to use with Instruments.app to measure execution time.")
print("Starting iterations...")

let numberOfChannels: UInt32 = 2
let IOCapacity: UInt32 = 512
let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: numberOfChannels)
let writeBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: IOCapacity)
let readBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: IOCapacity)
let ringBuffer = CARingBuffer<Float>(numberOfChannels: numberOfChannels, capacityFrames: 4096)

CARBTestsUtility.generateSampleChannelData(writeBuffer, numberOfFrames: IOCapacity)
var status: CARingBufferError
for iteration in 0 ..< UInt32(50_000_000) {
	status = ringBuffer.store(writeBuffer.audioBufferList, framesToWrite: IOCapacity,
	                          startWrite:  SampleTime(IOCapacity * iteration))
	assert(status == .noError)

	status = ringBuffer.fetch(readBuffer.mutableAudioBufferList, framesToRead: IOCapacity,
	                          startRead: SampleTime(IOCapacity * iteration))
	assert(status == .noError)
}
print("Done!")
