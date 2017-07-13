//
//  MediaBufferList.swift
//  WaveLabs
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
      dataByteSize = UInt(MemoryLayout<T>.stride * numberOfElements)
      self.mutableData = mutableData
      data = UnsafePointer(mutableData)
   }

   public init(data: UnsafePointer<T>, numberOfElements: Int) {
      self.numberOfElements = UInt(numberOfElements)
      dataByteSize = UInt(MemoryLayout<T>.stride * numberOfElements)
      mutableData = UnsafeMutablePointer(mutating: data)
      self.data = data
   }

   public subscript(index: UInt) -> T {
      get {
         precondition(index < numberOfElements)
         return data[Int(index)]
      }
      set {
         precondition(index < numberOfElements)
         mutableData[Int(index)] = newValue
      }
   }
}

public struct MediaBufferList<T> {

   public let numberOfBuffers: UInt
   public let buffers: UnsafePointer<MediaBuffer<T>>
   public let mutableBuffers: UnsafeMutablePointer<MediaBuffer<T>>

   public init(mutableBuffers: UnsafeMutablePointer<MediaBuffer<T>>, numberOfBuffers: Int) {
      self.numberOfBuffers = UInt(numberOfBuffers)
      self.mutableBuffers = mutableBuffers
      buffers = UnsafePointer(mutableBuffers)
   }

   public init(buffers: UnsafePointer<MediaBuffer<T>>, numberOfBuffers: Int) {
      self.numberOfBuffers = UInt(numberOfBuffers)
      mutableBuffers = UnsafeMutablePointer(mutating: buffers)
      self.buffers = buffers
   }

   public subscript(index: UInt) -> UnsafePointer<MediaBuffer<T>> {
      precondition(index < numberOfBuffers)
      return buffers.advanced(by: Int(index))
   }
}
