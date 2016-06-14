//
//  main.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 14.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import AVFoundation

print("Starting")

let numberOfChannels: UInt32 = 2
let IOCapacity: UInt32 = 512
let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: numberOfChannels)
let writeBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: IOCapacity)
let readBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: IOCapacity)
let ringBuffer = CARingBuffer<Float>(numberOfChannels: numberOfChannels, capacityFrames: 4096)

generateSampleChannelData(writeBuffer, numberOfFrames: IOCapacity)
var status: CARingBufferError
for iteration in 0 ..< UInt32(50_000_000) {
	status = ringBuffer.Store(writeBuffer.audioBufferList, framesToWrite: IOCapacity,
	                          startWrite:  SampleTime(IOCapacity * iteration))
	assert(status == .NoError)

	status = ringBuffer.Fetch(readBuffer.mutableAudioBufferList, nFrames: IOCapacity,
	                          startRead: SampleTime(IOCapacity * iteration))
	assert(status == .NoError)
}
print("Done")
