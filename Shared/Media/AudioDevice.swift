//
//  AudioDevice.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 23.03.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import CoreAudio

public final class AudioDevice {

	public enum Scope: Int {
		case Input = 1
		case Output = 0
		private var audioObjectPropertyScope: AudioObjectPropertyScope {
			return (self == .Input) ? kAudioObjectPropertyScopeInput : kAudioObjectPropertyScopeOutput
		}
	}

	public enum Error: ErrorProtocol {
		case UnexpectedDeviceID(AudioDeviceID)
		case AudioHardwareError(OSStatus)
		case UnableToGetProperty(AudioObjectPropertySelector)
		case UnexpectedPropertyDataSize(expected: UInt32, observed: UInt32)
	}

	public private(set) var deviceID: AudioDeviceID
	public private(set) var numberOfChannels: UInt32
	public private(set) var name: String
	public private(set) var safetyOffset: UInt32
	public private(set) var bufferFrameSize: UInt32

	public init(deviceID aDeviceID: AudioDeviceID, scope: Scope) throws {
		try AudioDevice.verifyDeviceID(deviceID: aDeviceID)
		deviceID = aDeviceID
		numberOfChannels = try AudioDevice.numberOfChannels(deviceID: deviceID, scope: scope)
		name = try AudioDevice.deviceName(deviceID: deviceID, scope: scope)
		safetyOffset = try AudioDevice.safetyOffset(deviceID: deviceID, scope: scope)
		bufferFrameSize = try AudioDevice.bufferFrameSize(deviceID: deviceID, scope: scope)
	}

	// MARK: - Static

