//
//  BufferList.swift
//  WLTests
//
//  Created by Vlad Gorlov on 08.09.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import Foundation

public struct MediaBuffer<T> {
   public let dataByteSize: UInt
   public let data: UnsafePointer<T>
   public let mutableData: UnsafeMutablePointer<T>
   public let numberOfElements: UInt
   public init(mutableData: UnsafeMutablePointer<T>, numberOfElements: Int) {
      self.numberOfElements = UInt(numberOfElements)
      self.dataByteSize = UInt(MemoryLayout<T>.stride * numberOfElements)
      self.mutableData = mutableData
      self.data = UnsafePointer(mutableData)
   }
   public init(data: UnsafePointer<T>, numberOfElements: Int) {
      self.numberOfElements = UInt(numberOfElements)
      self.dataByteSize = UInt(MemoryLayout<T>.stride * numberOfElements)
      self.mutableData = UnsafeMutablePointer(mutating: data)
      self.data = data
   }
}

public struct MediaBufferList<T> {
   public let numberBuffers: UInt
   public let buffers: UnsafePointer<MediaBuffer<T>>
   public let mutableBuffers: UnsafeMutablePointer<MediaBuffer<T>>
   public init(mutableBuffers: UnsafeMutablePointer<MediaBuffer<T>>, numberBuffers: Int) {
      self.numberBuffers = UInt(numberBuffers)
      self.mutableBuffers = mutableBuffers
      self.buffers = UnsafePointer(mutableBuffers)
   }
   public init(buffers: UnsafePointer<MediaBuffer<T>>, numberBuffers: Int) {
      self.numberBuffers = UInt(numberBuffers)
      self.mutableBuffers = UnsafeMutablePointer(mutating: buffers)
      self.buffers = buffers
   }
   public subscript(index: UInt) -> MediaBuffer<T> {
      get {
         precondition(index < numberBuffers)
         return buffers.advanced(by: Int(index)).pointee
      }
   }
}

