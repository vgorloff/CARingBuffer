## CARingBuffer (Swift)

[![Build Status](https://travis-ci.org/vgorloff/CARingBuffer.svg?branch=master)](https://travis-ci.org/vgorloff/CARingBuffer)

---

### Swift version of CARingBuffer class from [Core Audio Utility Classes](https://www.google.de/search?q=Core+Audio+Utility+Classes)

#### Xcode project setup

In order to compare performance between Swift and C++ versions manual download of [Core Audio Utility Classes](https://www.google.de/search?q=Core+Audio+Utility+Classes) required.


**Q**: Where are the `Vendor/CoreAudio/PublicUtility` files?  
**A**: Please open `Xcode`, open `Documentation and API Reference` and search for `Core Audio Utility Classes`. Download them and unpack.

There is also dependency on another git repository. Xcode build phase will fetch git subtree automatically. But if it fails, then see Q/A below.

**Q**: Where are the `Vendor/WL****Open` files?  
**A**: Please go to folder `Vendor` and look on `*.command` files.

