//
//  CARBTests.CustomType.swift
//  CARingBuffer
//
//  Created by Vlad Gorlov on 07.09.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import XCTest
import AVFoundation

struct CustomSampleInnerType: Equatable {
   let a: Int
   let b: Float
   init(_ value: Int) {
      a = value
      b = Float(value)
   }
}
func == (lhs: CustomSampleInnerType, rhs: CustomSampleInnerType) -> Bool {
   return lhs.a == rhs.a && lhs.b == rhs.b
}

struct CustomSampleType: Equatable {
   let x: Int
   let y: UInt
   let z: Float
   let innerType: CustomSampleInnerType
   init(_ value: Int) {
      x = value
      y = UInt(value)
      z = Float(value)
      innerType = CustomSampleInnerType(value)
   }
}
func == (lhs: CustomSampleType, rhs: CustomSampleType) -> Bool {
   return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
}

extension AudioBuffer {
   var mCustomTypeData: UnsafeMutablePointer<CustomSampleType>? {
      return mData?.assumingMemoryBound(to: CustomSampleType.self)
   }
   var mCustomTypeBuffer: UnsafeMutableBufferPointer<CustomSampleType> {
      return UnsafeMutableBufferPointer<CustomSampleType>(start: mCustomTypeData, count: Int(mDataByteSize) / MemoryLayout<CustomSampleType>.stride)
   }
   var mCustomTypeArray: [CustomSampleType] {
      return Array<CustomSampleType>(mCustomTypeBuffer)
   }
}

extension CARBSwiftTests {

   func testIOWithDataTypeDouble() {

      func isSampleDataEqual(lhs: [Double], rhs: [Double]) -> Bool {
         guard lhs.count == rhs.count else {
            return false
         }
         for index in 0..<lhs.count {
            if lhs[index] != rhs[index] {
               return false
            }
         }
         return true
      }

      var channelData1In: [Double] = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5]
      var channelData2In: [Double] = [2.0, 2.1, 2.2, 2.3, 2.4, 2.5]
      var channelData3In: [Double] = [3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
      var channelData4In: [Double] = [4.0, 4.1, 4.2, 4.3, 4.4, 4.5]
      let channelData1Ptr = UnsafeMutableBufferPointer(start: &channelData1In, count: channelData1In.count)
      let channelData2Ptr = UnsafeMutableBufferPointer(start: &channelData2In, count: channelData2In.count)
      let channelData3Ptr = UnsafeMutableBufferPointer(start: &channelData3In, count: channelData3In.count)
      let channelData4Ptr = UnsafeMutableBufferPointer(start: &channelData4In, count: channelData4In.count)
      let ablPointerIn = AudioBufferList.allocate(maximumBuffers: 4)
      ablPointerIn[0] = AudioBuffer(channelData1Ptr, numberOfChannels: 1)
      ablPointerIn[1] = AudioBuffer(channelData2Ptr, numberOfChannels: 1)
      ablPointerIn[2] = AudioBuffer(channelData3Ptr, numberOfChannels: 1)
      ablPointerIn[3] = AudioBuffer(channelData4Ptr, numberOfChannels: 1)

      var channelData1Out: [Double] = [10.0, 10.1, 10.2, 10.3, 10.4, 10.5]
      var channelData2Out: [Double] = [20.0, 20.1, 20.2, 20.3, 20.4, 20.5]
      var channelData3Out: [Double] = [30.0, 30.1, 30.2, 30.3, 30.4, 30.5]
      var channelData4Out: [Double] = [40.0, 40.1, 40.2, 40.3, 40.4, 40.5]
      let channelData1PtrOut = UnsafeMutableBufferPointer(start: &channelData1Out, count: channelData1Out.count)
      let channelData2PtrOut = UnsafeMutableBufferPointer(start: &channelData2Out, count: channelData2Out.count)
      let channelData3PtrOut = UnsafeMutableBufferPointer(start: &channelData3Out, count: channelData3Out.count)
      let channelData4PtrOut = UnsafeMutableBufferPointer(start: &channelData4Out, count: channelData4Out.count)
      let ablPointerOut = AudioBufferList.allocate(maximumBuffers: 4)
      ablPointerOut[0] = AudioBuffer(channelData1PtrOut, numberOfChannels: 1)
      ablPointerOut[1] = AudioBuffer(channelData2PtrOut, numberOfChannels: 1)
      ablPointerOut[2] = AudioBuffer(channelData3PtrOut, numberOfChannels: 1)
      ablPointerOut[3] = AudioBuffer(channelData4PtrOut, numberOfChannels: 1)

      let rb = CARingBuffer<Double>(numberOfChannels: 4, capacityFrames: 8)
      var status = CARingBufferError.NoError
      status = rb.store(ablPointerIn.unsafePointer, framesToWrite: 6, startWrite: 0)
      XCTAssertTrue(status == .NoError)
      status = rb.fetch(ablPointerOut.unsafeMutablePointer, framesToRead: 6, startRead: 0)
      XCTAssertTrue(status == .NoError)
      XCTAssertTrue(isSampleDataEqual(lhs: channelData1In, rhs: channelData1Out))
      XCTAssertTrue(isSampleDataEqual(lhs: channelData2In, rhs: channelData2Out))
      XCTAssertTrue(isSampleDataEqual(lhs: channelData3In, rhs: channelData3Out))
      XCTAssertTrue(isSampleDataEqual(lhs: channelData4In, rhs: channelData4Out))
   }

