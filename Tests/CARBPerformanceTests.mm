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

- (void)testPerformanceExample {
	UInt32 numberOfChannels = 2;
	UInt32 IOCapacity = 512;
	AVAudioFormat *audioFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:numberOfChannels];
	AVAudioPCMBuffer *writeBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:IOCapacity];
	AVAudioPCMBuffer *readBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:IOCapacity];
	CARingBuffer *ringBuffer = new CARingBuffer();
	ringBuffer->Allocate(numberOfChannels, sizeof(float), 4096);
	[CARBTestsUtility generateSampleChannelData:writeBuffer numberOfFrames:IOCapacity biasValue:1];
	[self measureBlock:^{
		CARingBufferError status;
		for (UInt32 iteration = 0; iteration < 2000000; ++iteration) {
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

@end
