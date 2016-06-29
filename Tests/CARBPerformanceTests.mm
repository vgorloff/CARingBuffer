//
//  CARBPerformanceTests.mm
//  WaveLabs
//
//  Created by Vlad Gorlov on 12.06.16.
//  Copyright © 2016 WaveLabs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AVFoundation/AVFoundation.h>
#import "CARBTestsCpp-Swift.h"
#import "CARingBuffer.h"

@interface CARBCppPerformanceTests : XCTestCase
@end

@implementation CARBCppPerformanceTests

- (void)performMeasure:(UInt32)numberOfIterations {
	UInt32 numberOfChannels = CARBTestParametersNumberOfChannels;
	UInt32 IOCapacity = CARBTestParametersIOCapacity;
	AVAudioFormat *audioFormat = [[AVAudioFormat alloc]
											initStandardFormatWithSampleRate:CARBTestParametersSampleRate
											channels:numberOfChannels];
	AVAudioPCMBuffer *writeBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:IOCapacity];
	AVAudioPCMBuffer *readBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:IOCapacity];
	CARingBuffer *ringBuffer = new CARingBuffer();
	ringBuffer->Allocate(numberOfChannels, sizeof(float), CARBTestParametersBufferCapacityFrames);
	[CARBTestsUtility generateSampleChannelData:writeBuffer numberOfFrames:IOCapacity biasValue:1];
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
   [self performMeasure:CARBTestParametersNumberOfIterationsShort];
}

- (void)testPerformanceMedium {
   [self performMeasure:CARBTestParametersNumberOfIterationsMedium];
}

- (void)testPerformanceLong {
   [self performMeasure:CARBTestParametersNumberOfIterationsLong];
}

@end
