//
//  PlayThroughRenderUtility.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 23.03.16.
//  Copyright © 2016 Vlad Gorloff. All rights reserved.
//

import AVFoundation

private let playThroughRenderUtilityInputRenderCallback: AURenderCallback = { inRefCon, ioActionFlags, inTimeStamp,
	inBusNumber, inNumberFrames, ioData in
	let sampleTime = inTimeStamp.memory.mSampleTime
	let renderUtility = unsafeBitCast(inRefCon, PlayThroughRenderUtility.self)
	if renderUtility.firstInputTime == nil {
		renderUtility.firstInputTime = sampleTime
	}
	let buffer = renderUtility.inputBuffer
	buffer.frameLength = inNumberFrames // Not required, but recommended to keep in sync.
	var status = AudioUnitRender(renderUtility.inputUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames,
	                         buffer.mutableAudioBufferList)
	if status == noErr {
		let ringBuffer = renderUtility.ringBuffer
		status = ringBuffer.Store(buffer.audioBufferList, framesToWrite: inNumberFrames, startWrite: sampleTime.int64Value).rawValue
	}
	return status
}

private let playThroughRenderUtilityOutputRenderCallback: AURenderCallback = { inRefCon, ioActionFlags, inTimeStamp,
	inBusNumber, inNumberFrames, ioData in
	let renderUtility = unsafeBitCast(inRefCon, PlayThroughRenderUtility.self)
	let audioBuffers = UnsafeMutableAudioBufferListPointer(ioData).audioBuffers
	if renderUtility.firstInputTime == nil {
		audioBuffers.forEach { audioBuffer in audioBuffer.fillWithZeros() }
		return noErr
	}

	var inputTimeStamp = AudioTimeStamp()
	var status = AudioDeviceGetCurrentTime(renderUtility.inputDevice, &inputTimeStamp)
	// this callback may still be called a few times after the device has been stopped
	if status != noErr {
		audioBuffers.forEach { audioBuffer in audioBuffer.fillWithZeros() }
		return noErr
	}

	var outTimeStamp = AudioTimeStamp()
	status = AudioDeviceGetCurrentTime(renderUtility.outputDevice, &outTimeStamp)
	if status != noErr {
		return status
	}

	//use the varispeed playback rate to offset small discrepancies in sample rate
	let rate = inputTimeStamp.mRateScalar / outTimeStamp.mRateScalar
	status = AudioUnitSetParameter(renderUtility.varispeedUnit, kVarispeedParam_PlaybackRate, kAudioUnitScope_Global, 0,
	                               rate.floatValue, 0)
	if status != noErr {
		return status
	}

	let sampleTime = inTimeStamp.memory.mSampleTime
	if renderUtility.firstOutputTime == nil {
		renderUtility.firstOutputTime = sampleTime
		let delta = (renderUtility.firstInputTime ?? 0) - (renderUtility.firstOutputTime ?? 0)
		let offset = try? PlayThroughRenderUtility.computeThruOffset(inputDevice: renderUtility.inputDevice,
			outputDevice: renderUtility.outputDevice)
		renderUtility.inToOutSampleOffset = (offset ?? 0).doubleValue
		if delta < 0 {
			renderUtility.inToOutSampleOffset -= delta
		} else {
		   renderUtility.inToOutSampleOffset = -delta + renderUtility.inToOutSampleOffset
		}

		audioBuffers.forEach { audioBuffer in audioBuffer.fillWithZeros() }
		return noErr
	}

	 //copy the data from the buffers
	let ringBuffer = renderUtility.ringBuffer
	let startFetch = sampleTime - renderUtility.inToOutSampleOffset
	let err = ringBuffer.Fetch(ioData, nFrames: inNumberFrames, startRead: startFetch.int64Value)
	if err != .NoError {
		audioBuffers.forEach { audioBuffer in audioBuffer.fillWithZeros() }
		var bufferStartTime: SampleTime = 0
		var bufferEndTime: SampleTime = 0
		ringBuffer.GetTimeBounds(startTime: &bufferStartTime, endTime: &bufferEndTime)
		renderUtility.inToOutSampleOffset = sampleTime - bufferStartTime.doubleValue
	}

	return noErr
}

