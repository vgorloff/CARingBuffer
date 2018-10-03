//
//  CARBPerformanceTests.mm
//  WaveLabs
//
//  Created by Vlad Gorlov on 12.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

#import "CARBTestsCpp-Swift.h"
#import "CARingBuffer.h"
#import <AVFoundation/AVFoundation.h>
#import <XCTest/XCTest.h>

@interface CARBCppPerformanceTests : XCTestCase
@end

@implementation CARBCppPerformanceTests

- (void)performMeasure:(UInt32)numberOfIterations {
   UInt32 numberOfChannels = RingBufferTestParametersNumberOfChannels;
   UInt32 IOCapacity = RingBufferTestParametersIoCapacity;
   AVAudioFormat *audioFormat = [[AVAudioFormat alloc]
                                 initStandardFormatWithSampleRate:RingBufferTestParametersSampleRate
                                 channels:numberOfChannels];
   AVAudioPCMBuffer *writeBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:IOCapacity];
   AVAudioPCMBuffer *readBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:IOCapacity];
   CARingBuffer *ringBuffer = new CARingBuffer();
   ringBuffer->Allocate(numberOfChannels, sizeof(float), RingBufferTestParametersBufferCapacityFrames);
   [RingBufferTestsUtility generateSampleChannelData:writeBuffer numberOfFrames:IOCapacity biasValue:1];
   [self measureBlock:^{
      CARingBufferError status;
      for (UInt32 iteration = 0; iteration < numberOfIterations; ++iteration) {
         status = ringBuffer->Store(writeBuffer.audioBufferList, IOCapacity, IOCapacity * iteration);
         if (status != kCARingBufferError_OK) {
            abort();
         }

         status = ringBuffer->Fetch(readBuffer.mutableAudioBufferList, IOCapacity, IOCapacity * iteration);
         if (status != kCARingBufferError_OK) {
            abort();
         }
      }
   }];
}

- (void)testPerformanceShort {
   [self performMeasure:RingBufferTestParametersNumberOfIterationsShort];
}

- (void)testPerformanceMedium {
   [self performMeasure:RingBufferTestParametersNumberOfIterationsMedium];
}

- (void)testPerformanceLong {
   [self performMeasure:RingBufferTestParametersNumberOfIterationsLong];
}

@end