	public static func numberOfChannels(deviceID: AudioDeviceID, scope: Scope) throws -> UInt32 {
		try AudioDevice.verifyDeviceID(deviceID: deviceID)
		var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreamConfiguration,
		                                                            mScope: scope.audioObjectPropertyScope, mElement: 0)
		var value = AudioBufferList()
		try getPropertyData(inObjectID: deviceID, inAddress: &propertyAddress, outData: &value)
		let ablPointer = UnsafeMutableAudioBufferListPointer(&value)
		var numberChannels = UInt32(0)
		for audioBuffer in ablPointer.audioBuffers {
			numberChannels += audioBuffer.mNumberChannels
		}
		return numberChannels
	}

	public static func safetyOffset(deviceID: AudioDeviceID, scope: Scope) throws -> UInt32 {
		try AudioDevice.verifyDeviceID(deviceID: deviceID)
		var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertySafetyOffset,
		                                                 mScope: scope.audioObjectPropertyScope, mElement: 0)
		var value: UInt32 = 0
		try getPropertyData(inObjectID: deviceID, inAddress: &propertyAddress, outData: &value)
		return value
	}

	public static func bufferFrameSize(deviceID: AudioDeviceID, scope: Scope) throws -> UInt32 {
		try AudioDevice.verifyDeviceID(deviceID: deviceID)
		var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyBufferFrameSize,
		                                                 mScope: scope.audioObjectPropertyScope, mElement: 0)
		var value: UInt32 = 0
		try getPropertyData(inObjectID: deviceID, inAddress: &propertyAddress, outData: &value)
		return value
	}

	public static func deviceName(deviceID: AudioDeviceID, scope: Scope) throws -> String {
		try AudioDevice.verifyDeviceID(deviceID: deviceID)
		var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceName,
		                                                 mScope: scope.audioObjectPropertyScope, mElement: 0)
		var propertyDataSize = try getPropertyDataSize(inObjectID: deviceID, inAddress: &propertyAddress)
		var value = Array<CChar>(repeating: 0, count: propertyDataSize.intValue)
      try getPropertyData(inObjectID: deviceID, inAddress: &propertyAddress, ioDataSize: &propertyDataSize, outData: &value)
		guard let deviceName = String(utf8String: &value) else {
			throw Error.UnableToGetProperty(kAudioDevicePropertyDeviceName)
		}
		return deviceName
	}

	public static func defaultDeviceForScope(scope: Scope) throws -> AudioDeviceID {
		let selector = (scope == .Input) ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice
		var propertyAddress = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal,
		                                                         mElement: kAudioObjectPropertyElementMaster)
		var value = AudioDeviceID(0)
		try getPropertyData(inObjectID: kAudioObjectSystemObject.uint32Value, inAddress: &propertyAddress, outData: &value)
		return value
	}

	public static func audioDevices() throws -> [AudioDeviceID] {
		var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
		                                                 mScope: kAudioObjectPropertyScopeGlobal,
		                                                 mElement: kAudioObjectPropertyElementMaster)
		var propertyDataSize = try getPropertyDataSize(inObjectID: kAudioObjectSystemObject.uint32Value, inAddress: &propertyAddress)
		let numberOfDevices = propertyDataSize / sizeof(AudioDeviceID.self).uint32Value
		var value = Array<AudioDeviceID>(repeating: 0, count: numberOfDevices.intValue)
      try getPropertyData(inObjectID: kAudioObjectSystemObject.uint32Value, inAddress: &propertyAddress,
		                    ioDataSize: &propertyDataSize, outData: &value)
		return value
	}

	public static func audioDevicesForScope(scope: Scope) throws -> [AudioDeviceID] {
		let deviceIDs = try audioDevices().filter { deviceID in
			return (try? numberOfChannels(deviceID: deviceID, scope: scope) ?? 0) > 0
		}
		return deviceIDs
	}

	// MARK: - Private

	private static func getPropertyDataSize(inObjectID: AudioObjectID, inAddress: UnsafePointer<AudioObjectPropertyAddress>,
	                                        inQualifierDataSize: UInt32 = 0,
	                                        inQualifierData: UnsafePointer<Void>? = nil) throws -> UInt32 {
		var propertyDataSize = UInt32(0)
		let status = AudioObjectGetPropertyDataSize(inObjectID, inAddress, inQualifierDataSize, inQualifierData, &propertyDataSize)
		try verifyStatusCode(statusCode: status)
		return propertyDataSize
	}

	private static func getPropertyData<T>(inObjectID: AudioObjectID, inAddress: UnsafePointer<AudioObjectPropertyAddress>,
	                                    inQualifierDataSize: UInt32 = 0, inQualifierData: UnsafePointer<Void>? = nil,
	                                    outData: UnsafeMutablePointer<T>) throws {
		var propertyDataSize = try getPropertyDataSize(inObjectID: inObjectID, inAddress: inAddress)
		guard propertyDataSize == sizeof(T.self).uint32Value else {
			throw Error.UnexpectedPropertyDataSize(expected: sizeof(T.self).uint32Value, observed: propertyDataSize)
		}
		let status = AudioObjectGetPropertyData(inObjectID, inAddress, inQualifierDataSize, inQualifierData, &propertyDataSize, outData)
		try verifyStatusCode(statusCode: status)
	}

	private static func getPropertyData<T>(inObjectID: AudioObjectID, inAddress: UnsafePointer<AudioObjectPropertyAddress>,
	                                    inQualifierDataSize: UInt32 = 0, inQualifierData: UnsafePointer<Void>? = nil,
	                                    ioDataSize: UnsafeMutablePointer<UInt32>, outData: UnsafeMutablePointer<T>) throws {
		let status = AudioObjectGetPropertyData(inObjectID, inAddress, inQualifierDataSize, inQualifierData, ioDataSize, outData)
		try verifyStatusCode(statusCode: status)
	}

	private static func verifyDeviceID(deviceID: AudioDeviceID) throws {
		if deviceID == kAudioDeviceUnknown {
			throw Error.UnexpectedDeviceID(deviceID)
		}
	}

	private static func verifyStatusCode(statusCode: OSStatus) throws {
		if statusCode != kAudioHardwareNoError {
			throw Error.AudioHardwareError(statusCode)
		}
	}
}
