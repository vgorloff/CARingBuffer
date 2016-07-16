//
//  CARingBuffer.swift
//  WaveLabs
//
//  Created by Vlad Gorlov on 31.05.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import CoreAudio

//region MARK: - Supporting Definitions

// Next power of two greater or equal to x
private func NextPowerOfTwo(_ value: UInt32) -> UInt32 {
	// TODO: Performance optimization required. See: http://stackoverflow.com/questions/466204/rounding-up-to-nearest-power-of-2
	var power: UInt32 = 1
	while power < value {
		power *= 2
	}
	return power
}

public typealias SampleTime = Int64

private let kGeneralRingTimeBoundsQueueSize: UInt32 = 32
private let kGeneralRingTimeBoundsQueueMask: Int32 = Int32(kGeneralRingTimeBoundsQueueSize) - 1

private struct CARingBufferTimeBounds {
	var mStartTime: SampleTime = 0
	var mEndTime: SampleTime = 0
	var mUpdateCounter: UInt32 = 0
}

public enum CARingBufferError: Int32 {
	case NoError = 0
	/// Fetch start time is earlier than buffer start time and fetch end time is later than buffer end time
	case TooMuch = 3
	/// The reader is unable to get enough CPU cycles to capture a consistent snapshot of the time bounds
	case CPUOverload = 4
}

//endregion

public final class CARingBuffer<T: FloatingPoint> {

	private var mTimeBoundsQueue = ContiguousArray<CARingBufferTimeBounds>(repeating: CARingBufferTimeBounds(),
	                                                                       count: Int(kGeneralRingTimeBoundsQueueSize))
	private var mTimeBoundsQueueCurrentIndex: Int32 = 0

	private let mNumberChannels: UInt32
	/// Per channel capacity, must be a power of 2.
	private let mCapacityFrames: UInt32
	/// Used to for index calculation.
	private let mCapacityFramesMask: UInt32
	private let mCapacityBytes: UInt32
	private let mBytesPerFrame: UInt32
	/// Number of allocated elements in buffer for all channels.
	private let mBuffersLength: UInt32
	private let mBuffer: UnsafeMutablePointer<T>
	/// Buffer pointer just for debug purpose.
	private var mBufferPointer: UnsafeMutableBufferPointer<T> {
		return UnsafeMutableBufferPointer(start: mBuffer, count: Int(mBuffersLength))
	}
	/// Buffer array just for debug purpose.
	private var mBufferArray: Array<T> {
		return Array(mBufferPointer)
	}

	// MARK: - Init / Deinit

	/// **Note** CapacityFrames will be rounded up to a power of 2
	/// - parameter numberOfChannels: Number of channels (non-interleaved).
	/// - parameter capacityFrames: Capacity per every channel.
	public init(numberOfChannels: UInt32, capacityFrames: UInt32) {
		mNumberChannels = numberOfChannels
		mCapacityFrames = NextPowerOfTwo(capacityFrames)
		mCapacityFramesMask = mCapacityFrames - 1
		mBuffersLength = mCapacityFrames * numberOfChannels
      mBuffer = UnsafeMutablePointer<T>(allocatingCapacity: Int(mBuffersLength))
		mBytesPerFrame = UInt32(sizeof(T.self))
		mCapacityBytes = mBytesPerFrame * mCapacityFrames
	}

	deinit {
		mBuffer.deallocateCapacity(Int(mBuffersLength))
	}

