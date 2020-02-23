//
//  PlayThroughEngine.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 23.03.16.
//  Copyright © 2016 Vlad Gorloff. All rights reserved.
//

import AVFoundation
import mcMedia
import mcMediaAU
import mcUIReusable

private typealias SampleTime = RingBufferTimeBounds.SampleTime

private let playThroughRenderUtilityInputRenderCallback: AURenderCallback = { inRefCon, ioActionFlags, inTimeStamp,
   inBusNumber, inNumberFrames, _ in
   let sampleTime = inTimeStamp.pointee.mSampleTime
   let renderUtility = unsafeBitCast(inRefCon, to: PlayThroughEngine.self)
   if renderUtility.firstInputTime == nil {
      renderUtility.firstInputTime = sampleTime
   }
   guard let buffer = renderUtility.inputBuffer else {
      return noErr
   }
   buffer.frameLength = inNumberFrames // Not required, but recommended to keep in sync.
   var status = AudioUnitRender(renderUtility.inputUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames,
                                buffer.mutableAudioBufferList)
   if status == noErr {
      if let ringBuffer = renderUtility.ringBuffer {
         if ringBuffer.store(buffer.audioBufferList, framesToWrite: SampleTime(inNumberFrames),
                             startWrite: sampleTime.int64Value) != .noError {
            status = OSStatus(AVError.unknown.rawValue)
         }
      }
   }
   return status
}

private let playThroughRenderUtilityOutputRenderCallback: AURenderCallback = { inRefCon, _, inTimeStamp,
   _, inNumberFrames, ioData in
   let renderUtility = unsafeBitCast(inRefCon, to: PlayThroughEngine.self)
   let audioBuffers = UnsafeMutableAudioBufferListPointer(ioData)?.audioBuffers
   if renderUtility.firstInputTime == nil {
      audioBuffers?.forEach { audioBuffer in audioBuffer.fillWithZeros() }
      return noErr
   }

   var inputTimeStamp = AudioTimeStamp()
   var status = AudioDeviceGetCurrentTime(renderUtility.inputDevice, &inputTimeStamp)
   // this callback may still be called a few times after the device has been stopped
   if status != noErr {
      audioBuffers?.forEach { audioBuffer in audioBuffer.fillWithZeros() }
      return noErr
   }

   var outTimeStamp = AudioTimeStamp()
   status = AudioDeviceGetCurrentTime(renderUtility.outputDevice, &outTimeStamp)
   if status != noErr {
      return status
   }

   // use the varispeed playback rate to offset small discrepancies in sample rate
   let rate = inputTimeStamp.mRateScalar / outTimeStamp.mRateScalar
   status = AudioUnitSetParameter(renderUtility.varispeedUnit, kVarispeedParam_PlaybackRate, kAudioUnitScope_Global, 0,
                                  rate.floatValue, 0)
   if status != noErr {
      return status
   }

   let sampleTime = inTimeStamp.pointee.mSampleTime
   if renderUtility.firstOutputTime == nil {
      renderUtility.firstOutputTime = sampleTime
      let delta = (renderUtility.firstInputTime ?? 0) - (renderUtility.firstOutputTime ?? 0)
      let offset = try? PlayThroughEngine.computeThruOffset(inputDevice: renderUtility.inputDevice,
                                                            outputDevice: renderUtility.outputDevice)
      renderUtility.inToOutSampleOffset = (offset ?? 0).doubleValue
      if delta < 0 {
         renderUtility.inToOutSampleOffset -= delta
      } else {
         renderUtility.inToOutSampleOffset = -delta + renderUtility.inToOutSampleOffset
      }

      audioBuffers?.forEach { audioBuffer in audioBuffer.fillWithZeros() }
      return noErr
   }

   // copy the data from the buffers
   guard let ringBuffer = renderUtility.ringBuffer else {
      return noErr
   }
   guard let ioDataInstance = ioData else {
      return noErr
   }
   let startFetch = sampleTime - renderUtility.inToOutSampleOffset
   let err = ringBuffer.fetch(ioDataInstance, framesToRead: SampleTime(inNumberFrames), startRead: startFetch.int64Value)
   if err != .noError {
      audioBuffers?.forEach { audioBuffer in audioBuffer.fillWithZeros() }
      switch ringBuffer.getTimeBounds() {
      case .failure:
         break // // FIXME: Handle error.
      case .success(let bufferStartTime, let bufferEndTime):
         renderUtility.inToOutSampleOffset = sampleTime - bufferStartTime.doubleValue
      }
   }

   return noErr
}

