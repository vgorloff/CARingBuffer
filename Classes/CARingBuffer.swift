//
//  CARingBuffer_.swift
//  WLMedia
//
//  Created by Vlad Gorlov on 31.05.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

import CoreAudio

public extension AudioBuffer {
	var mFloatData: UnsafeMutablePointer<Float> {
		return UnsafeMutablePointer<Float>(mData)
	}
	var mFloatBuffer: UnsafeMutableBufferPointer<Float> {
		return UnsafeMutableBufferPointer<Float>(start: mFloatData, count: Int(mDataByteSize) / sizeof(Float))
	}
	var mFloatArray: [Float] {
		return Array<Float>(mFloatBuffer)
	}
	func fillWithZeros() {
		memset(mData, 0, Int(mDataByteSize))
	}
}

public extension UnsafeMutableAudioBufferListPointer {
	public var audioBuffers: [AudioBuffer] {
		var result = [AudioBuffer]()
		for audioBufferIndex in 0..<count {
			result.append(self[audioBufferIndex])
		}
		return result
	}
	public init(_ p: UnsafePointer<AudioBufferList>) {
		self.init(UnsafeMutablePointer<AudioBufferList>(p))
	}
}

// Next power of two greater or equal to x
private func NextPowerOfTwo(x: UInt32) -> UInt32 {
	// TODO: Optimization required. See: http://stackoverflow.com/questions/466204/rounding-up-to-nearest-power-of-2
	var power: UInt32 = 1
	while power < x {
		power *= 2
	}
	return power
}

private let kGeneralRingTimeBoundsQueueSize: Int = 32
private let kGeneralRingTimeBoundsQueueMask: Int = kGeneralRingTimeBoundsQueueSize - 1

private struct CARingBufferTimeBounds {
	var mStartTime: SampleTime = 0
	var mEndTime: SampleTime = 0
	var mUpdateCounter: Int = 0
}

// Public

public typealias SampleTime = Int64

public enum CARingBufferErrorCode: Int32 {
	case OK = 0
	/// Fetch start time is earlier than buffer start time and fetch end time is later than buffer end time
	case TooMuch = 3
	/// The reader is unable to get enough CPU cycles to capture a consistent snapshot of the time bounds
	case CPUOverload = 4
}

public final class CARingBuffer<T: FloatingPointType> {

	private var mTimeBoundsQueue = [CARingBufferTimeBounds](count: kGeneralRingTimeBoundsQueueSize, repeatedValue: CARingBufferTimeBounds())
	private var mTimeBoundsQueuePtr: Int = 0

	// MARK: - Private / Internal (for testability)

	private let mNumberChannels: UInt32
	/// per channel capacity, must be a power of 2.
	internal let mCapacityFrames: UInt32
	private let mCapacityFramesMask: UInt32
	private let mCapacityBytes: UInt32
	private let mBytesPerFrame: UInt32
	internal let mBuffersLength: UInt32 // Number of allocated elements in buffer
	private let mBuffer: UnsafeMutablePointer<T>
	internal var mBufferPointer: UnsafeMutableBufferPointer<T> {
		return UnsafeMutableBufferPointer(start: mBuffer, count: Int(mBuffersLength))
	}
	internal var mBufferArray: Array<T> {
		return Array(mBufferPointer)
	}

	// MARK: -

	/// **Note** CapacityFrames will be rounded up to a power of 2
	/// - parameter capacityFrames: Capacity per every channel.
	public init(nChannels: UInt32, capacityFrames: UInt32) {
		mNumberChannels = nChannels
		mCapacityFrames = NextPowerOfTwo(capacityFrames)
		mCapacityFramesMask = mCapacityFrames - 1
		mBuffersLength = mCapacityFrames * nChannels
		mBuffer = UnsafeMutablePointer<T>.alloc(Int(mBuffersLength))
		mBytesPerFrame = UInt32(sizeof(T.self))
		mCapacityBytes = mBytesPerFrame * mCapacityFrames
	}

