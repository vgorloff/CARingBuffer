//
//  RingBufferOffsets.swift
//  WL
//
//  Created by Vlad Gorlov on 23.08.18.
//  Copyright © 2018 WaveLabs. All rights reserved.
//

import Foundation

class RingBufferOffsets {

   typealias SampleTime = RingBufferTimeBounds.SampleTime

   struct UpdateProcedure {
      let sourceOffset: SampleTime
      let destinationOffset: SampleTime
      let numberOfElements: SampleTime
   }

   struct ZeroProcedure {
      let offset: SampleTime
      let numberOfElements: SampleTime
   }

   let timeBounds = RingBufferTimeBounds()

   let capacity: SampleTime

   init(capacity: SampleTime) {
      self.capacity = capacity
   }

}

extension RingBufferOffsets {

   func store(framesToWrite: SampleTime, startWrite: SampleTime,
              storeProcedure: (UpdateProcedure) -> Void, zeroProcedure: (ZeroProcedure) -> Void) -> RingBufferError {

      if framesToWrite == 0 {
         return .noError
      }

      if framesToWrite > capacity {
         return .tooMuch
      }

      let endWrite = startWrite + framesToWrite

      // Adjusting bounds.
      do {
         if startWrite < timeBounds.bounds.end {
            // Going backwards, throw everything out
            timeBounds.set(start: startWrite, end: startWrite)
         } else if endWrite - timeBounds.bounds.start <= capacity {
            // The buffer has not yet wrapped and will not need to
         } else {
            // Advance the start time past the region we are about to overwrite
            let newStart = endWrite - capacity // One buffer of time behind where we're writing
            let newEnd = max(newStart, timeBounds.bounds.end)
            timeBounds.set(start: newStart, end: newEnd)
         }
      }

      let curEnd = timeBounds.bounds.end
      var offset0: SampleTime
      var offset1: SampleTime
      if startWrite > curEnd {
         // We are skipping some samples, so zero the range we are skipping
         offset0 = curEnd % capacity
         offset1 = startWrite % capacity
         if offset0 < offset1 {
            zeroProcedure(ZeroProcedure(offset: offset0, numberOfElements: offset1 - offset0))
         } else {
            zeroProcedure(ZeroProcedure(offset: offset0, numberOfElements: capacity - offset0))
            zeroProcedure(ZeroProcedure(offset: 0, numberOfElements: offset1))
         }
         offset0 = offset1
      } else {
         offset0 = startWrite % capacity
      }

      offset1 = endWrite % capacity
      if offset0 < offset1 {
         storeProcedure(UpdateProcedure(sourceOffset: 0, destinationOffset: offset0, numberOfElements: offset1 - offset0))
      } else {
         let numberOfElements = capacity - offset0
         storeProcedure(UpdateProcedure(sourceOffset: 0, destinationOffset: offset0, numberOfElements: numberOfElements))
         storeProcedure(UpdateProcedure(sourceOffset: numberOfElements, destinationOffset: 0, numberOfElements: offset1))
      }

      // Updating the end time
      timeBounds.set(start: timeBounds.bounds.start, end: endWrite)

      return .noError
   }

   func fetch(framesToRead: SampleTime, startRead: SampleTime,
              fetchProcedure: (UpdateProcedure) -> Void, zeroProcedure: (ZeroProcedure) -> Void) -> RingBufferError {

      if framesToRead == 0 {
         return .noError
      }

      var startRead = max(0, startRead)
      var endRead = startRead + framesToRead

      let startRead0 = startRead
      let endRead0 = endRead

      if timeBounds.clip(start: &startRead, end: &endRead) == false {
         return .cpuOverload
      }

      // Out of range case.
      if startRead == endRead {
         zeroProcedure(ZeroProcedure(offset: 0, numberOfElements: framesToRead))
         return .noError
      }

      let elementsSize = endRead - startRead

      let destinationOffset = max(0, (startRead - startRead0))
      if destinationOffset > 0 {
         zeroProcedure(ZeroProcedure(offset: 0, numberOfElements: min(framesToRead, destinationOffset)))
      }

      let destEndSize = max(0, endRead0 - endRead)
      if destEndSize > 0 {
         zeroProcedure(ZeroProcedure(offset: destinationOffset + elementsSize, numberOfElements: destEndSize))
      }

      let offset0 = startRead % capacity
      let offset1 = endRead % capacity
      var numberOfElements: SampleTime = 0

      if offset0 < offset1 {
         numberOfElements = offset1 - offset0
         fetchProcedure(UpdateProcedure(sourceOffset: offset0, destinationOffset: destinationOffset,
                                        numberOfElements: numberOfElements))
      } else {
         numberOfElements = capacity - offset0
         fetchProcedure(UpdateProcedure(sourceOffset: offset0, destinationOffset: destinationOffset,
                                        numberOfElements: numberOfElements))
         fetchProcedure(UpdateProcedure(sourceOffset: 0, destinationOffset: destinationOffset + numberOfElements,
                                        numberOfElements: offset1))
         numberOfElements += offset1
      }

      // FIXME: Do we really need to update mDataByteSize?.
      //      let ablPointer = UnsafeMutableAudioBufferListPointer(abl)
      //      for channel in 0..<ablPointer.count {
      //         var dest = ablPointer[channel]
      //         if dest.mData != nil {
      // FIXME: This should be in sync with AVAudioPCMBuffer (Vlad Gorlov, 2016-06-12).
      //            dest.mDataByteSize = UInt32(numberOfElements)
      //         }
      //      }

      return .noError
   }

}
