## CARingBuffer (Swift)

[![Build Status](https://travis-ci.org/vgorloff/CARingBuffer.svg?branch=master)](https://travis-ci.org/vgorloff/CARingBuffer)

---

### Swift version of CARingBuffer class from [Core Audio Utility Classes](https://developer.apple.com/library/archive/samplecode/CoreAudioUtilityClasses/Introduction/Intro.html)

Actually it is not just a Swift version of CARingBuffer, but generic 3 dimensional RingBuffer (time, channel, frame).
It can be used not only for Audio, but, for instance, for Graphics data manipulation.
You can use custom data types (Swift structures) with it.
For example:

```swift
struct CustomSampleInnerType {
   let a: Int
   let b: Float
}

struct CustomSampleType {
   let x: Int
   let y: UInt
   let z: Float
   let innerType: CustomSampleInnerType
}

let ringBuffer = CARingBuffer<CustomSampleType>(numberOfChannels: 4, capacityFrames: 8)
// See folder named "Test" for details how ablPointerIn and ablPointerOut were defined...
ringBuffer.store(ablPointerIn.unsafePointer, framesToWrite: 6, startWrite: 0)
ringBuffer.fetch(ablPointerOut.unsafeMutablePointer, framesToRead: 6, startRead: 0)
```

If MemoryLayout.size and MemoryLayout.stride of your data type are equal, then efficiency even better.

#### Xcode project setup

Run `npm install` in order to install dependencies.

In order to compare performance between Swift and C++ versions manual download of [Core Audio Utility Classes](https://developer.apple.com/library/archive/samplecode/CoreAudioUtilityClasses/Introduction/Intro.html) required.

- **Q**: Where are the `Vendor/CoreAudio/PublicUtility` files?
- **A**: Download them from [Documentation Archive](https://developer.apple.com/library/archive/samplecode/CoreAudioUtilityClasses/Introduction/Intro.html) and unpack.