   func testIOWithMediaBufferType() {

      func isSampleDataEqual(lhs: [Double], rhs: [Double]) -> Bool {
         guard lhs.count == rhs.count else {
            return false
         }
         for index in 0..<lhs.count {
            if lhs[index] != rhs[index] {
               return false
            }
         }
         return true
      }

      var channelData1In = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5]
      var channelData2In = [2.0, 2.1, 2.2, 2.3, 2.4, 2.5]
      var channelData3In = [3.0, 3.1, 3.2, 3.3, 3.4, 3.5]
      var channelData4In = [4.0, 4.1, 4.2, 4.3, 4.4, 4.5]
      let mediaBufferListPtrIn = UnsafeMutablePointer<MediaBuffer<Double>>.allocate(capacity: 4)
      mediaBufferListPtrIn[0] = MediaBuffer(mutableData: &channelData1In, numberOfElements: channelData1In.count)
      mediaBufferListPtrIn[1] = MediaBuffer(mutableData: &channelData2In, numberOfElements: channelData2In.count)
      mediaBufferListPtrIn[2] = MediaBuffer(mutableData: &channelData3In, numberOfElements: channelData3In.count)
      mediaBufferListPtrIn[3] = MediaBuffer(mutableData: &channelData4In, numberOfElements: channelData4In.count)
      let mediaBufferListIn = MediaBufferList(buffers: mediaBufferListPtrIn, numberBuffers: 4)

      var channelData1Out = [10.0, 10.1, 10.2, 10.3, 10.4, 10.5]
      var channelData2Out = [20.0, 20.1, 20.2, 20.3, 20.4, 20.5]
      var channelData3Out = [30.0, 30.1, 30.2, 30.3, 30.4, 30.5]
      var channelData4Out = [40.0, 40.1, 40.2, 40.3, 40.4, 40.5]
      let mediaBufferListPtrOut = UnsafeMutablePointer<MediaBuffer<Double>>.allocate(capacity: 4)
      mediaBufferListPtrOut[0] = MediaBuffer(mutableData: &channelData1Out, numberOfElements: channelData1Out.count)
      mediaBufferListPtrOut[1] = MediaBuffer(mutableData: &channelData2Out, numberOfElements: channelData2Out.count)
      mediaBufferListPtrOut[2] = MediaBuffer(mutableData: &channelData3Out, numberOfElements: channelData3Out.count)
      mediaBufferListPtrOut[3] = MediaBuffer(mutableData: &channelData4Out, numberOfElements: channelData4Out.count)
      let mediaBufferListOut = MediaBufferList(buffers: mediaBufferListPtrOut, numberBuffers: 4)