public final class PlayThroughRenderUtility {

	public enum Error: ErrorType {
		case OSStatusError(OSStatus)
		case UnableToFindComponent(AudioComponentDescription)
		case UnexpectedDeviceID(AudioDeviceID)
	}

	public let inputDevice: AudioDeviceID
	public let outputDevice: AudioDeviceID

	private var inputUnit: AudioUnit = nil
	private var varispeedNode: AUNode = 0
	private var outputNode: AUNode = 0
	private var varispeedUnit: AudioUnit = nil
	private var outputUnit: AudioUnit = nil
	private var auGraph: AUGraph = nil
	private var inputBuffer: AVAudioPCMBuffer!
	private var ringBuffer: CARingBuffer<Float>!
	private var inToOutSampleOffset: Double = 0
	private var firstInputTime: Double?
	private var firstOutputTime: Double?

	public init(inputDevice anInput: AudioDeviceID, outputDevice anOutput: AudioDeviceID) throws {
		inputDevice = anInput
		outputDevice = anOutput
		//Note: You can interface to input and output devices with "output" audio units.
		//Please keep in mind that you are only allowed to have one output audio unit per graph (AUGraph).
		//As you will see, this sample code splits up the two output units.  The "output" unit that will
		//be used for device input will not be contained in a AUGraph, while the "output" unit that will
		//interface the default output device will be in a graph.
		inputUnit = try setupInputDevice(anInput) // Setup AUHAL for an input device
		auGraph = try setUpAUGraph()
		try setupOutputDevice(anOutput) // Setup Graph containing Varispeed Unit & Default Output Unit
	}

	deinit {
		_ = try? cleanup()
	}