public final class PlayThroughEngine {

   public enum Errors: Error {
      case OSStatusError(OSStatus)
      case unableToFindComponent(AudioComponentDescription)
      case unexpectedDeviceID(AudioDeviceID)
      case unableToInitialize(String)
   }

   public let inputDevice: AudioDeviceID
   public let outputDevice: AudioDeviceID

   fileprivate var inputUnit: AudioUnit!
   private var varispeedNode: AUNode = 0
   private var outputNode: AUNode = 0
   fileprivate var varispeedUnit: AudioUnit!
   private var outputUnit: AudioUnit!
   private var auGraph: AUGraph!
   fileprivate var inputBuffer: AVAudioPCMBuffer!
   fileprivate var ringBuffer: RingBuffer<Float>!
   fileprivate var inToOutSampleOffset: Double = 0
   fileprivate var firstInputTime: Double?
   fileprivate var firstOutputTime: Double?

   public init(inputDevice anInput: AudioDeviceID, outputDevice anOutput: AudioDeviceID) throws {
      inputDevice = anInput
      outputDevice = anOutput
      // Note: You can interface to input and output devices with "output" audio units.
      // Please keep in mind that you are only allowed to have one output audio unit per graph (AUGraph).
      // As you will see, this sample code splits up the two output units.  The "output" unit that will
      // be used for device input will not be contained in a AUGraph, while the "output" unit that will
      // interface the default output device will be in a graph.
      inputUnit = try setupInputDevice(anInput) // Setup AUHAL for an input device
      auGraph = try setUpAUGraph()
      try setupOutputDevice(anOutput) // Setup Graph containing Varispeed Unit & Default Output Unit
   }

   deinit {
      _ = try? cleanup()
   }
}

extension PlayThroughEngine {

   public func start() throws {
      if try !isRunning() {
         try with(AudioOutputUnitStart(inputUnit))
         try with(AUGraphStart(auGraph))
         firstInputTime = nil
         firstOutputTime = nil
      }
   }

   public func stop() throws {
      if try isRunning() {
         try with(AudioOutputUnitStop(inputUnit))
         try with(AUGraphStop(auGraph))
         firstInputTime = nil
         firstOutputTime = nil
      }
   }

   public func isRunning() throws -> Bool {
      let auhalRunning: UInt32 = try AudioUnitSettings.getProperty(for: inputUnit,
                                                                   propertyID: kAudioOutputUnitProperty_IsRunning,
                                                                   scope: .global, element: 0)
      var graphRunning = DarwinBoolean(false)
      try with(AUGraphIsRunning(auGraph, &graphRunning))
      return (auhalRunning != 0) || graphRunning.boolValue
   }
}

extension PlayThroughEngine {

   private func cleanup() throws {
      try stop()
      try with(AudioUnitUninitialize(inputUnit))
      try with(AUGraphClose(auGraph))
      try with(DisposeAUGraph(auGraph))
      try with(AudioComponentInstanceDispose(inputUnit))
   }

   private func setupInputDevice(_ inputDevice: AudioDeviceID) throws -> AudioUnit {
      try verifyDeviceID(inputDevice)
      var desc = AudioComponentDescription(type: kAudioUnitType_Output, subType: kAudioUnitSubType_HALOutput)
      let comp = AudioComponentFindNext(nil, &desc)
      guard let componentInstance = comp else {
         throw Errors.unableToFindComponent(desc)
      }

      var audioUnitRefeence: AudioUnit?
      try with(AudioComponentInstanceNew(componentInstance, &audioUnitRefeence))
      guard let audioUnit = audioUnitRefeence else {
         throw Errors.unableToInitialize(String(describing: AudioUnit.self))
      }
      try with(AudioUnitInitialize(audioUnit))

      // You must enable the Audio Unit (AUHAL) for input and disable output BEFORE setting the AUHAL's current device.
      var enableIO: UInt32 = 1
      try with(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Input, 1, &enableIO,
                                    MemoryLayout<UInt32>.size.uint32Value)) // "1" means input element

