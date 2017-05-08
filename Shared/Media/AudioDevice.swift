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
      case input = 1
      case output = 0
      fileprivate var audioObjectPropertyScope: AudioObjectPropertyScope {
         return (self == .input) ? kAudioObjectPropertyScopeInput : kAudioObjectPropertyScopeOutput
      }
   }

   public enum Errors: Error {
      case unexpectedDeviceID(AudioDeviceID)
      case audioHardwareError(OSStatus)
      case unableToGetProperty(AudioObjectPropertySelector)
      case unexpectedPropertyDataSize(expected: UInt32, observed: UInt32)
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
      var value = Array<CChar>(repeating: 0, count: propertyDataSize.intValue) // swiftlint:disable:this syntactic_sugar
      try getPropertyData(inObjectID: deviceID, inAddress: &propertyAddress, ioDataSize: &propertyDataSize, outData: &value)
      guard let deviceName = String(utf8String: &value) else {
         throw Errors.unableToGetProperty(kAudioDevicePropertyDeviceName)
      }
      return deviceName
   }

   public static func defaultDeviceForScope(scope: Scope) throws -> AudioDeviceID {
      let selector = (scope == .input) ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice
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
      var propertyDataSize = try getPropertyDataSize(inObjectID: kAudioObjectSystemObject.uint32Value,
                                                     inAddress: &propertyAddress)
      let numberOfDevices = propertyDataSize / MemoryLayout<AudioDeviceID>.size.uint32Value
      var value: [AudioDeviceID] = Array(repeating: 0, count: numberOfDevices.intValue)
      try getPropertyData(inObjectID: kAudioObjectSystemObject.uint32Value, inAddress: &propertyAddress,
                          ioDataSize: &propertyDataSize, outData: &value)
      return value
   }

   public static func audioDevicesForScope(scope: Scope) throws -> [AudioDeviceID] {
      let deviceIDs = try audioDevices().filter { deviceID in
         let numOfChannels = try? numberOfChannels(deviceID: deviceID, scope: scope)
         return (numOfChannels ?? 0) > 0
      }
      return deviceIDs
   }

   // MARK: - Private

   private static func getPropertyDataSize(inObjectID: AudioObjectID, inAddress: UnsafePointer<AudioObjectPropertyAddress>,
                                           inQualifierDataSize: UInt32 = 0,
                                           inQualifierData: UnsafeRawPointer? = nil) throws -> UInt32 {
      var propertyDataSize = UInt32(0)
      let status = AudioObjectGetPropertyDataSize(inObjectID, inAddress, inQualifierDataSize, inQualifierData, &propertyDataSize)
      try verifyStatusCode(statusCode: status)
      return propertyDataSize
   }

   private static func getPropertyData<T>(inObjectID: AudioObjectID, inAddress: UnsafePointer<AudioObjectPropertyAddress>,
                                          inQualifierDataSize: UInt32 = 0, inQualifierData: UnsafeRawPointer? = nil,
                                          outData: UnsafeMutablePointer<T>) throws {
      var propertyDataSize = try getPropertyDataSize(inObjectID: inObjectID, inAddress: inAddress)
      guard propertyDataSize == MemoryLayout<T>.size.uint32Value else {
         throw Errors.unexpectedPropertyDataSize(expected: MemoryLayout<T>.size.uint32Value, observed: propertyDataSize)
      }
      let status = AudioObjectGetPropertyData(inObjectID, inAddress, inQualifierDataSize, inQualifierData,
                                              &propertyDataSize, outData)
      try verifyStatusCode(statusCode: status)
   }

   private static func getPropertyData<T>(inObjectID: AudioObjectID, inAddress: UnsafePointer<AudioObjectPropertyAddress>,
                                          inQualifierDataSize: UInt32 = 0, inQualifierData: UnsafeRawPointer? = nil,
                                          ioDataSize: UnsafeMutablePointer<UInt32>, outData: UnsafeMutablePointer<T>) throws {
      let status = AudioObjectGetPropertyData(inObjectID, inAddress, inQualifierDataSize, inQualifierData, ioDataSize, outData)
      try verifyStatusCode(statusCode: status)
   }

   private static func verifyDeviceID(deviceID: AudioDeviceID) throws {
      if deviceID == kAudioDeviceUnknown {
         throw Errors.unexpectedDeviceID(deviceID)
      }
   }

   private static func verifyStatusCode(statusCode: OSStatus) throws {
      if statusCode != kAudioHardwareNoError {
         throw Errors.audioHardwareError(statusCode)
      }
   }
}
