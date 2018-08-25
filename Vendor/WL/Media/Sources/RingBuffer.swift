//
//  RingBuffer.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 31.05.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import CoreAudio

public protocol RingBufferType {
   init()
}

extension Float: RingBufferType {}
extension Int32: RingBufferType {}
extension Int: RingBufferType {}
extension Double: RingBufferType {}


public enum RingBufferError: Int {

   case noError = 0

   /// Fetch start time is earlier than buffer start time and fetch end time is later than buffer end time
   case tooMuch

   /// The reader is unable to get enough CPU cycles to capture a consistent snapshot of the time bounds
   case cpuOverload
}

public final class RingBuffer<T: RingBufferType> {

   public typealias SampleTime = RingBufferTimeBounds.SampleTime

   public let numberOfChannels: Int

   let offsets: RingBufferOffsets

   private let capacityFrames: Int
   private let bytesPerFrame: SampleTime

   private let bufferLength: Int /// Number of allocated elements in buffer for all channels.
   private let buffer: UnsafeMutablePointer<T>

   /// Buffer pointer just for debug purpose.
   var bufferPointer: UnsafeMutableBufferPointer<T> {
      return UnsafeMutableBufferPointer(start: buffer, count: bufferLength)
   }

   /// - parameter numberOfChannels: Number of channels (non-interleaved).
   /// - parameter capacityFrames: Capacity per every channel.
   public init(numberOfChannels: Int, capacityFrames: Int) {
      self.numberOfChannels = numberOfChannels
      self.capacityFrames = capacityFrames
      bytesPerFrame = SampleTime(MemoryLayout<T>.stride)
      offsets = RingBufferOffsets(capacity: SampleTime(capacityFrames))
      bufferLength = Int(capacityFrames * numberOfChannels)
      buffer = UnsafeMutablePointer<T>.allocate(capacity: bufferLength)
      buffer.initialize(repeating: T(), count: bufferLength)
   }

   deinit {
      buffer.deallocate()
   }
}

extension RingBuffer {

   public func getTimeBounds() -> RingBufferTimeBounds.Result {
      return offsets.timeBounds.get()
   }

   /// Copy framesToWrite of data into the ring buffer at the specified sample time.
   /// The sample time should normally increase sequentially, though gaps
   /// are filled with zeroes. A sufficiently large gap effectively empties
   /// the buffer before storing the new data.
   /// If startWrite is less than the previous frame number, the behavior is undefined.
   /// Return false for failure (buffer not large enough).
   /// - parameter abl: Source AudioBufferList.
   /// - parameter framesToWrite: Frames to write.
   /// - parameter startWrite: Absolute time.
   /// - returns: Operation status code.
   public func store(_ abl: UnsafePointer<AudioBufferList>,
                     framesToWrite: SampleTime, startWrite: SampleTime) -> RingBufferError {
      return offsets.store(framesToWrite: framesToWrite, startWrite: startWrite, storeProcedure: { info in
         store(from: abl, into: buffer, info: info)
      }, zeroProcedure: { info in
         zero(info: info)
      })
   }

   public func fetch(_ abl: UnsafeMutablePointer<AudioBufferList>,
                     framesToRead: SampleTime, startRead: SampleTime) -> RingBufferError {
      return offsets.fetch(framesToRead: framesToRead, startRead: startRead, fetchProcedure: { info in
         fetch(into: abl, from: buffer, info: info)
      }, zeroProcedure: { info in
         zero(abl: abl, info: info)
      })
   }

   public func store(_ mediaBuffers: MediaBufferList<T>,
                     framesToWrite: SampleTime, startWrite: SampleTime) -> RingBufferError {
      return offsets.store(framesToWrite: framesToWrite, startWrite: startWrite, storeProcedure: { info in
         store(from: mediaBuffers, into: buffer, info: info)
      }, zeroProcedure: { info in
         zero(info: info)
      })
   }

   public func fetch(_ mediaBuffers: MediaBufferList<T>,
                     framesToRead: SampleTime, startRead: SampleTime) -> RingBufferError {
      return offsets.fetch(framesToRead: framesToRead, startRead: startRead, fetchProcedure: { info in
         fetch(into: mediaBuffers, from: buffer, info: info)
      }, zeroProcedure: { info in
         zero(mediaBufferList: mediaBuffers, info: info)
      })
   }