	deinit {
		mBuffer.dealloc(Int(mBuffersLength))
	}

	// MARK: - Public

	/// Copy framesToWrite of data into the ring buffer at the specified sample time.
	/// The sample time should normally increase sequentially, though gaps
	/// are filled with zeroes. A sufficiently large gap effectively empties
	/// the buffer before storing the new data.
	/// If startWrite is less than the previous frame number, the behavior is undefined.
	/// Return false for failure (buffer not large enough).
	public func Store(abl: UnsafePointer<AudioBufferList>, framesToWrite: UInt32, startWrite: SampleTime) -> CARingBufferErrorCode {
		if framesToWrite == 0 {
			return .OK
		}

		if framesToWrite > mCapacityFrames {
			return .TooMuch
		}

		let endWrite = startWrite + Int64(framesToWrite)
		if startWrite < EndTime() {
			// going backwards, throw everything out
			SetTimeBounds(startTime: startWrite, endTime: startWrite)
		} else if endWrite - StartTime() <= Int64(mCapacityFrames) {
			// the buffer has not yet wrapped and will not need to
		} else {
			// advance the start time past the region we are about to overwrite
			let newStart = endWrite - Int64(mCapacityFrames)	// one buffer of time behind where we're writing
			let newEnd = max(newStart, EndTime())
			SetTimeBounds(startTime: newStart, endTime: newEnd)
		}

		let curEnd = EndTime()
		var offset0: SampleTime
		var offset1: SampleTime
		var nbytes: SampleTime
		let nchannels = mNumberChannels
		if startWrite > curEnd {
			// we are skipping some samples, so zero the range we are skipping
			offset0 = FrameOffset(curEnd)
			offset1 = FrameOffset(startWrite)
			if offset0 < offset1 {
				ZeroRange(mBuffer, nchannels: nchannels, offset: offset0, nbytes: offset1 - offset0)
			}
			else {
				ZeroRange(mBuffer, nchannels: nchannels, offset: offset0, nbytes: SampleTime(mCapacityBytes) - offset0)
				ZeroRange(mBuffer, nchannels: nchannels, offset: 0, nbytes: offset1)
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

		return .OK
	}

	public func Fetch(abl: UnsafeMutablePointer<AudioBufferList>, nFrames: UInt32, startRead aStartRead: SampleTime) -> CARingBufferErrorCode {
		if nFrames == 0 {
			return .OK
		}

		var startRead = max(0, aStartRead)

		var endRead = startRead + Int64(nFrames)

		let startRead0 = startRead
		let endRead0 = endRead

		let err = ClipTimeBounds(startRead: &startRead, endRead: &endRead)
		if err != .OK {
			return err
		}

		if startRead == endRead {
			ZeroABL(abl, destOffset: 0, nbytes: Int64(nFrames * mBytesPerFrame))
			return .OK
		}


		let byteSize = (endRead - startRead) * Int64(mBytesPerFrame)

		let destStartByteOffset = max(0, (startRead - startRead0) * Int64(mBytesPerFrame))

		if (destStartByteOffset > 0) {
			ZeroABL(abl, destOffset: 0, nbytes: min(Int64(nFrames * mBytesPerFrame), destStartByteOffset))
		}

		let destEndSize = max(0, endRead0 - endRead)
		if (destEndSize > 0) {
			ZeroABL(abl, destOffset: destStartByteOffset + byteSize, nbytes: destEndSize * Int64(mBytesPerFrame))
		}

		let offset0 = FrameOffset(startRead)
		let offset1 = FrameOffset(endRead)
		var nbytes: SampleTime = 0

		if (offset0 < offset1) {
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

		return .OK
	}

	// MARK: - Private

	private func ZeroABL(abl: UnsafeMutablePointer<AudioBufferList>, destOffset: SampleTime, nbytes: SampleTime) {
		let elementsToWrite = Int(nbytes) / sizeof(T.self) // FIXME: Check for overflows. See CPP code. (Vlad Gorlov, 2016-06-12).
		let elementsOfDstOffset = Int(destOffset) / sizeof(T.self)
		let ablPointer = UnsafeMutableAudioBufferListPointer(abl)
		assert(mNumberChannels == UInt32(ablPointer.count))
		for channel in 0..<ablPointer.count {
			let dst = ablPointer[channel]
			assert(dst.mNumberChannels == 1) // Supporting non interleaved channels at the momment
			if destOffset > Int64(dst.mDataByteSize) {
				continue
			}
			let channelData = UnsafeMutablePointer<T>(dst.mData)
			let dstWritePosition = channelData.advancedBy(elementsOfDstOffset)
			dstWritePosition.initializeFrom(Repeat(count: elementsToWrite, repeatedValue: T(0)))
		}

		//		int nBuffers = abl->mNumberBuffers;
		//		AudioBuffer *dest = abl->mBuffers;
		//		while (--nBuffers >= 0) {
		//			if (destOffset > (int)dest->mDataByteSize) continue;
		//			memset((Byte *)dest->mData + destOffset, 0, std::min(nbytes, (int)dest->mDataByteSize - destOffset));
		//			++dest;
		//		}
	}

	private func FrameOffset(frameNumber: SampleTime) -> SampleTime {
		return (frameNumber & SampleTime(mCapacityFramesMask)) * SampleTime(mBytesPerFrame)
	}

	private func ZeroRange(buffers: UnsafeMutablePointer<T>, nchannels: UInt32, offset: SampleTime, nbytes: SampleTime) {
		let elementsToWrite = Int(nbytes) / sizeof(T.self)
		let elementsOfSrcOffset = Int(offset) / sizeof(T.self)
		assert(mNumberChannels == nchannels)
		for channel in 0..<nchannels {
			// FIXME: Check for overflows (Vlad Gorlov, 2016-06-12).
			let srcReadPosition = buffers.advancedBy(elementsOfSrcOffset + Int(channel * mCapacityFrames))
			srcReadPosition.initializeFrom(Repeat(count: elementsToWrite, repeatedValue: T(0)))
		}
		//		while (--nchannels >= 0) {
		//			memset(*buffers + offset, 0, nbytes);
		//			++buffers;
		//		}
	}

	private func FetchABL(abl: UnsafeMutablePointer<AudioBufferList>, destOffset: SampleTime,
	                      buffers: UnsafeMutablePointer<T>, srcOffset: SampleTime, nbytes: SampleTime) {

		let elementsToWrite = Int(nbytes) / sizeof(T.self) // FIXME: Check for overflows. See CPP code. (Vlad Gorlov, 2016-06-12).
		let elementsOfSrcOffset = Int(srcOffset) / sizeof(T.self)
		let elementsOfDstOffset = Int(destOffset) / sizeof(T.self)
		let ablPointer = UnsafeMutableAudioBufferListPointer(abl)
		assert(mNumberChannels == UInt32(ablPointer.count))
		for channel in 0..<ablPointer.count {
			let dst = ablPointer[channel]
			assert(dst.mNumberChannels == 1) // Supporting non interleaved channels at the momment
			if destOffset > Int64(dst.mDataByteSize) {
				continue
			}
			let channelData = UnsafeMutablePointer<T>(dst.mData)
			let dstWritePosition = channelData.advancedBy(elementsOfDstOffset)
			let srcReadPosition = buffers.advancedBy(elementsOfSrcOffset + channel * Int(mCapacityFrames))
			dstWritePosition.initializeFrom(srcReadPosition, count: elementsToWrite)
		}

		//		int nchannels = abl->mNumberBuffers;
		//		AudioBuffer *dest = abl->mBuffers;
		//		while (--nchannels >= 0) {
		//			if (destOffset > (int)dest->mDataByteSize) continue;
		//			memcpy((Byte *)dest->mData + destOffset, *buffers + srcOffset, std::min(nbytes, (int)dest->mDataByteSize - destOffset));
		//			++buffers;
		//			++dest;
		//		}
	}

	private func StoreABL(buffers: UnsafeMutablePointer<T>, destOffset: SampleTime, abl: UnsafePointer<AudioBufferList>,
	                      srcOffset: SampleTime, nbytes: SampleTime) {

		let elementsToWrite = Int(nbytes) / sizeof(T.self) // FIXME: Check for overflows. See CPP code. (Vlad Gorlov, 2016-06-12).
		let elementsOfSrcOffset = Int(srcOffset) / sizeof(T.self)
		let elementsOfDstOffset = Int(destOffset) / sizeof(T.self)
		let ablPointer = UnsafeMutableAudioBufferListPointer(abl)
		assert(mNumberChannels == UInt32(ablPointer.count))
		for channel in 0..<ablPointer.count {
			let src = ablPointer[channel]
			assert(src.mNumberChannels == 1) // Supporting non interleaved channels at the momment
			if srcOffset > Int64(src.mDataByteSize) {
				continue
			}
			let channelData = UnsafeMutablePointer<T>(src.mData)
			let srcReadPosition = channelData.advancedBy(elementsOfSrcOffset)
			let dstWritePosition = buffers.advancedBy(elementsOfDstOffset + channel * Int(mCapacityFrames))
			dstWritePosition.initializeFrom(srcReadPosition, count: elementsToWrite)
		}

		//		int nchannels = abl->mNumberBuffers
		//		const AudioBuffer *src = abl->mBuffers
		//		while (--nchannels >= 0) {
		//			if (srcOffset > (int)src->mDataByteSize) continue
		//			memcpy(*buffers + destOffset, (Byte *)src->mData + srcOffset, std::min(nbytes, (int)src->mDataByteSize - srcOffset))
		//			++buffers
		//			++src
		//		}
	}


	// MARK: - Time Bounds Queue

	func SetTimeBounds(startTime startTime: SampleTime, endTime: SampleTime) {
		let nextPtr = mTimeBoundsQueuePtr + 1
		let index = nextPtr & kGeneralRingTimeBoundsQueueMask
		mTimeBoundsQueue[index].mStartTime = startTime
		mTimeBoundsQueue[index].mEndTime = endTime
		mTimeBoundsQueue[index].mUpdateCounter = nextPtr
		OSAtomicCompareAndSwapLongBarrier(mTimeBoundsQueuePtr, mTimeBoundsQueuePtr + 1, &mTimeBoundsQueuePtr)
	}

	func GetTimeBounds(inout startTime startTime: SampleTime, inout endTime: SampleTime) -> CARingBufferErrorCode {
		// Fail after a few tries.
		for _ in 0 ..< 8 {
			let curPtr = mTimeBoundsQueuePtr
			let index = curPtr & kGeneralRingTimeBoundsQueueMask
			let bounds = mTimeBoundsQueue[index]

			startTime = bounds.mStartTime
			endTime = bounds.mEndTime
			let newPtr = bounds.mUpdateCounter

			if newPtr == curPtr {
				return .OK
			}
		}
		return .CPUOverload
	}

	// Should only be called from Store.
	func StartTime() -> SampleTime {
		return mTimeBoundsQueue[mTimeBoundsQueuePtr & kGeneralRingTimeBoundsQueueMask].mStartTime
	}
	// Should only be called from Store.
	func EndTime() -> SampleTime {
		return mTimeBoundsQueue[mTimeBoundsQueuePtr & kGeneralRingTimeBoundsQueueMask].mEndTime
	}

	func ClipTimeBounds(inout startRead startRead: SampleTime, inout endRead: SampleTime) -> CARingBufferErrorCode {
		var startTime: SampleTime = 0
		var endTime: SampleTime = 0

		let err = GetTimeBounds(startTime: &startTime, endTime: &endTime)
		if err != .OK {
			return err
		}

		if startRead > endTime || endRead < startTime {
			endRead = startRead
			return .OK
		}

		startRead = max(startRead, startTime)
		endRead = min(endRead, endTime)
		endRead = max(endRead, startRead)
		
		return .OK	// success
	}
	
}