	// MARK: - Public

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
		let auhalRunning: UInt32 = try AudioUnitUtility.getProperty(inputUnit, propertyID: kAudioOutputUnitProperty_IsRunning,
		                                                        scope: kAudioUnitScope_Global, element: 0)
		var graphRunning = DarwinBoolean(false)
		try with(AUGraphIsRunning(auGraph, &graphRunning))
		return (auhalRunning != 0) || graphRunning.boolValue
	}


	// MARK: - Private

	private func cleanup() throws {
		try stop()
		try with(AudioUnitUninitialize(inputUnit))
		try with(AUGraphClose(auGraph))
		try with(DisposeAUGraph(auGraph))
		try with(AudioComponentInstanceDispose(inputUnit))
	}

	private func setupInputDevice(inputDevice: AudioDeviceID) throws -> AudioUnit {
		try verifyDeviceID(inputDevice)
		var desc = AudioComponentDescription(type: kAudioUnitType_Output, subType: kAudioUnitSubType_HALOutput)
		let comp = AudioComponentFindNext(nil, &desc)
		if comp == nil {
			throw Error.UnableToFindComponent(desc)
		}

		var audioUnit: AudioUnit = nil
		try with(AudioComponentInstanceNew(comp, &audioUnit))
		try with(AudioUnitInitialize(audioUnit))

		// You must enable the Audio Unit (AUHAL) for input and disable output BEFORE setting the AUHAL's current device.
		var enableIO: UInt32 = 1
		try with(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO,
			kAudioUnitScope_Input, 1, &enableIO, sizeof(UInt32).uint32Value)) // "1" means input element

		// Disable Output on the AUHAL
		enableIO = 0
		try with(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO,
			kAudioUnitScope_Output, 0, &enableIO, sizeof(UInt32).uint32Value)) // "0" means output element

		// Set the Current Device to the AUHAL. This should be done only after IO has been enabled on the AUHAL.
		var inDevice = inputDevice
		try with(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_CurrentDevice,
			kAudioUnitScope_Global, 0, &inDevice, sizeof(AudioDeviceID).uint32Value))

		// Set up input callback
		let context = UnsafeMutablePointer<Void>(unsafeAddressOf(self))
		var renderCallbackStruct = AURenderCallbackStruct(inputProc: playThroughRenderUtilityInputRenderCallback,
		                                                  inputProcRefCon: context)
		try with(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_SetInputCallback,
			kAudioUnitScope_Global, 0, &renderCallbackStruct, sizeof(AURenderCallbackStruct).uint32Value))

		// Don't setup buffers until you know what the input and output device audio streams look like.
		try with(AudioUnitInitialize(audioUnit)) // TODO: Why this needed?

		return audioUnit
	}

	private func setUpAUGraph() throws -> AUGraph {
		var varispeedDesc = AudioComponentDescription(type: kAudioUnitType_FormatConverter, subType: kAudioUnitSubType_Varispeed)
		var outDesc = AudioComponentDescription(type: kAudioUnitType_Output, subType: kAudioUnitSubType_DefaultOutput)

		var graph: AUGraph = nil
		try with(NewAUGraph(&graph))
		try with(AUGraphOpen(graph)) // Open the Graph, AudioUnits are opened but not initialized

		try with(AUGraphAddNode(graph, &varispeedDesc, &varispeedNode))
		try with(AUGraphAddNode(graph, &outDesc, &outputNode))

		// Get Audio Units from AUGraph nodes
		try with(AUGraphNodeInfo(graph, varispeedNode, nil, &varispeedUnit))
		try with(AUGraphNodeInfo(graph, outputNode, nil, &outputUnit))

		return graph
	}

	private func setupOutputDevice(outputDevice: AudioDeviceID) throws {
		try verifyDeviceID(outputDevice)
		//Set the Current Device to the Default Output Unit.
		var outDevice = outputDevice
		try AudioUnitUtility.setProperty(outputUnit, propertyID: kAudioOutputUnitProperty_CurrentDevice,
			scope: kAudioUnitScope_Global, element: 0, data: &outDevice)

		// Tell the output unit not to reset timestamps. Otherwise sample rate changes will cause sync los
		var startAtZero: UInt32 = 0
		try AudioUnitUtility.setProperty(outputUnit, propertyID: kAudioOutputUnitProperty_StartTimestampsAtZero,
		                             scope: kAudioUnitScope_Global, element: 0, data: &startAtZero)
		// Set up output callback
		let context = UnsafeMutablePointer<Void>(unsafeAddressOf(self))
		var renderCallbackStruct = AURenderCallbackStruct(inputProc: playThroughRenderUtilityOutputRenderCallback,
		                                                  inputProcRefCon: context)
		try AudioUnitUtility.setProperty(varispeedUnit, propertyID: kAudioUnitProperty_SetRenderCallback,
			scope: kAudioUnitScope_Input, element: 0, data: &renderCallbackStruct)

		try setupBuffers()

		// the varispeed unit should only be connected after the input and output formats have been set
		try with(AUGraphConnectNodeInput(auGraph, varispeedNode, 0, outputNode, 0))
		try with(AUGraphInitialize(auGraph))
		inToOutSampleOffset = try PlayThroughRenderUtility.computeThruOffset(inputDevice: inputDevice,
		                                                                     outputDevice: outputDevice).doubleValue
	}

	private func setupBuffers() throws {
		let bufferSizeFrames: UInt32 =
			try AudioUnitUtility.getProperty(inputUnit, propertyID: kAudioDevicePropertyBufferFrameSize,
			                                 scope: kAudioUnitScope_Global, element: 0)
		let asbd_dev1_in: AudioStreamBasicDescription =
			try AudioUnitUtility.getProperty(inputUnit, propertyID: kAudioUnitProperty_StreamFormat,
			                                 scope: kAudioUnitScope_Input, element: 1)
		var asbd: AudioStreamBasicDescription =
			try AudioUnitUtility.getProperty(inputUnit, propertyID: kAudioUnitProperty_StreamFormat,
			                                 scope: kAudioUnitScope_Output, element: 1)
		let asbd_dev2_out: AudioStreamBasicDescription =
			try AudioUnitUtility.getProperty(outputUnit, propertyID: kAudioUnitProperty_StreamFormat,
			                                 scope: kAudioUnitScope_Output, element: 0)

		//Set the format of all the AUs to the input/output devices channel count
		//For a simple case, you want to set this to the lower of count of the channels
		//in the input device vs output device
		asbd.mChannelsPerFrame = min(asbd_dev1_in.mChannelsPerFrame, asbd_dev2_out.mChannelsPerFrame)

		// We must get the sample rate of the input device and set it to the stream format of AUHAL
		let theAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyNominalSampleRate,
		                                            mScope: kAudioObjectPropertyScopeGlobal,
		                                            mElement: kAudioObjectPropertyElementMaster)
		var rate: Double = try AudioObjectUtility.getPropertyData(inputDevice, address: theAddress)
		asbd.mSampleRate = rate
		try AudioUnitUtility.setProperty(inputUnit, propertyID: kAudioUnitProperty_StreamFormat,
		                                 scope: kAudioUnitScope_Output, element: 1, data: &asbd)
		try AudioUnitUtility.setProperty(varispeedUnit, propertyID: kAudioUnitProperty_StreamFormat,
		                                 scope: kAudioUnitScope_Input, element: 0, data: &asbd)

		//Set the correct sample rate for the output device, but keep the channel count the same
		rate = try AudioObjectUtility.getPropertyData(outputDevice, address: theAddress)
		asbd.mSampleRate = rate
		try AudioUnitUtility.setProperty(varispeedUnit, propertyID: kAudioUnitProperty_StreamFormat,
		                                 scope: kAudioUnitScope_Output, element: 0, data: &asbd)
		try AudioUnitUtility.setProperty(outputUnit, propertyID: kAudioUnitProperty_StreamFormat,
		                                 scope: kAudioUnitScope_Input, element: 0, data: &asbd)

		let format = AVAudioFormat(streamDescription: &asbd)
		inputBuffer = AVAudioPCMBuffer(PCMFormat: format, frameCapacity: bufferSizeFrames)

		assert(asbd.mBytesPerFrame.intValue == sizeof(Float))
		ringBuffer = CARingBuffer<Float>(numberOfChannels: asbd.mChannelsPerFrame, capacityFrames: bufferSizeFrames * 20)
	}

	private static func computeThruOffset(inputDevice anInputDevice: AudioDeviceID, outputDevice: AudioDeviceID) throws -> UInt32 {
		let inputOffset = try AudioDevice.safetyOffset(anInputDevice, scope: .Input)
		let outputOffset = try AudioDevice.safetyOffset(outputDevice, scope: .Output)
		let inputBuffer = try AudioDevice.bufferFrameSize(anInputDevice, scope: .Input)
		let outputBuffer = try AudioDevice.bufferFrameSize(outputDevice, scope: .Output)
		return inputOffset + outputOffset + inputBuffer + outputBuffer
	}

	private static func with(@autoclosure closure: Void -> OSStatus) throws {
		try verifyStatusCode(closure())
	}

	private func with(@autoclosure closure: Void -> OSStatus) throws {
		try PlayThroughRenderUtility.verifyStatusCode(closure())
	}

	private static func verifyStatusCode(status: OSStatus) throws {
		if status != noErr {
			throw Error.OSStatusError(status)
		}
	}

	private static func verifyDeviceID(deviceID: AudioDeviceID) throws {
		if deviceID == kAudioDeviceUnknown {
			throw Error.UnexpectedDeviceID(deviceID)
		}
	}
	private func verifyDeviceID(deviceID: AudioDeviceID) throws {
		try PlayThroughRenderUtility.verifyDeviceID(deviceID)
	}
}
