## CARingBuffer (Swift)

[![Build Status](https://travis-ci.org/vgorloff/CARingBuffer.svg?branch=master)](https://travis-ci.org/vgorloff/CARingBuffer)

---

### Swift version of CARingBuffer class from [Core Audio Utility Classes](https://www.google.de/search?q=Core+Audio+Utility+Classes)

Actually it is not just a Swift version of CARingBuffer, but 3 generic dimensional RingBuffer (time, channel, frame).   
It can be used not only for Audio data manipulation, but for instance for Graphics data manipulation.   
You can use custom data types (Swift structures) with it. If MemoryLayout.size and MemoryLayout.stride of your data type are equal, then efficiency even better.   
For example:

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
    // See folder named "Test" for details how ablPointerIn and ablPointerOut was defined...
    ringBuffer.Store(ablPointerIn.unsafePointer, framesToWrite: 6, startWrite: 0)
    ringBuffer.Fetch(ablPointerOut.unsafeMutablePointer, framesToRead: 6, startRead: 0)

#### Xcode project setup

In order to compare performance between Swift and C++ versions manual download of [Core Audio Utility Classes](https://www.google.de/search?q=Core+Audio+Utility+Classes) required.


**Q**: Where are the `Vendor/CoreAudio/PublicUtility` files?  
**A**: Please open `Xcode`, open `Documentation and API Reference` and search for `Core Audio Utility Classes`. Download them and unpack.