   public func fetch(_ mediaBuffers: MediaBufferList<T>, offsetFrames: SampleTime, framesToRead: SampleTime,
                     startRead: SampleTime) -> RingBufferError {
      return offsets.fetch(framesToRead: framesToRead, startRead: startRead, fetchProcedure: { info in
         let info = RingBufferOffsets.UpdateProcedure(sourceOffset: info.sourceOffset,
                                                        destinationOffset: info.destinationOffset + offsetFrames,
                                                        numberOfElements: info.numberOfElements)
         fetch(into: mediaBuffers, from: buffer, info: info)
      }, zeroProcedure: { info in
         let info = RingBufferOffsets.ZeroProcedure(offset: info.offset + offsetFrames, numberOfElements: info.numberOfElements)
         zero(mediaBufferList: mediaBuffers, info: info)
      })
   }
}

// MARK: - Private

extension RingBuffer {

   private func store(from abl: UnsafePointer<AudioBufferList>, into buffer: UnsafeMutablePointer<T>,
                      info: RingBufferOffsets.UpdateProcedure) {

      let bufferList = UnsafeMutableAudioBufferListPointer(unsafePointer: abl)
      let numOfChannels = max(bufferList.count, numberOfChannels)
      for channel in 0 ..< numOfChannels {
         guard channel < numberOfChannels else { // Ring buffer has less channels than input buffer
            continue
         }
         let positionWrite = buffer.advanced(by: Int(info.destinationOffset) + channel * capacityFrames)

         if channel < bufferList.count {
            let channelBuffer = bufferList[channel]
            guard let channelBufferData = channelBuffer.mData else {
               continue
            }
            assert(channelBuffer.mNumberChannels == 1) // Supporting non interleaved channels at the moment
            let channelData = channelBufferData.assumingMemoryBound(to: T.self)

            let channelCapacity = SampleTime(channelBuffer.mDataByteSize) / bytesPerFrame
            if info.sourceOffset > channelCapacity {
               continue
            }

            let positionRead = channelData.advanced(by: Int(info.sourceOffset))
            let numberOfElements = min(info.numberOfElements, channelCapacity - info.sourceOffset)
            positionWrite.assign(from: positionRead, count: Int(numberOfElements))
         } else {
            // ABL has less channels than expected. So we filling buffer with zeroes.
            positionWrite.initialize(repeating: T(), count: Int(info.numberOfElements))
         }
      }
   }

   private func fetch(into abl: UnsafeMutablePointer<AudioBufferList>, from buffer: UnsafeMutablePointer<T>,
                      info: RingBufferOffsets.UpdateProcedure) {

      let bufferList = UnsafeMutableAudioBufferListPointer(abl)
      for channel in 0 ..< bufferList.count {
         let channelBuffer = bufferList[channel]
         guard let channelBufferData = channelBuffer.mData else {
            continue
         }
         assert(channelBuffer.mNumberChannels == 1) // Supporting non interleaved channels at the moment
         let channelData = channelBufferData.assumingMemoryBound(to: T.self)

         let channelCapacity = SampleTime(channelBuffer.mDataByteSize) / bytesPerFrame
         if info.destinationOffset > channelCapacity {
            continue
         }

         let positionWrite = channelData.advanced(by: Int(info.destinationOffset))
         let numberOfElements = min(info.numberOfElements, channelCapacity - info.destinationOffset)
         if channel < numberOfChannels { // Ring buffer has less channels than output buffer
            let positionRead = buffer.advanced(by: Int(info.sourceOffset) + channel * capacityFrames)
            positionWrite.assign(from: positionRead, count: Int(numberOfElements))
         } else {
            positionWrite.initialize(repeating: T(), count: Int(numberOfElements))
         }
      }
   }

   private func zero(abl: UnsafeMutablePointer<AudioBufferList>, info: RingBufferOffsets.ZeroProcedure) {
      let bufferList = UnsafeMutableAudioBufferListPointer(abl)
      for channel in 0 ..< bufferList.count {
         let channelBuffer = bufferList[channel]
         guard let channelBufferData = channelBuffer.mData else {
            continue
         }
         let channelData = channelBufferData.assumingMemoryBound(to: T.self)
         assert(channelBuffer.mNumberChannels == 1) // Supporting non interleaved channels at the moment

         let channelCapacity = SampleTime(channelBuffer.mDataByteSize) / bytesPerFrame
         if info.offset > channelCapacity {
            continue
         }

         let positionWrite = channelData.advanced(by: Int(info.offset))
         let numberOfElements = min(info.numberOfElements, channelCapacity - info.offset)
         positionWrite.initialize(repeating: T(), count: Int(numberOfElements))
      }
   }