      // Disable Output on the AUHAL
      enableIO = 0
      try with(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Output, 0, &enableIO,
                                    MemoryLayout<UInt32>.size.uint32Value)) // "0" means output element

      // Set the Current Device to the AUHAL. This should be done only after IO has been enabled on the AUHAL.
      var inDevice = inputDevice
      try with(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_CurrentDevice,
                                    kAudioUnitScope_Global, 0, &inDevice, MemoryLayout<AudioDeviceID>.size.uint32Value))

      // Set up input callback

      let context = Unmanaged.passUnretained(self).toOpaque()
      var renderCallbackStruct = AURenderCallbackStruct(inputProc: playThroughRenderUtilityInputRenderCallback,
                                                        inputProcRefCon: context)
      try with(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_SetInputCallback,
                                    kAudioUnitScope_Global, 0, &renderCallbackStruct,
                                    MemoryLayout<AURenderCallbackStruct>.size.uint32Value))

      // Don't setup buffers until you know what the input and output device audio streams look like.
      try with(AudioUnitInitialize(audioUnit)) // TODO: Why this needed?

      return audioUnit
   }

   private func setUpAUGraph() throws -> AUGraph {
      var varispeedDesc = AudioComponentDescription(type: kAudioUnitType_FormatConverter, subType: kAudioUnitSubType_Varispeed)
      var outDesc = AudioComponentDescription(type: kAudioUnitType_Output, subType: kAudioUnitSubType_DefaultOutput)

      var graphReference: AUGraph?
      try with(NewAUGraph(&graphReference))

      guard let graph = graphReference else {
         throw Errors.unableToInitialize(String(describing: AUGraph.self))
      }

      try with(AUGraphOpen(graph)) // Open the Graph, AudioUnits are opened but not initialized

      try with(AUGraphAddNode(graph, &varispeedDesc, &varispeedNode))
      try with(AUGraphAddNode(graph, &outDesc, &outputNode))

      // Get Audio Units from AUGraph nodes
      var varispeedUnitReference: AudioUnit?
      try with(AUGraphNodeInfo(graph, varispeedNode, nil, &varispeedUnitReference))
      varispeedUnit = varispeedUnitReference
      var outputUnitReference: AudioUnit?
      try with(AUGraphNodeInfo(graph, outputNode, nil, &outputUnitReference))
      outputUnit = outputUnitReference

      return graph
   }

   private func setupOutputDevice(_ outputDevice: AudioDeviceID) throws {
      try verifyDeviceID(outputDevice)
      // Set the Current Device to the Default Output Unit.
      try AudioUnitSettings.setProperty(for: outputUnit, propertyID: kAudioOutputUnitProperty_CurrentDevice,
                                        scope: .global, element: 0, data: outputDevice)

      // Tell the output unit not to reset timestamps. Otherwise sample rate changes will cause sync los
      let startAtZero: UInt32 = 0
      try AudioUnitSettings.setProperty(for: outputUnit, propertyID: kAudioOutputUnitProperty_StartTimestampsAtZero,
                                        scope: .global, element: 0, data: startAtZero)
      // Set up output callback
      let context = Unmanaged.passUnretained(self).toOpaque()
      let renderCallbackStruct = AURenderCallbackStruct(inputProc: playThroughRenderUtilityOutputRenderCallback,
                                                        inputProcRefCon: context)
      try AudioUnitSettings.setProperty(for: varispeedUnit, propertyID: kAudioUnitProperty_SetRenderCallback,
                                        scope: .input, element: 0, data: renderCallbackStruct)

      try setupBuffers()

      // the varispeed unit should only be connected after the input and output formats have been set
      try with(AUGraphConnectNodeInput(auGraph, varispeedNode, 0, outputNode, 0))
      try with(AUGraphInitialize(auGraph))
      inToOutSampleOffset = try PlayThroughEngine.computeThruOffset(inputDevice: inputDevice,
                                                                    outputDevice: outputDevice).doubleValue
   }

   private func setupBuffers() throws {
      let bufferSizeFrames: UInt32 =
         try AudioUnitSettings.getProperty(for: inputUnit, propertyID: kAudioDevicePropertyBufferFrameSize,
                                           scope: .global, element: 0)
      let asbd_dev1_in: AudioStreamBasicDescription =
         try AudioUnitSettings.getProperty(for: inputUnit, propertyID: kAudioUnitProperty_StreamFormat,
                                           scope: .input, element: 1)
      var asbd: AudioStreamBasicDescription =
         try AudioUnitSettings.getProperty(for: inputUnit, propertyID: kAudioUnitProperty_StreamFormat,
                                           scope: .output, element: 1)
      let asbd_dev2_out: AudioStreamBasicDescription =
         try AudioUnitSettings.getProperty(for: outputUnit, propertyID: kAudioUnitProperty_StreamFormat,
                                           scope: .output, element: 0)

      // Set the format of all the AUs to the input/output devices channel count
      // For a simple case, you want to set this to the lower of count of the channels
      // in the input device vs output device
      asbd.mChannelsPerFrame = min(asbd_dev1_in.mChannelsPerFrame, asbd_dev2_out.mChannelsPerFrame)

      // We must get the sample rate of the input device and set it to the stream format of AUHAL
      let theAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyNominalSampleRate,
                                                  mScope: kAudioObjectPropertyScopeGlobal,
                                                  mElement: kAudioObjectPropertyElementMaster)
      var rate: Double = try AudioObjectUtility.getPropertyData(objectID: inputDevice, address: theAddress)
      asbd.mSampleRate = rate
      try AudioUnitSettings.setProperty(for: inputUnit, propertyID: kAudioUnitProperty_StreamFormat,
                                        scope: .output, element: 1, data: asbd)
      try AudioUnitSettings.setProperty(for: varispeedUnit, propertyID: kAudioUnitProperty_StreamFormat,
                                        scope: .input, element: 0, data: asbd)

      // Set the correct sample rate for the output device, but keep the channel count the same
      rate = try AudioObjectUtility.getPropertyData(objectID: outputDevice, address: theAddress)
      asbd.mSampleRate = rate
      try AudioUnitSettings.setProperty(for: varispeedUnit, propertyID: kAudioUnitProperty_StreamFormat,
                                        scope: .output, element: 0, data: asbd)
      try AudioUnitSettings.setProperty(for: outputUnit, propertyID: kAudioUnitProperty_StreamFormat,
                                        scope: .input, element: 0, data: asbd)

      let format = AVAudioFormat(streamDescription: &asbd)!
      inputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSizeFrames)

      assert(asbd.mBytesPerFrame.intValue == MemoryLayout<Float>.size)
      ringBuffer = RingBuffer<Float>(numberOfBuffers: Int(asbd.mChannelsPerFrame),
                                     numberOfElements: Int(bufferSizeFrames * 20))
   }

   fileprivate static func computeThruOffset(inputDevice anInputDevice: AudioDeviceID,
                                             outputDevice: AudioDeviceID) throws -> UInt32 {
      let inputOffset = try AudioDevice.safetyOffset(deviceID: anInputDevice, scope: .input)
      let outputOffset = try AudioDevice.safetyOffset(deviceID: outputDevice, scope: .output)
      let inputBuffer = try AudioDevice.bufferFrameSize(deviceID: anInputDevice, scope: .input)
      let outputBuffer = try AudioDevice.bufferFrameSize(deviceID: outputDevice, scope: .output)
      return inputOffset + outputOffset + inputBuffer + outputBuffer
   }
}

extension PlayThroughEngine {

   private static func with(_ closure: @autoclosure () -> OSStatus) throws {
      try verifyStatusCode(closure())
   }

   private func with(_ closure: @autoclosure () -> OSStatus) throws {
      try PlayThroughEngine.verifyStatusCode(closure())
   }

   private static func verifyStatusCode(_ status: OSStatus) throws {
      if status != noErr {
         throw Errors.OSStatusError(status)
      }
   }

   private static func verifyDeviceID(_ deviceID: AudioDeviceID) throws {
      if deviceID == kAudioDeviceUnknown {
         throw Errors.unexpectedDeviceID(deviceID)
      }
   }

   private func verifyDeviceID(_ deviceID: AudioDeviceID) throws {
      try PlayThroughEngine.verifyDeviceID(deviceID)
   }
}