      let rb = CARingBuffer<Double>(numberOfChannels: 4, capacityFrames: 8)
      var status = CARingBufferError.NoError
      status = rb.store(mediaBufferListIn, framesToWrite: 6, startWrite: 0)
      XCTAssertTrue(status == .NoError)
      status = rb.fetch(mediaBufferListOut, framesToRead: 6, startRead: 0)
      XCTAssertTrue(status == .NoError)
      XCTAssertTrue(isSampleDataEqual(lhs: channelData1In, rhs: channelData1Out))
      XCTAssertTrue(isSampleDataEqual(lhs: channelData2In, rhs: channelData2Out))
      XCTAssertTrue(isSampleDataEqual(lhs: channelData3In, rhs: channelData3Out))
      XCTAssertTrue(isSampleDataEqual(lhs: channelData4In, rhs: channelData4Out))
   }

   func testIOWithCustomDataType() {

      typealias ST = CustomSampleType
      func isSampleDataEqual(lhs: [ST], rhs: [ST]) -> Bool {
         guard lhs.count == rhs.count else {
            return false
         }
         for index in 0..<lhs.count {
            if lhs[index] != rhs[index] {
               return false
            }
         }
         return true
      }

      var channelData1In: [ST] = [ST(0), ST(1), ST(2), ST(3), ST(4), ST(5)]
      var channelData2In: [ST] = [ST(6), ST(7), ST(8), ST(9), ST(10), ST(11)]
      var channelData3In: [ST] = [ST(12), ST(13), ST(14), ST(15), ST(16), ST(17)]
      var channelData4In: [ST] = [ST(18), ST(19), ST(20), ST(21), ST(22), ST(23)]
      let channelData1Ptr = UnsafeMutableBufferPointer(start: &channelData1In, count: channelData1In.count)
      let channelData2Ptr = UnsafeMutableBufferPointer(start: &channelData2In, count: channelData2In.count)
      let channelData3Ptr = UnsafeMutableBufferPointer(start: &channelData3In, count: channelData3In.count)
      let channelData4Ptr = UnsafeMutableBufferPointer(start: &channelData4In, count: channelData4In.count)
      let ablPointerIn = AudioBufferList.allocate(maximumBuffers: 4)
      ablPointerIn[0] = AudioBuffer(channelData1Ptr, numberOfChannels: 1)
      ablPointerIn[1] = AudioBuffer(channelData2Ptr, numberOfChannels: 1)
      ablPointerIn[2] = AudioBuffer(channelData3Ptr, numberOfChannels: 1)
      ablPointerIn[3] = AudioBuffer(channelData4Ptr, numberOfChannels: 1)

      var channelData1Out: [ST] = [ST(10), ST(11), ST(12), ST(13), ST(14), ST(15)]
      var channelData2Out: [ST] = [ST(16), ST(17), ST(18), ST(19), ST(110), ST(111)]
      var channelData3Out: [ST] = [ST(112), ST(113), ST(114), ST(115), ST(116), ST(117)]
      var channelData4Out: [ST] = [ST(118), ST(119), ST(120), ST(121), ST(122), ST(123)]
      let channelData1PtrOut = UnsafeMutableBufferPointer(start: &channelData1Out, count: channelData1Out.count)
      let channelData2PtrOut = UnsafeMutableBufferPointer(start: &channelData2Out, count: channelData2Out.count)
      let channelData3PtrOut = UnsafeMutableBufferPointer(start: &channelData3Out, count: channelData3Out.count)
      let channelData4PtrOut = UnsafeMutableBufferPointer(start: &channelData4Out, count: channelData4Out.count)
      let ablPointerOut = AudioBufferList.allocate(maximumBuffers: 4)
      ablPointerOut[0] = AudioBuffer(channelData1PtrOut, numberOfChannels: 1)
      ablPointerOut[1] = AudioBuffer(channelData2PtrOut, numberOfChannels: 1)
      ablPointerOut[2] = AudioBuffer(channelData3PtrOut, numberOfChannels: 1)
      ablPointerOut[3] = AudioBuffer(channelData4PtrOut, numberOfChannels: 1)

      let rb = CARingBuffer<CustomSampleType>(numberOfChannels: 4, capacityFrames: 8)
      var status = CARingBufferError.NoError
      status = rb.store(ablPointerIn.unsafePointer, framesToWrite: 6, startWrite: 0)
      XCTAssertTrue(status == .NoError)
      status = rb.fetch(ablPointerOut.unsafeMutablePointer, framesToRead: 6, startRead: 0)
      XCTAssertTrue(status == .NoError)
      XCTAssertTrue(isSampleDataEqual(lhs: channelData1In, rhs: channelData1Out))
      XCTAssertTrue(isSampleDataEqual(lhs: channelData2In, rhs: channelData2Out))
      XCTAssertTrue(isSampleDataEqual(lhs: channelData3In, rhs: channelData3Out))
      XCTAssertTrue(isSampleDataEqual(lhs: channelData4In, rhs: channelData4Out))
   }
   
}