   private func store(from mediaBuffer: MediaBufferList<T>, into buffer: UnsafeMutablePointer<T>,
                      info: RingBufferOffsets.UpdateProcedure) {
      let numOfChannels = max(Int(mediaBuffer.numberOfBuffers), numberOfChannels)
      for channel in 0 ..< numOfChannels {
         guard channel < numberOfChannels else { // Ring buffer has less channels than input buffer
            continue
         }
         let positionWrite = buffer.advanced(by: Int(info.destinationOffset) + channel * capacityFrames)
         if channel < mediaBuffer.numberOfBuffers {
            let channelBuffer = mediaBuffer[UInt(channel)].pointee
            if info.sourceOffset > Int64(channelBuffer.numberOfElements) {
               continue // FIXME: Need to zero buffer for missed range
            }
            let positionRead = channelBuffer.data.advanced(by: Int(info.sourceOffset))
            let numOfElements = min(info.numberOfElements, SampleTime(channelBuffer.numberOfElements) - info.sourceOffset)
            positionWrite.assign(from: positionRead, count: Int(numOfElements))
         } else {
            positionWrite.initialize(repeating: T(), count: Int(info.numberOfElements))
         }
      }
   }

   private func fetch(into mediaBuffer: MediaBufferList<T>, from buffer: UnsafeMutablePointer<T>,
                      info: RingBufferOffsets.UpdateProcedure) {
      for channel in 0 ..< Int(mediaBuffer.numberOfBuffers) {
         let channelBuffer = mediaBuffer[UInt(channel)].pointee
         if info.destinationOffset > SampleTime(channelBuffer.numberOfElements) {
            continue
         }
         let positionWrite = channelBuffer.data.advanced(by: Int(info.destinationOffset))
         let writeDestination = UnsafeMutablePointer(mutating: positionWrite)
         let numOfElements = min(info.numberOfElements, SampleTime(channelBuffer.numberOfElements) - info.destinationOffset)
         if channel < numberOfChannels { // Ring buffer has less channels than output buffer
            let positionRead = buffer.advanced(by: Int(info.sourceOffset) + channel * capacityFrames)
            writeDestination.assign(from: positionRead, count: Int(numOfElements))
         } else {
            writeDestination.initialize(repeating: T(), count: Int(info.numberOfElements))
         }
      }
   }

   private func zero(mediaBufferList: MediaBufferList<T>, info: RingBufferOffsets.ZeroProcedure) {
      for channel in 0 ..< Int(mediaBufferList.numberOfBuffers) {
         let channelBuffer = mediaBufferList[UInt(channel)].pointee
         if info.offset > SampleTime(channelBuffer.numberOfElements) {
            continue
         }
         let channelData = channelBuffer.data
         let positionWrite = channelData.advanced(by: Int(info.offset))
         let writeDestination = UnsafeMutablePointer(mutating: positionWrite)
         let numOfElements = min(info.numberOfElements, SampleTime(channelBuffer.numberOfElements) - info.offset)
         writeDestination.initialize(repeating: T(), count: Int(numOfElements))
      }
   }

   private func zero(info: RingBufferOffsets.ZeroProcedure) {
      assert(Int(info.offset + info.numberOfElements) <= capacityFrames)
      for channel in 0 ..< numberOfChannels {
         let positionWrite = buffer.advanced(by: Int(info.offset) + channel * capacityFrames)
         positionWrite.initialize(repeating: T(), count: Int(info.numberOfElements))
      }
   }
}

// MARK: -

extension RingBuffer: CustomReflectable {

   public var customMirror: Mirror {
      var children: [(String?, Any)] = [
         ("numberOfChannels", numberOfChannels), ("capacityFrames", capacityFrames)
      ]
      switch offsets.timeBounds.get() {
      case .failure:
         break
      case.success(let start, let end):
         children += [("start", start), ("end", end)]
      }
      return Mirror(self, children: children)
   }
}

extension QuickLookProxy {

   public convenience init<T>(_ ringBuffer: RingBuffer<T>) {
      if let ringBuffer = ringBuffer as? RingBuffer<Float> {
         self.init(data: Array(ringBuffer.bufferPointer))
      } else {
         self.init(object: nil)
      }
   }
}