	// MARK: - Public

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
	public func Store(_ abl: UnsafePointer<AudioBufferList>, framesToWrite: UInt32, startWrite: SampleTime) -> CARingBufferError {
		if framesToWrite == 0 {
			return .NoError
		}

		if framesToWrite > mCapacityFrames {
			return .TooMuch
		}

		let endWrite = startWrite + SampleTime(framesToWrite)
		if startWrite < EndTime() {
			// going backwards, throw everything out
			SetTimeBounds(startTime: startWrite, endTime: startWrite)
		} else if endWrite - StartTime() <= SampleTime(mCapacityFrames) {
			// the buffer has not yet wrapped and will not need to
		} else {
			// advance the start time past the region we are about to overwrite
			let newStart = endWrite - SampleTime(mCapacityFrames)	// one buffer of time behind where we're writing
			let newEnd = max(newStart, EndTime())
			SetTimeBounds(startTime: newStart, endTime: newEnd)
		}

		let curEnd = EndTime()
		var offset0: SampleTime
		var offset1: SampleTime
		var nbytes: SampleTime
		if startWrite > curEnd {
			// we are skipping some samples, so zero the range we are skipping
			offset0 = FrameOffset(curEnd)
			offset1 = FrameOffset(startWrite)
			if offset0 < offset1 {
				ZeroRange(mBuffer, numberOfChannels: mNumberChannels, offset: offset0, nbytes: offset1 - offset0)
			} else {
				ZeroRange(mBuffer, numberOfChannels: mNumberChannels, offset: offset0, nbytes: SampleTime(mCapacityBytes) - offset0)
				ZeroRange(mBuffer, numberOfChannels: mNumberChannels, offset: 0, nbytes: offset1)
			}
			offset0 = offset1
		} else {
			offset0 = FrameOffset(startWrite)
		}

		offset1 = FrameOffset(endWrite)
		if offset0 < offset1 {
			StoreABL(mBuffer, destOffset: offset0, abl: abl, srcOffset: 0, nbytes: offset1 - offset0)
		} else {
			nbytes = SampleTime(mCapacityBytes) - offset0
			StoreABL(mBuffer, destOffset: offset0, abl: abl, srcOffset: 0, nbytes: nbytes)
			StoreABL(mBuffer, destOffset: 0, abl: abl, srcOffset: nbytes, nbytes: offset1)
		}

		// now update the end time
		SetTimeBounds(startTime: StartTime(), endTime: endWrite)

		return .NoError
	}

	public func Fetch(_ abl: UnsafeMutablePointer<AudioBufferList>, nFrames: UInt32,
	                  startRead aStartRead: SampleTime) -> CARingBufferError {
		if nFrames == 0 {
			return .NoError
		}

		var startRead = max(0, aStartRead)

		var endRead = startRead + Int64(nFrames)

		let startRead0 = startRead
		let endRead0 = endRead

		let err = ClipTimeBounds(startRead: &startRead, endRead: &endRead)
		if err != .NoError {
			return err
		}

		if startRead == endRead {
			ZeroABL(abl, destOffset: 0, nbytes: Int64(nFrames * mBytesPerFrame))
			return .NoError
		}


		let byteSize = (endRead - startRead) * Int64(mBytesPerFrame)

		let destStartByteOffset = max(0, (startRead - startRead0) * Int64(mBytesPerFrame))

		if destStartByteOffset > 0 {
			ZeroABL(abl, destOffset: 0, nbytes: min(Int64(nFrames * mBytesPerFrame), destStartByteOffset))
		}

		let destEndSize = max(0, endRead0 - endRead)
		if destEndSize > 0 {
			ZeroABL(abl, destOffset: destStartByteOffset + byteSize, nbytes: destEndSize * Int64(mBytesPerFrame))
		}

		let offset0 = FrameOffset(startRead)
		let offset1 = FrameOffset(endRead)
		var nbytes: SampleTime = 0

		if offset0 < offset1 {
			nbytes = offset1 - offset0
			FetchABL(abl, destOffset: destStartByteOffset, buffers: mBuffer, srcOffset: offset0, nbytes: nbytes)
		} else {
			nbytes = Int64(mCapacityBytes) - offset0
			FetchABL(abl, destOffset: destStartByteOffset, buffers: mBuffer, srcOffset: offset0, nbytes: nbytes)
			FetchABL(abl, destOffset: destStartByteOffset + nbytes, buffers: mBuffer, srcOffset: 0, nbytes: offset1)
			nbytes += offset1
		}

		let ablPointer = UnsafeMutableAudioBufferListPointer(abl)
		for channel in 0..<ablPointer.count {
			var dest = ablPointer[channel]
			dest.mDataByteSize = UInt32(nbytes) // FIXME: This should be in sync with AVAudioPCMBuffer (Vlad Gorlov, 2016-06-12).
		}

		return .NoError
	}

