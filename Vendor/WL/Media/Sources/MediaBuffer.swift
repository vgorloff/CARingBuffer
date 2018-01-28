//
//  MediaBuffer.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 22.07.17.
//  Copyright © 2017 WaveLabs. All rights reserved.
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
      } set {
         precondition(index < numberOfElements)
         mutableData[Int(index)] = newValue
      }
   }
}