	// MARK: - Private

	private func ZeroABL(_ abl: UnsafeMutablePointer<AudioBufferList>, destOffset: SampleTime, nbytes: SampleTime) {
		let advanceDistance = Int(destOffset) / sizeof(T.self)
		let buffersPointer = UnsafeBufferPointer<AudioBuffer>(start: &abl.pointee.mBuffers, count:Int(abl.pointee.mNumberBuffers))
		let numberBuffers = abl.pointee.mNumberBuffers
		for channel in 0..<numberBuffers {
			let channelBuffer = buffersPointer[Int(channel)]
			assert(channelBuffer.mNumberChannels == 1) // Supporting non interleaved channels at the moment
			if destOffset > Int64(channelBuffer.mDataByteSize) {
				continue
			}
         guard let channelBufferData = channelBuffer.mData else {
				continue
         }
			let channelData = UnsafeMutablePointer<T>(channelBufferData)
         let positionWrite = channelData.advanced(by: advanceDistance)
			let numberOfBytes = min(Int(nbytes), Int(channelBuffer.mDataByteSize) - Int(destOffset))
			memset(positionWrite, 0, numberOfBytes)
		}
	}

	private func FrameOffset(_ frameNumber: SampleTime) -> SampleTime {
		return (frameNumber & SampleTime(mCapacityFramesMask)) * SampleTime(mBytesPerFrame)
	}

	private func ZeroRange(_ buffers: UnsafeMutablePointer<T>, numberOfChannels: UInt32, offset: SampleTime, nbytes: SampleTime) {
		let advanceDistance = Int(offset) / sizeof(T.self)
		assert(mNumberChannels == numberOfChannels)
		for channel in 0 ..< numberOfChannels {
			// FIXME: Check for overflows (Vlad Gorlov, 2016-06-12).
         let positionWrite = buffers.advanced(by: advanceDistance + Int(channel * mCapacityFrames))
			memset(positionWrite, 0, Int(nbytes))
		}
	}

	private func FetchABL(_ abl: UnsafeMutablePointer<AudioBufferList>, destOffset: SampleTime,
	                      buffers: UnsafeMutablePointer<T>, srcOffset: SampleTime, nbytes: SampleTime) {

		let advanceOfSource = Int(srcOffset) / sizeof(T.self)
		let advanceOfDestination = Int(destOffset) / sizeof(T.self)
		let buffersPointer = UnsafeBufferPointer<AudioBuffer>(start: &abl.pointee.mBuffers, count: Int(abl.pointee.mNumberBuffers))
		let numberOfChannels = abl.pointee.mNumberBuffers
		for channel in 0 ..< numberOfChannels {
			let channelBuffer = buffersPointer[Int(channel)]
			if destOffset > Int64(channelBuffer.mDataByteSize) {
				continue
			}
         guard let channelBufferData = channelBuffer.mData else {
            continue
         }
			let channelData = UnsafeMutablePointer<T>(channelBufferData)
         let positionRead = buffers.advanced(by: advanceOfSource + Int(channel * mCapacityFrames))
			let positionWrite = channelData.advanced(by: advanceOfDestination)
			let numberOfBytes = min(Int(nbytes), Int(channelBuffer.mDataByteSize) - Int(destOffset))
			memcpy(positionWrite, positionRead, numberOfBytes)
		}
	}

	private func StoreABL(_ buffers: UnsafeMutablePointer<T>, destOffset: SampleTime, abl: UnsafePointer<AudioBufferList>,
	                      srcOffset: SampleTime, nbytes: SampleTime) {

		let advanceOfSource = Int(srcOffset) / sizeof(T.self)
		let advanceOfDestination = Int(destOffset) / sizeof(T.self)
		let buffersPointer = UnsafeBufferPointer<AudioBuffer>(start: &(UnsafeMutablePointer<AudioBufferList>(abl)).pointee.mBuffers,
		                                                      count:Int(abl.pointee.mNumberBuffers))
		let numberOfChannels = abl.pointee.mNumberBuffers
		for channel in 0 ..< numberOfChannels {
			let channelBuffer = buffersPointer[Int(channel)]
			if srcOffset > Int64(channelBuffer.mDataByteSize) {
				continue
			}
         guard let channelBufferData = channelBuffer.mData else {
            continue
         }
			let channelData = UnsafeMutablePointer<T>(channelBufferData)
			let positionRead = channelData.advanced(by: advanceOfSource)
			let positionWrite = buffers.advanced(by: advanceOfDestination + Int(channel * mCapacityFrames))
			let numberOfBytes = min(Int(nbytes), Int(channelBuffer.mDataByteSize) - Int(srcOffset))
			memcpy(positionWrite, positionRead, numberOfBytes)
		}
	}

	//region MARK: - Time Bounds Queue

	func SetTimeBounds(startTime: SampleTime, endTime: SampleTime) {
		let nextAbsoluteIndex = mTimeBoundsQueueCurrentIndex + 1 // Always increasing
		// Index always in range [0, kGeneralRingTimeBoundsQueueSize - 1]
		let elementIndex = Int(nextAbsoluteIndex & kGeneralRingTimeBoundsQueueMask)
		mTimeBoundsQueue[elementIndex].mStartTime = startTime
		mTimeBoundsQueue[elementIndex].mEndTime = endTime
		mTimeBoundsQueue[elementIndex].mUpdateCounter = UInt32(nextAbsoluteIndex)
		let status = OSAtomicCompareAndSwap32Barrier(mTimeBoundsQueueCurrentIndex, nextAbsoluteIndex,
		                                               &mTimeBoundsQueueCurrentIndex)
		assert(status)
	}

	func GetTimeBounds(startTime: inout SampleTime, endTime: inout SampleTime) -> CARingBufferError {
		// Fail after a few tries.
		for _ in 0 ..< 8 {
			let curPtr = mTimeBoundsQueueCurrentIndex
			let index = curPtr & kGeneralRingTimeBoundsQueueMask
			let bounds = mTimeBoundsQueue[Int(index)]

			startTime = bounds.mStartTime
			endTime = bounds.mEndTime
			let newPtr = Int32(bounds.mUpdateCounter)

			if newPtr == curPtr {
				return .NoError
			}
		}
		return .CPUOverload
	}

	//endregion

	//region MARK: - Time Bounds Queue: Private

	/// **Note!** Should only be called from Store.
	/// - returns: Start time from the Time bounds queue at current index.
	private func StartTime() -> SampleTime {
		return mTimeBoundsQueue[Int(mTimeBoundsQueueCurrentIndex & kGeneralRingTimeBoundsQueueMask)].mStartTime
	}

	/// **Note!** Should only be called from Store.
	/// - returns: End time from the Time bounds queue at current index.
	private func EndTime() -> SampleTime {
		return mTimeBoundsQueue[Int(mTimeBoundsQueueCurrentIndex & kGeneralRingTimeBoundsQueueMask)].mEndTime
	}

	private func ClipTimeBounds(startRead: inout SampleTime, endRead: inout SampleTime) -> CARingBufferError {
		var startTime: SampleTime = 0
		var endTime: SampleTime = 0

		let err = GetTimeBounds(startTime: &startTime, endTime: &endTime)
		if err != .NoError {
			return err
		}

		if startRead > endTime || endRead < startTime {
			endRead = startRead
			return .NoError
		}

		startRead = max(startRead, startTime)
		endRead = min(endRead, endTime)
		endRead = max(endRead, startRead)

		return .NoError
	}

	//endregion

}
